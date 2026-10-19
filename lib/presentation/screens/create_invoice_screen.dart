import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../data/models/client.dart';
import '../../data/models/invoice.dart';
import '../../data/models/invoice_item.dart';
import '../../data/models/payment_milestone.dart';
import '../../data/models/product.dart';
import '../../services/currency_tax_service.dart';
import '../../services/pdf_service.dart';
import '../../core/utils/navigation_utils.dart';
import '../providers/client_provider.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../widgets/device_contact_picker_sheet.dart';
import '../widgets/milestone_config_sheet.dart';
import '../widgets/animated_currency_text.dart';
import '../widgets/voice_waveform_indicator.dart';
import '../widgets/bouncing_button.dart';
import '../../core/theme/app_motion.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final Invoice? invoiceToEdit;
  final bool isBottomSheet;

  const CreateInvoiceScreen({
    super.key,
    this.invoiceToEdit,
    this.isBottomSheet = false,
  });

  /// Static helper to open Create Invoice as a modal bottom sheet popup (or dialog on desktop)
  static Future<Invoice?> showAsBottomSheet(BuildContext context, {Invoice? invoiceToEdit}) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;
    if (isWide) {
      return showDialog<Invoice>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 740,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.92,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CreateInvoiceScreen(
                invoiceToEdit: invoiceToEdit,
                isBottomSheet: false,
              ),
            ),
          ),
        ),
      );
    }
    return showModalBottomSheet<Invoice>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateInvoiceScreen(
        invoiceToEdit: invoiceToEdit,
        isBottomSheet: true,
      ),
    );
  }

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  Client? _selectedClient;
  final List<InvoiceItem> _items = [];
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  String _notes = '';
  late String _invoiceNumber;
  List<PaymentMilestone> _milestones = [];

  late stt.SpeechToText _speech;
  bool _isListening = false;
  VoiceState _voiceState = VoiceState.idle;
  bool _isSaving = false;
  bool _isSaveSuccess = false;

  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _itemQtyController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    final invoice = widget.invoiceToEdit;
    if (invoice != null) {
      _invoiceNumber = invoice.invoiceNumber;
      _selectedClient = invoice.client;
      _items.addAll(invoice.items);
      _issueDate = invoice.issueDate;
      _dueDate = invoice.dueDate;
      _notes = invoice.notes;
      _milestones = List.from(invoice.milestones);
    } else {
      final existingInvoices = ref.read(invoiceProvider);
      _invoiceNumber = _computeNextInvoiceNumber(existingInvoices);
    }
  }

  static String _computeNextInvoiceNumber(List<Invoice> existingInvoices) {
    if (existingInvoices.isEmpty) {
      return '1';
    }

    int maxSeq = 0;
    for (final inv in existingInvoices) {
      final clean = inv.invoiceNumber.trim();
      final direct = int.tryParse(clean);
      if (direct != null && direct > 0 && direct < 100000) {
        if (direct > maxSeq) maxSeq = direct;
        continue;
      }
      final match = RegExp(r'(\d+)$').firstMatch(clean);
      if (match != null) {
        final val = int.tryParse(match.group(1)!);
        if (val != null && val > 0 && val < 100000) {
          if (val > maxSeq) maxSeq = val;
        }
      }
    }

    if (maxSeq > 0) {
      return '${maxSeq + 1}';
    }

    return '1';
  }

  void _showEditInvoiceNumberDialog() {
    final controller = TextEditingController(text: _invoiceNumber);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Invoice Number', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customize your invoice / bill number:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.text,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              decoration: InputDecoration(
                prefixText: 'INV-#',
                prefixStyle: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 16),
                hintText: '1',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              final newNum = controller.text.trim();
              if (newNum.isNotEmpty) {
                setState(() => _invoiceNumber = newNum);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _itemNameController.dispose();
    _itemPriceController.dispose();
    _itemQtyController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() => _voiceState = VoiceState.error);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Microphone permission is required for voice commands'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Future.delayed(const Duration(milliseconds: 1600), () {
            if (mounted && _voiceState == VoiceState.error) {
              setState(() => _voiceState = VoiceState.idle);
            }
          });
        }
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'listening') {
            if (mounted) setState(() => _voiceState = VoiceState.listening);
          } else if (val == 'done' || val == 'notListening') {
            if (mounted) {
              setState(() {
                _isListening = false;
                if (_voiceState != VoiceState.success) {
                  _voiceState = VoiceState.idle;
                }
              });
            }
          }
        },
        onError: (val) => setState(() {
          _isListening = false;
          _voiceState = VoiceState.error;
          Future.delayed(const Duration(milliseconds: 1600), () {
            if (mounted && _voiceState == VoiceState.error) {
              setState(() => _voiceState = VoiceState.idle);
            }
          });
        }),
      );
      if (available) {
        setState(() {
          _isListening = true;
          _voiceState = VoiceState.listening;
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _parseVoiceCommand(val.recognizedWords);
              if (val.finalResult) {
                _voiceState = VoiceState.success;
                Future.delayed(const Duration(milliseconds: 1200), () {
                  if (mounted && _voiceState == VoiceState.success) {
                    setState(() => _voiceState = VoiceState.idle);
                  }
                });
              }
            });
          },
        );
      } else {
        setState(() {
          _isListening = false;
          _voiceState = VoiceState.error;
          Future.delayed(const Duration(milliseconds: 1600), () {
            if (mounted && _voiceState == VoiceState.error) {
              setState(() => _voiceState = VoiceState.idle);
            }
          });
        });
      }
    } else {
      setState(() {
        _isListening = false;
        _voiceState = VoiceState.idle;
      });
      _speech.stop();
    }
  }

  void _parseVoiceCommand(String text) {
    text = text.toLowerCase();
    // Match client
    final clients = ref.read(clientsProvider);
    for (var client in clients) {
      if (text.contains(client.name.toLowerCase())) {
        _selectedClient = client;
        break;
      }
    }
    // Match numbers and add quick item
    final regExp = RegExp(r'(\d+)\s*(dollars?|bucks?|rupees?|inr|\$)?');
    final match = regExp.firstMatch(text);
    if (match != null) {
      final price = double.tryParse(match.group(1) ?? '0') ?? 0.0;
      if (price > 0 && _items.isEmpty) {
        _items.add(InvoiceItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Consulting Service',
          price: price,
          quantity: 1,
        ));
      }
    }
  }

  void _showAddProductDialog() {
    _itemNameController.clear();
    _itemPriceController.clear();
    _itemQtyController.text = '1';

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Line Item', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                TextButton.icon(
                  onPressed: () async {
                    final Product? selected = await context.push<Product>('/products-select');
                    if (selected != null) {
                      setState(() {
                        _items.add(InvoiceItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: selected.name,
                          price: selected.defaultPrice,
                          quantity: 1,
                        ));
                      });
                      if (context.mounted) Navigator.pop(ctx);
                    }
                  },
                  icon: const Icon(Icons.grid_view_rounded, size: 16, color: Color(0xFFFF5722)),
                  label: const Text('Catalog', style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Item Name
            TextField(
              controller: _itemNameController,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14.5, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Item name or service description...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Price
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _itemPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14.5, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'Unit Price',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                      prefixText: '${CurrencyTaxService.getCurrencySymbol(ref.watch(profileProvider).currency)} ',
                      prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Quantity
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _itemQtyController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14.5, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'Qty',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final name = _itemNameController.text.trim();
                  final price = double.tryParse(_itemPriceController.text.trim()) ?? 0.0;
                  final qty = int.tryParse(_itemQtyController.text.trim()) ?? 1;

                  if (name.isNotEmpty && price > 0) {
                    setState(() {
                      _items.add(InvoiceItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        price: price,
                        quantity: qty > 0 ? qty : 1,
                      ));
                    });
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Add to Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotesDialog() {
    final notesController = TextEditingController(text: _notes);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Invoice Notes & Terms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 14),
            TextField(
              controller: notesController,
              maxLines: 4,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter payment instructions, bank details, or terms...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _notes = notesController.text.trim());
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Save Notes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveInvoice() {
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a client'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add at least one line item'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final profile = ref.read(profileProvider);
    final taxRate = profile.defaultTaxRate > 0 ? profile.defaultTaxRate : 10.0;

    final invoice = Invoice(
      id: widget.invoiceToEdit?.id ?? 'inv_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: _invoiceNumber,
      client: _selectedClient!,
      items: List.from(_items),
      issueDate: _issueDate,
      dueDate: _dueDate,
      taxPercentage: widget.invoiceToEdit?.taxPercentage ?? taxRate,
      discount: widget.invoiceToEdit?.discount ?? 0.0,
      notes: _notes,
      status: widget.invoiceToEdit?.status ?? 'pending',
      milestones: _milestones,
      clientViewedAt: widget.invoiceToEdit?.clientViewedAt,
      clientViewCount: widget.invoiceToEdit?.clientViewCount ?? 0,
      paymentProofRef: widget.invoiceToEdit?.paymentProofRef,
      paymentProofDate: widget.invoiceToEdit?.paymentProofDate,
      paymentProofNote: widget.invoiceToEdit?.paymentProofNote,
      paymentProofStatus: widget.invoiceToEdit?.paymentProofStatus,
      paymentProofImage: widget.invoiceToEdit?.paymentProofImage,
    );

    setState(() => _isSaving = true);

    if (widget.invoiceToEdit != null) {
      ref.read(invoiceProvider.notifier).updateInvoice(invoice);
    } else {
      ref.read(invoiceProvider.notifier).addInvoice(invoice);
    }

    setState(() {
      _isSaving = false;
      _isSaveSuccess = true;
    });
    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      if (widget.isBottomSheet) {
        Navigator.pop(context, invoice);
        context.push('/preview', extra: invoice);
      } else {
        context.pushReplacement('/preview', extra: invoice);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 2,
    );

    final currentSubtotal = _items.fold<double>(0.0, (sum, it) => sum + it.total);
    final taxRate = profile.defaultTaxRate > 0 ? profile.defaultTaxRate : 10.0;
    final taxAmount = currentSubtotal * (taxRate / 100);
    final grandTotal = currentSubtotal + taxAmount;

    final contentWidget = Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: widget.isBottomSheet ? const BorderRadius.vertical(top: Radius.circular(32)) : BorderRadius.zero,
      ),
      child: Column(
        children: [
          // ── Top Header / Drag Bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                if (widget.isBottomSheet) ...[
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.invoiceToEdit != null ? 'Edit Invoice' : 'Create new invoice',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _showEditInvoiceNumberDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'INV-#$_invoiceNumber',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_outlined, size: 12, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        if (widget.isBottomSheet) {
                          Navigator.pop(context);
                        } else {
                          safeNavigateBack(context, fallbackRoute: '/dashboard');
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Scrollable Form Body ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Client Card (From Old Design) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Client / Recipient',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final contact = await DeviceContactPickerSheet.show(context);
                          if (contact != null) {
                            final newClient = contact.toClient();
                            ref.read(clientProvider.notifier).addClient(newClient);
                            setState(() => _selectedClient = newClient);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.contacts_rounded, size: 12, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text('From Contacts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  BouncingButton(
                    scaleFactor: 0.98,
                    onTap: () async {
                      final Client? selected = await context.push<Client>('/clients-select');
                      if (selected != null) {
                        setState(() => _selectedClient = selected);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: AppMotion.standard,
                        switchInCurve: AppMotion.entrance,
                        switchOutCurve: AppMotion.stateChange,
                        child: _selectedClient == null
                            ? Row(
                                key: const ValueKey('unselected'),
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person_add_outlined, color: Color(0xFFFF5722), size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Select or Add Client', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A))),
                                        SizedBox(height: 2),
                                        Text('Tap to choose from directory', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                                ],
                              )
                            : Row(
                                key: ValueKey('client_${_selectedClient!.id}'),
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFF0F172A),
                                    child: Text(
                                      _selectedClient!.name.isNotEmpty ? _selectedClient!.name[0].toUpperCase() : 'C',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_selectedClient!.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                                        const SizedBox(height: 2),
                                        Text(
                                          _selectedClient!.email.isNotEmpty ? _selectedClient!.email : _selectedClient!.phone,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── 2. Dates Row ──
                  Row(
                    children: [
                      // Issue Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Issue Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _issueDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) setState(() => _issueDate = picked);
                              },
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(DateFormat('dd MMM yyyy').format(_issueDate), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A))),
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Due Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Due Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dueDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) setState(() => _dueDate = picked);
                              },
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(DateFormat('dd MMM yyyy').format(_dueDate), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A))),
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Quick Due Date Presets
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildDueDatePresetChip('Due on Receipt', 0),
                        const SizedBox(width: 8),
                        _buildDueDatePresetChip('+7 Days', 7),
                        const SizedBox(width: 8),
                        _buildDueDatePresetChip('+14 Days', 14),
                        const SizedBox(width: 8),
                        _buildDueDatePresetChip('+30 Days', 30),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 3. Line Items (From Old Design) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Items & Services (${_items.length})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showAddProductDialog,
                        child: const Text(
                          '+ Add Item',
                          style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_items.isEmpty)
                    GestureDetector(
                      onTap: _showAddProductDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFFFF5722), size: 20),
                              ),
                              const SizedBox(height: 10),
                              const Text('No items added yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              const Text('Tap to add products or custom services', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < _items.length; i++)
                            Dismissible(
                              key: ValueKey('item_${_items[i].id}_$i'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                alignment: Alignment.centerRight,
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                              ),
                              onDismissed: (_) {
                                HapticFeedback.mediumImpact();
                                final removed = _items[i];
                                final removedIndex = i;
                                setState(() => _items.removeAt(i));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Removed ${removed.name}'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      textColor: const Color(0xFFFF5722),
                                      onPressed: () {
                                        setState(() => _items.insert(removedIndex, removed));
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _items[i].name,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${currencyFormat.format(_items[i].price)} each',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Quantity Stepper [-] Qty [+]
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            icon: const Icon(Icons.remove, size: 16, color: Color(0xFF0F172A)),
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              setState(() {
                                                if (_items[i].quantity > 1) {
                                                  _items[i] = InvoiceItem(
                                                    id: _items[i].id,
                                                    name: _items[i].name,
                                                    price: _items[i].price,
                                                    quantity: _items[i].quantity - 1,
                                                  );
                                                } else {
                                                  _items.removeAt(i);
                                                }
                                              });
                                            },
                                          ),
                                          Text(
                                            '${_items[i].quantity}',
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            icon: const Icon(Icons.add, size: 16, color: Color(0xFF0F172A)),
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              setState(() {
                                                _items[i] = InvoiceItem(
                                                  id: _items[i].id,
                                                  name: _items[i].name,
                                                  price: _items[i].price,
                                                  quantity: _items[i].quantity + 1,
                                                );
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Total for item with animated currency
                                    AnimatedCurrencyText(
                                      value: _items[i].total,
                                      formatter: currencyFormat,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── 4. Notes & Voice Input (From Old Design) ──
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _showNotesDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.notes_rounded, size: 18, color: Color(0xFF64748B)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _notes.isNotEmpty ? _notes : 'Add Order Notes',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _notes.isNotEmpty ? FontWeight.w700 : FontWeight.w500,
                                      color: _notes.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Voice Input Button
                      VoiceWaveformIndicator(
                        state: _voiceState,
                        onTap: _listen,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── 5. Payment Milestones & Deposit Tranches ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5722).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.splitscreen_rounded, size: 14, color: Color(0xFFFF5722)),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Payment Milestones & Tranches',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_milestones.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            MilestoneConfigSheet.show(
                              context,
                              totalAmount: grandTotal,
                              currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
                              initialMilestones: _milestones,
                              onSave: (list) {
                                setState(() => _milestones = list);
                              },
                            );
                          },
                          child: const Text(
                            'Edit Tranches',
                            style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_milestones.isEmpty)
                    GestureDetector(
                      onTap: () {
                        if (grandTotal <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Add at least one line item before setting up milestones.')),
                          );
                          return;
                        }
                        MilestoneConfigSheet.show(
                          context,
                          totalAmount: grandTotal,
                          currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
                          onSave: (list) {
                            setState(() => _milestones = list);
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF64748B), size: 20),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Single Full Payment (Default)',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A)),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Tap to split into milestone tranches (e.g. 50% deposit, 50% final)',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722).withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_milestones.length} Tranches Configured',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _milestones.clear()),
                                child: const Text(
                                  'Reset to Single',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._milestones.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final m = entry.value;
                            return Container(
                              margin: EdgeInsets.only(bottom: idx == _milestones.length - 1 ? 0 : 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5722).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${m.percentage.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFFF5722),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      m.title,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(m.amount),
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Total & Action Sticky Bar ──
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Payable', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF64748B))),
                      AnimatedCurrencyText(
                        value: grandTotal,
                        formatter: currencyFormat,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF0F172A), letterSpacing: -0.4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Preview button
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 50,
                          child: BouncingButton(
                            scaleFactor: 0.97,
                            onTap: () async {
                              if (_selectedClient == null || _items.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add client & items to preview')));
                                return;
                              }
                              final tempInvoice = Invoice(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                invoiceNumber: _invoiceNumber,
                                client: _selectedClient!,
                                items: List.from(_items),
                                issueDate: _issueDate,
                                dueDate: _dueDate,
                                status: 'pending',
                                notes: _notes,
                                milestones: _milestones,
                              );
                              await PdfService.shareInvoice(tempInvoice, profile);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Text(
                                'Preview',
                                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Finalise / Save button (Vibrant Orange / Lime)
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 50,
                          child: BouncingButton(
                            isLoading: _isSaving,
                            isSuccess: _isSaveSuccess,
                            onTap: _isSaving ? null : _saveInvoice,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _isSaveSuccess ? const Color(0xFF10B981) : const Color(0xFFFF5722),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                widget.invoiceToEdit != null ? 'Save Changes' : 'Finalise Order',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.isBottomSheet) {
      return contentWidget;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(child: contentWidget),
    );
  }

  Widget _buildDueDatePresetChip(String label, int days) {
    final targetDate = days == 0 ? _issueDate : _issueDate.add(Duration(days: days));
    final isSelected = DateUtils.isSameDay(_dueDate, targetDate);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _dueDate = targetDate;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFECE8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5722) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.3 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
