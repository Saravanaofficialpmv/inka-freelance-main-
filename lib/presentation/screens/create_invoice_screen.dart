import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/client.dart';
import '../../data/models/invoice.dart';
import '../../data/models/invoice_item.dart';
import '../../data/models/product.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../providers/profile_provider.dart';
import '../providers/product_provider.dart';
import '../../services/pdf_service.dart';
import 'package:inka/core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  Client? _selectedClient;
  final List<InvoiceItem> _items = [];
  final double _taxPercentage = 0.0;
  final double _discount = 0.0;

  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _itemQuantityController = TextEditingController(text: '1');
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      final status = await Permission.microphone.request();
      if (status.isDenied) return;

      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _lastWords = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              // We'll process once they stop talking or after a short delay
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _processVoiceCommand(_lastWords);
    }
  }

  void _processVoiceCommand(String text) {
    if (text.isEmpty) return;
    final lowercase = text.toLowerCase();
    
    // Simple NL logic: "add [item name] for [price]"
    // Example: "add laptop for one thousand five hundred" or "add apple for 5"
    if (lowercase.contains('add')) {
      try {
        final parts = lowercase.split('add')[1].split('for');
        final name = parts[0].trim();
        final priceString = parts[1].trim();
        
        // Basic number word to double conversion for simple cases
        double? price = double.tryParse(priceString.replaceAll(RegExp(r'[^0-9.]'), ''));
        
        if (price == null) {
          // Fallback if they spoke the number as words (very basic)
          if (priceString.contains('ten')) {
            price = 10;
          } else if (priceString.contains('five')) price = 5;
          else if (priceString.contains('one hundred')) price = 100;
          // ... in a real app, use a proper words-to-numbers library
        }

        if (name.isNotEmpty && price != null) {
          setState(() {
            _items.add(InvoiceItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name[0].toUpperCase() + name.substring(1),
              price: price!,
              quantity: 1,
            ));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added $name for $price via voice')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't parse command. Try: 'Add Apple for five'")),
        );
      }
    }
  }
  String _notes = '';
  final List<String> _tags = [];
  bool _isListeningToNotes = false;

  void _listenToNotes() async {
    if (!_isListeningToNotes) {
      final status = await Permission.microphone.request();
      if (status.isDenied) return;

      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListeningToNotes = true);
        _speech.listen(
          onResult: (val) => setState(() {
            if (val.finalResult) {
              _notes = _notes.isEmpty ? val.recognizedWords : '$_notes ${val.recognizedWords}';
              _isListeningToNotes = false;
            }
          }),
        );
      }
    } else {
      setState(() => _isListeningToNotes = false);
      _speech.stop();
    }
  }

  void _showNotesDialog() {
    final notesController = TextEditingController(text: _notes);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
        decoration: const BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter internal notes...',
                fillColor: AppColors.background,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _notes = notesController.text);
                  Navigator.pop(context);
                },
                child: const Text('Save Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagsDialog() {
    final tagController = TextEditingController();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Tags', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tagController,
                      decoration: InputDecoration(
                        hintText: 'New tag...',
                        fillColor: AppColors.background,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 48),
                    onPressed: () {
                      if (tagController.text.trim().isNotEmpty) {
                        setDialogState(() {
                          _tags.add(tagController.text.trim());
                          tagController.clear();
                        });
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.primary,
                  onDeleted: () {
                    setDialogState(() => _tags.remove(tag));
                    setState(() {});
                  },
                  deleteIconColor: Colors.white70,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                )).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
        decoration: const BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.grid_view_rounded, size: 18, color: AppColors.primary),
                  label: const Text('Browse Catalog', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 24),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final catalogProducts = ref.read(productsProvider);
                final allInvoices = ref.read(invoiceProvider);
                
                final suggestions = <String>{};
                for (var p in catalogProducts) {
                  suggestions.add(p.name);
                }
                for (var inv in allInvoices) {
                  for (var item in inv.items) {
                    suggestions.add(item.name);
                  }
                }
                
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return suggestions.where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                _itemNameController.text = selection;
                
                final catalog = ref.read(productsProvider);
                final productInCatalog = catalog.where((p) => p.name == selection).firstOrNull;
                
                if (productInCatalog != null) {
                  _itemPriceController.text = productInCatalog.defaultPrice.toString();
                } else {
                  final allInvoices = ref.read(invoiceProvider);
                  for (var inv in allInvoices) {
                    for (var item in inv.items) {
                       if (item.name == selection) {
                          _itemPriceController.text = item.price.toString();
                          return;
                       }
                    }
                  }
                }
              },
              fieldViewBuilder: (context, fieldTextEditingController, fieldFocusNode, onFieldSubmitted) {
                fieldTextEditingController.addListener(() {
                  _itemNameController.text = fieldTextEditingController.text;
                });
                return TextField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    prefixIcon: const Icon(Icons.shopping_bag_outlined),
                    fillColor: AppColors.background,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                final profile = ref.read(profileProvider);
                final currencyFormat = NumberFormat.simpleCurrency(name: profile.currency, decimalDigits: 0);
                final catalog = ref.read(productsProvider);
                
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8.0,
                    borderRadius: BorderRadius.circular(16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200, 
                        maxWidth: MediaQuery.of(context).size.width - 48
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          final catProd = catalog.where((p) => p.name == option).firstOrNull;
                          
                          return ListTile(
                            title: Text(option),
                            subtitle: Text(catProd != null ? 'Catalog Price: ${currencyFormat.format(catProd.defaultPrice)}' : 'From History'),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price',
                      prefixIcon: const Icon(Icons.attach_money),
                      fillColor: AppColors.background,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _itemQuantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      prefixIcon: const Icon(Icons.add_shopping_cart),
                      fillColor: AppColors.background,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_itemNameController.text.isNotEmpty && _itemPriceController.text.isNotEmpty) {
                    setState(() {
                      _items.add(InvoiceItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _itemNameController.text,
                        price: double.tryParse(_itemPriceController.text) ?? 0,
                        quantity: int.tryParse(_itemQuantityController.text) ?? 1,
                      ));
                    });
                    _itemNameController.clear();
                    _itemPriceController.clear();
                    _itemQuantityController.text = '1';
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add to Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateNextInvoiceNumber() {
    final invoices = ref.read(invoiceProvider);
    if (invoices.isEmpty) return 'INV-0001';
    
    int maxNumber = 0;
    for (final inv in invoices) {
      final match = RegExp(r'INV-(\d+)').firstMatch(inv.invoiceNumber);
      if (match != null) {
        final num = int.tryParse(match.group(1)!) ?? 0;
        if (num > maxNumber) maxNumber = num;
      }
    }
    
    final nextNumber = maxNumber > 0 ? maxNumber + 1 : invoices.length + 1;
    return 'INV-${nextNumber.toString().padLeft(4, '0')}';
  }

  void _saveInvoice() {
    if (_selectedClient == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a client and add products')));
      return;
    }

    final newInvoice = Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceNumber: _generateNextInvoiceNumber(),
      client: _selectedClient!,
      items: _items,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 14)),
      taxPercentage: _taxPercentage,
      discount: _discount,
      status: 'pending',
      notes: _tags.isEmpty ? _notes : '$_notes\n\nTags: ${_tags.join(", ")}',
    );

    ref.read(invoiceProvider.notifier).addInvoice(newInvoice);
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final currencyFormat = NumberFormat.simpleCurrency(name: profile.currency);
    final allInvoices = ref.watch(invoiceProvider);
    
    double previousBalance = 0;
    if (_selectedClient != null) {
      previousBalance = allInvoices
          .where((inv) => inv.client.id == _selectedClient!.id && inv.status != 'paid')
          .fold(0.0, (sum, inv) => sum + inv.total);
    }

    final double currentTotal = _items.fold(0, (sum, item) => sum + item.total);
    final double grandTotal = currentTotal + previousBalance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/dashboard')),
        title: Text(AppLocalizations.of(context)?.translate('create_invoice') ?? 'Create Order', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Selection Card
                  Text(AppLocalizations.of(context)?.translate('customer') ?? 'Customer', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _SelectionCard(
                    onTap: () async {
                      final client = await context.push<Client>('/clients-select');
                      if (client != null) setState(() => _selectedClient = client);
                    },
                    child: _selectedClient == null
                        ? Row(
                            children: const [
                              Icon(Icons.person_add_rounded, color: AppColors.primary),
                              SizedBox(width: 16),
                              Text('Choose Customer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              Spacer(),
                              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                            ],
                          )
                        : Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(_selectedClient!.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_selectedClient!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(_selectedClient!.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    if (_selectedClient!.gstNumber != null && _selectedClient!.gstNumber!.isNotEmpty)
                                      Text('GSTIN: ${_selectedClient!.gstNumber}', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                                onPressed: () => setState(() => _selectedClient = null),
                              )
                            ],
                          ),
                  ),

                  if (previousBalance > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${AppLocalizations.of(context)?.translate('unpaid_balance') ?? 'Unpaid Balance'}: ${currencyFormat.format(previousBalance)}',
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Products List Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)?.translate('order_items') ?? 'Order Items', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: _showAddProductDialog,
                        icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    _SelectionCard(
                      onTap: _showAddProductDialog,
                      child: Center(
                        child: Column(
                          children: const [
                            Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.inactive),
                            SizedBox(height: 12),
                            Text('No items added yet', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text('${item.quantity} × ${currencyFormat.format(item.price)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(currencyFormat.format(item.total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                  GestureDetector(
                                    onTap: () => setState(() => _items.remove(item)),
                                    child: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),

                  const SizedBox(height: 32),
                  
                  // Metadata Section
                  const Text('Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _SelectionCard(
                    onTap: _showNotesDialog,
                    child: Row(
                      children: [
                        const Icon(Icons.sticky_note_2_outlined, color: AppColors.textSecondary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Internal Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(_notes.isEmpty ? 'Optional notes for your records' : _notes, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isListeningToNotes ? Icons.stop_circle : Icons.mic_rounded,
                            color: _isListeningToNotes ? Colors.redAccent : AppColors.primary,
                          ),
                          onPressed: _listenToNotes,
                        ),
                        const Icon(Icons.add_rounded, color: AppColors.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SelectionCard(
                    onTap: _showTagsDialog,
                    child: Row(
                      children: [
                        const Icon(Icons.tag_rounded, color: AppColors.textSecondary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Categorisation Tags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(_tags.isEmpty ? 'Organise your orders' : _tags.join(', '), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const Icon(Icons.add_rounded, color: AppColors.primary),
                      ],
                    ),
                  ),

                  const SizedBox(height: 155),
                ],
              ),
            ),
          ),
          
          // Total & Creation Bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 110), // Bottom padding for pill
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, -5))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)?.translate('total_amount') ?? 'Total Amount', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(currencyFormat.format(currentTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ],
                ),
                if (previousBalance > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)?.translate('previous_balance') ?? 'Previous Balance', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(currencyFormat.format(previousBalance), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)?.translate('total_payable') ?? 'Total Payable', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(currencyFormat.format(grandTotal), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary)),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(currencyFormat.format(currentTotal), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black)),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                // Stacked Primary Actions
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 20),
                    onPressed: () async {
                       if (_selectedClient == null || _items.isEmpty) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add items to preview')));
                         return;
                       }
                       final tempInvoice = Invoice(
                         id: DateTime.now().millisecondsSinceEpoch.toString(),
                         invoiceNumber: _generateNextInvoiceNumber(),
                         client: _selectedClient!,
                         items: _items,
                         issueDate: DateTime.now(),
                         dueDate: DateTime.now().add(const Duration(days: 14)),
                         status: 'pending',
                         notes: _notes,
                       );
                       await PdfService.shareInvoice(tempInvoice, profile);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    label: const Text('Preview & Share', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    onPressed: _saveInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    label: Text(AppLocalizations.of(context)?.translate('finalise_order') ?? 'Finalise Order', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                // AI Voice Trigger Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _listen,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isListening ? Colors.redAccent.withOpacity(0.1) : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _isListening ? Colors.redAccent : AppColors.border.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_isListening ? Icons.mic : Icons.mic_none, size: 18, color: _isListening ? Colors.redAccent : AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              _isListening ? 'Listening...' : 'Voice Input',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isListening ? Colors.redAccent : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SelectionCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
          border: Border.all(color: AppColors.border.withOpacity(0.3)),
        ),
        child: child,
      ),
    );
  }
}
