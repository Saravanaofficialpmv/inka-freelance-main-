import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../data/models/client.dart';
import '../../data/models/invoice.dart';
import '../../data/models/invoice_item.dart';
import '../../data/models/product.dart';
import '../../services/currency_tax_service.dart';
import '../../services/pdf_service.dart';
import '../providers/client_provider.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final Invoice? invoiceToEdit;
  final bool isBottomSheet;

  const CreateInvoiceScreen({
    super.key,
    this.invoiceToEdit,
    this.isBottomSheet = false,
  });

  /// Static helper to open Create Invoice as a modal bottom sheet popup
  static Future<Invoice?> showAsBottomSheet(BuildContext context, {Invoice? invoiceToEdit}) {
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

  late stt.SpeechToText _speech;
  bool _isListening = false;

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
    } else {
      _invoiceNumber = '${100000 + Random().nextInt(899999)}';
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemPriceController.dispose();
    _itemQtyController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _parseVoiceCommand(val.recognizedWords);
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
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
                      prefixText: '\$ ',
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
      taxPercentage: taxRate,
      discount: 0.0,
      notes: _notes,
      status: widget.invoiceToEdit?.status ?? 'unpaid',
    );

    if (widget.invoiceToEdit != null) {
      ref.read(invoiceProvider.notifier).updateInvoice(invoice);
    } else {
      ref.read(invoiceProvider.notifier).addInvoice(invoice);
    }

    if (widget.isBottomSheet) {
      Navigator.pop(context, invoice);
      context.push('/preview', extra: invoice);
    } else {
      context.pushReplacement('/preview', extra: invoice);
    }
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
                        const SizedBox(height: 2),
                        Text(
                          'INV-#$_invoiceNumber • Fill details below',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                  const Text('Client / Recipient', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),

                  GestureDetector(
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
                      child: _selectedClient == null
                          ? Row(
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

                  const SizedBox(height: 20),

                  // ── 3. Line Items (From Old Design) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items & Services (${_items.length})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
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
                    for (int i = 0; i < _items.length; i++) ...[
                      Container(
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

                            // Total for item
                            Text(
                              currencyFormat.format(_items[i].total),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                    ],

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
                      GestureDetector(
                        onTap: _listen,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isListening ? const Color(0xFFFFECE8) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _isListening ? const Color(0xFFFF5722) : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(_isListening ? Icons.mic : Icons.mic_none_rounded, size: 18, color: _isListening ? const Color(0xFFFF5722) : const Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                _isListening ? 'Listening...' : 'Voice',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: _isListening ? const Color(0xFFFF5722) : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                      Text(
                        currencyFormat.format(grandTotal),
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
                          child: OutlinedButton(
                            onPressed: () async {
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
                              );
                              await PdfService.shareInvoice(tempInvoice, profile);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Preview', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Finalise / Save button (Vibrant Orange / Lime)
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _saveInvoice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5722),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Text(
                              widget.invoiceToEdit != null ? 'Save Changes' : 'Finalise Order',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
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
}
