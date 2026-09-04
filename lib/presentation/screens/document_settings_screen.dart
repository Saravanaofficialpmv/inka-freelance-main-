import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/currency_tax_service.dart';
import '../providers/profile_provider.dart';

class DocumentSettingsScreen extends ConsumerStatefulWidget {
  const DocumentSettingsScreen({super.key});

  @override
  ConsumerState<DocumentSettingsScreen> createState() => _DocumentSettingsScreenState();
}

class _DocumentSettingsScreenState extends ConsumerState<DocumentSettingsScreen> {
  late final TextEditingController _taxLabelController;
  late final TextEditingController _taxRateController;
  late final TextEditingController _taxIdController;
  late bool _isTaxInclusive;
  late String _selectedCurrency;
  bool _isSaving = false;

  static const List<Map<String, String>> _availableCurrencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'CAD', 'symbol': 'CA\$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'AU\$', 'name': 'Australian Dollar'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'AED', 'symbol': 'AED', 'name': 'UAE Dirham'},
    {'code': 'SGD', 'symbol': 'SG\$', 'name': 'Singapore Dollar'},
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _taxLabelController = TextEditingController(text: profile.taxLabel.isNotEmpty ? profile.taxLabel : 'GST');
    _taxRateController = TextEditingController(
      text: profile.defaultTaxRate > 0 ? profile.defaultTaxRate.toString() : '18',
    );
    _taxIdController = TextEditingController(text: profile.gstNumber ?? '');
    _isTaxInclusive = profile.isTaxInclusive;
    _selectedCurrency = profile.currency.isNotEmpty ? profile.currency : 'USD';
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

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final label = _taxLabelController.text.trim().isNotEmpty ? _taxLabelController.text.trim() : 'GST';
      final rate = double.tryParse(_taxRateController.text.trim()) ?? 0.0;
      final taxId = _taxIdController.text.trim();

      final profile = ref.read(profileProvider);
      final updated = profile.copyWith(
        taxLabel: label,
        defaultTaxRate: rate,
        isTaxInclusive: _isTaxInclusive,
        gstNumber: taxId,
        currency: _selectedCurrency,
      );

      await ref.read(profileProvider.notifier).updateProfile(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document settings updated ($label $rate% / $_selectedCurrency)!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schemes = CurrencyTaxService.commonTaxSchemes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Document Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.cardBorder, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Quick Tax Scheme Presets ──
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Tax Scheme Presets',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.2),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: schemes.map((s) {
                    final isSelected = _taxLabelController.text == s.label && _taxRateController.text == s.defaultRate.toString();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => _applyScheme(s),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.cardBorder,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${s.label} (${s.defaultRate.toStringAsFixed(0)}%)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // ── Tax Configuration Card ──
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Tax Rules',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Tax Label (e.g. GST, VAT, Sales Tax)',
                      controller: _taxLabelController,
                      icon: Icons.label_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Default Tax Rate (%)',
                      controller: _taxRateController,
                      icon: Icons.percent_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Tax ID / GSTIN Number',
                      controller: _taxIdController,
                      icon: Icons.receipt_long_outlined,
                      hint: 'e.g. GSTIN29ABCDE1234F1Z5',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calculate_outlined, color: AppColors.textSecondary, size: 22),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tax Inclusive Pricing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                Text('Item prices already include taxes', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isTaxInclusive,
                            activeThumbColor: AppColors.primary,
                            onChanged: (v) => setState(() => _isTaxInclusive = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Currency Selection Card ──
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Default Currency',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: _availableCurrencies.map((curr) {
                    final isCurrent = _selectedCurrency == curr['code'];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isCurrent ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            curr['symbol']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        '${curr['code']} - ${curr['name']}',
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                          color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20) : null,
                      onTap: () => setState(() => _selectedCurrency = curr['code']!),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, -4)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(
                    AppLocalizations.of(context)?.translate('save') ?? 'Save Changes',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
