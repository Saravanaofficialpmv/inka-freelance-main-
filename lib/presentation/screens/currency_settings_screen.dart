import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/navigation_utils.dart';
import '../../data/models/business_profile.dart';
import '../../services/currency_tax_service.dart';
import '../../services/currency_conversion_service.dart';
import '../providers/profile_provider.dart';

class CurrencySettingsScreen extends ConsumerStatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  ConsumerState<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends ConsumerState<CurrencySettingsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final activeCurrency = CurrencyTaxService.findCurrency(profile.currency);

    final filteredCurrencies = CurrencyTaxService.top10Currencies.where((c) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return c.code.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q) ||
          c.symbol.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => safeNavigateBack(context, fallbackRoute: '/profile'),
        ),
        title: const Text(
          'Currency Settings',
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ── 3. Search Bar ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search currency name, code (USD, EUR, INR)...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── 4. Section Header ──
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Top 10 Major Currencies',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            // ── 5. Currency Cards List ──
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                children: filteredCurrencies.asMap().entries.map((entry) {
                  final index = entry.key;
                  final currency = entry.value;
                  final isSelected = activeCurrency.code.toUpperCase() == currency.code.toUpperCase();
                  final isLast = index == filteredCurrencies.length - 1;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(currency.flag, style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                currency.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 15,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currency.code,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${currency.symbol} • ${CurrencyTaxService.formatAmount(100.0, currencyCode: currency.code)}',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: isSelected
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Active',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const Icon(Icons.circle_outlined, color: AppColors.cardBorder, size: 22),
                        onTap: () async {
                          if (isSelected) return;
                          await _handleCurrencySelection(currency, activeCurrency, profile);
                        },
                      ),
                      if (!isLast)
                        const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFFF1F5F9)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCurrencySelection(
    CurrencyInfo targetCurrency,
    CurrencyInfo activeCurrency,
    BusinessProfile profile,
  ) async {
    final recordCounts = CurrencyConversionService.getExistingRecordCounts();
    final totalRecords = recordCounts.values.fold<int>(0, (sum, count) => sum + count);

    // If no existing records, directly update profile currency
    if (totalRecords == 0) {
      final updatedProfile = profile.copyWith(currency: targetCurrency.code);
      await ref.read(profileProvider.notifier).updateProfile(updatedProfile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Currency set to ${targetCurrency.name} (${targetCurrency.symbol})'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    // Fetch real-time exchange rate between active and target currencies
    final rate = await CurrencyConversionService.getExchangeRate(activeCurrency.code, targetCurrency.code);
    if (!mounted) return;

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => _buildConversionDialog(
        ctx,
        activeCurrency: activeCurrency,
        targetCurrency: targetCurrency,
        rate: rate,
        recordCounts: recordCounts,
        totalRecords: totalRecords,
      ),
    );

    if (action == null || action == 'cancel' || !mounted) return;

    if (action == 'convert') {
      _showConvertingDialog(context);

      final summary = await CurrencyConversionService.convertAllData(
        fromCurrency: activeCurrency.code,
        toCurrency: targetCurrency.code,
        ref: ref,
        customRate: rate,
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Converted ${summary.totalRecordsConverted} records to ${targetCurrency.code} at 1 ${activeCurrency.code} = ${rate >= 1 ? rate.toStringAsFixed(2) : rate.toStringAsFixed(4)} ${targetCurrency.code}',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildConversionDialog(
    BuildContext context, {
    required CurrencyInfo activeCurrency,
    required CurrencyInfo targetCurrency,
    required double rate,
    required Map<String, int> recordCounts,
    required int totalRecords,
  }) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_exchange_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Convert to ${targetCurrency.name}?',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Exchange Rate Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(activeCurrency.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '1 ${activeCurrency.code}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textSecondary),
                ),
                Text(targetCurrency.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '${rate >= 1 ? rate.toStringAsFixed(2) : rate.toStringAsFixed(4)} ${targetCurrency.code}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Details Note
          Text(
            'Inka will convert all $totalRecords existing records to ${targetCurrency.name} (${targetCurrency.symbol}) at the up-to-date exchange rate.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),

          // Records Breakdown Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                if (recordCounts['invoices']! > 0)
                  _buildRecordRow('Invoices & Line Items', '${recordCounts['invoices']} bills', Icons.receipt_long_rounded),
                if (recordCounts['products']! > 0)
                  _buildRecordRow('Product Catalog', '${recordCounts['products']} items', Icons.inventory_2_rounded),
                if (recordCounts['expenses']! > 0)
                  _buildRecordRow('Expenses', '${recordCounts['expenses']} entries', Icons.payments_rounded),
                if (recordCounts['projects']! > 0)
                  _buildRecordRow('Projects & Budgets', '${recordCounts['projects']} projects', Icons.folder_special_rounded),
                if (recordCounts['timeEntries']! > 0)
                  _buildRecordRow('Time Tracking Rates', '${recordCounts['timeEntries']} logs', Icons.timer_rounded),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Primary Convert Button
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('convert'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'Convert All Data to ${targetCurrency.code} (${targetCurrency.symbol})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),

          // Cancel
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordRow(String title, String count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            count,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showConvertingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: const [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Converting Records...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Applying live exchange rate...',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
