import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/business_profile.dart';
import '../../services/currency_tax_service.dart';
import '../../services/currency_conversion_service.dart';
import '../providers/profile_provider.dart';
import 'app_search_bar.dart';

// ── Currency Selection Bottom Sheet ──
class CurrencySelectionBottomSheet extends StatefulWidget {
  final BusinessProfile profile;

  const CurrencySelectionBottomSheet({super.key, required this.profile});

  static Future<void> show(BuildContext context, BusinessProfile profile) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CurrencySelectionBottomSheet(profile: profile),
    );
  }

  @override
  State<CurrencySelectionBottomSheet> createState() => _CurrencySelectionBottomSheetState();
}

class _CurrencySelectionBottomSheetState extends State<CurrencySelectionBottomSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = CurrencyTaxService.supportedCurrencies.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.code.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q) ||
          c.symbol.toLowerCase().contains(q);
    }).toList();

    return Consumer(
      builder: (context, ref, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 16,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Currency',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Choose currency format for your invoices',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Bar
              AppSearchBar(
                hintText: 'Search currency name, code (USD, EUR, INR)...',
                onChanged: (v) => setState(() => _searchQuery = v),
                onClear: () => setState(() => _searchQuery = ''),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, index) {
                    final curr = filtered[index];
                    final isSelected = widget.profile.currency.toUpperCase() == curr.code.toUpperCase() ||
                        widget.profile.currency == curr.symbol;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFECE8) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF5722) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        onTap: () async {
                          if (isSelected) {
                            Navigator.of(context).pop();
                            return;
                          }
                          final oldCurrency = widget.profile.currency;
                          final recordCounts = CurrencyConversionService.getExistingRecordCounts();
                          final totalRecords = recordCounts.values.fold<int>(0, (sum, count) => sum + count);
                          if (totalRecords > 0) {
                            await CurrencyConversionService.convertAllData(
                              fromCurrency: oldCurrency,
                              toCurrency: curr.code,
                              ref: ref,
                            );
                          } else {
                            await ref.read(profileProvider.notifier).updateProfile(
                                  widget.profile.copyWith(currency: curr.code),
                                );
                          }
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Text(curr.flag, style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(
                          '${curr.name} (${curr.code})',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text('Sample: ${curr.symbol}1,250.00', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        trailing: Text(
                          curr.symbol,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tax Configuration Bottom Sheet ──
class TaxSettingsBottomSheet extends ConsumerStatefulWidget {
  final BusinessProfile profile;

  const TaxSettingsBottomSheet({super.key, required this.profile});

  static Future<void> show(BuildContext context, BusinessProfile profile) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TaxSettingsBottomSheet(profile: profile),
    );
  }

  @override
  ConsumerState<TaxSettingsBottomSheet> createState() => _TaxSettingsBottomSheetState();
}

class _TaxSettingsBottomSheetState extends ConsumerState<TaxSettingsBottomSheet> {
  late TextEditingController _taxLabelController;
  late TextEditingController _taxRateController;
  late TextEditingController _taxIdController;
  late bool _isTaxInclusive;

  @override
  void initState() {
    super.initState();
    _taxLabelController = TextEditingController(text: widget.profile.taxLabel.isNotEmpty ? widget.profile.taxLabel : 'GST');
    _taxRateController = TextEditingController(text: widget.profile.defaultTaxRate > 0 ? widget.profile.defaultTaxRate.toString() : '18');
    _taxIdController = TextEditingController(text: widget.profile.taxIdNumber ?? widget.profile.gstNumber ?? '');
    _isTaxInclusive = widget.profile.isTaxInclusive;
  }

  @override
  void dispose() {
    _taxLabelController.dispose();
    _taxRateController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  void _applyScheme(TaxScheme scheme) {
    setState(() {
      _taxLabelController.text = scheme.label;
      _taxRateController.text = scheme.defaultRate.toString();
    });
  }

  void _handleSave() {
    final label = _taxLabelController.text.trim().isNotEmpty ? _taxLabelController.text.trim() : 'GST';
    final rate = double.tryParse(_taxRateController.text.trim()) ?? 0.0;
    final taxId = _taxIdController.text.trim();

    final updated = widget.profile.copyWith(
      taxLabel: label,
      defaultTaxRate: rate,
      isTaxInclusive: _isTaxInclusive,
      taxIdNumber: taxId,
      gstNumber: taxId,
    );

    ref.read(profileProvider.notifier).updateProfile(updated);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tax settings updated to $label ($rate%)!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
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
                const Text(
                  'Tax & Regional Compliance',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Regional Presets
            const Text(
              'Quick Tax Presets',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: CurrencyTaxService.commonTaxSchemes.map((scheme) {
                  final isSelected = _taxLabelController.text.trim().toLowerCase() == scheme.label.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        '${scheme.label} (${scheme.defaultRate}%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                      backgroundColor: isSelected ? const Color(0xFFFF5722) : const Color(0xFFF8FAFC),
                      side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
                      onPressed: () => _applyScheme(scheme),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Tax Label & Rate
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tax Label / Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _taxLabelController,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'e.g. VAT, GST, Sales Tax',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Default Rate (%)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _taxRateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: '18.0',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tax Identification Number (GSTIN, VAT ID, EIN)
            const Text('Tax Registration / Identification Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            TextField(
              controller: _taxIdController,
              style: const TextStyle(color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'e.g. GSTIN 07AAAAA0000A1Z5 or GB123456789',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
              ),
            ),
            const SizedBox(height: 14),

            // Tax Inclusive Toggle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prices are Tax-Inclusive', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
                        Text('Line item rates already include the tax percentage', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isTaxInclusive,
                    activeThumbColor: const Color(0xFFFF5722),
                    onChanged: (val) => setState(() => _isTaxInclusive = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Tax Settings',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
