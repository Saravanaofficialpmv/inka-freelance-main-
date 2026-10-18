import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../data/models/expense.dart';
import '../data/models/invoice.dart';
import '../data/models/product.dart';
import '../data/models/project.dart';
import '../data/models/time_entry.dart';
import '../presentation/providers/product_provider.dart';
import '../presentation/providers/profile_provider.dart';
import '../presentation/viewmodels/expense_viewmodel.dart';
import '../presentation/viewmodels/invoice_viewmodel.dart';
import '../presentation/viewmodels/project_viewmodel.dart';
import '../presentation/viewmodels/time_tracker_viewmodel.dart';
import 'firestore_service.dart';

class CurrencyConversionSummary {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final int invoicesCount;
  final int productsCount;
  final int expensesCount;
  final int timeEntriesCount;
  final int projectsCount;

  const CurrencyConversionSummary({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.invoicesCount,
    required this.productsCount,
    required this.expensesCount,
    required this.timeEntriesCount,
    required this.projectsCount,
  });

  int get totalRecordsConverted =>
      invoicesCount + productsCount + expensesCount + timeEntriesCount + projectsCount;
}

class CurrencyConversionService {
  static Map<String, double>? _cachedRates;
  static DateTime? _lastCacheTime;

  /// Baseline fallback exchange rates (relative to 1 USD)
  static const Map<String, double> _fallbackUsdRates = {
    'USD': 1.0,
    'EUR': 0.861,
    'GBP': 0.740,
    'INR': 94.51,
    'JPY': 156.17,
    'CAD': 1.383,
    'AUD': 1.388,
    'CHF': 0.810,
    'SGD': 1.267,
    'AED': 3.6725,
    'SAR': 3.750,
    'NZD': 1.700,
  };

  /// Fetches latest real-time rates from public open API with offline fallback
  static Future<Map<String, double>> fetchLatestUsdRates() async {
    if (_cachedRates != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < const Duration(hours: 1)) {
      return _cachedRates!;
    }

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      final response = await request.close().timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        if (data['result'] == 'success' && data['rates'] is Map) {
          final rawRates = data['rates'] as Map<String, dynamic>;
          final parsed = <String, double>{};
          rawRates.forEach((k, v) {
            if (v is num) parsed[k.toUpperCase()] = v.toDouble();
          });
          _cachedRates = parsed;
          _lastCacheTime = DateTime.now();
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('CurrencyConversionService live rates fetch error (using fallback): $e');
    }

    return _fallbackUsdRates;
  }

  /// Calculates exchange rate multiplier from [fromCurrency] to [toCurrency]
  static Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    final from = fromCurrency.toUpperCase().trim();
    final to = toCurrency.toUpperCase().trim();
    if (from == to) return 1.0;

    final rates = await fetchLatestUsdRates();
    final fromUsdRate = rates[from] ?? _fallbackUsdRates[from] ?? 1.0;
    final toUsdRate = rates[to] ?? _fallbackUsdRates[to] ?? 1.0;

    if (fromUsdRate <= 0) return 1.0;
    return toUsdRate / fromUsdRate;
  }

  /// Counts existing records that contain monetary data
  static Map<String, int> getExistingRecordCounts() {
    return {
      'invoices': Hive.isBoxOpen('invoices') ? Hive.box<Invoice>('invoices').length : 0,
      'products': Hive.isBoxOpen('products') ? Hive.box<Product>('products').length : 0,
      'expenses': Hive.isBoxOpen('expenses') ? Hive.box<Expense>('expenses').length : 0,
      'timeEntries': Hive.isBoxOpen('time_entries') ? Hive.box<TimeEntry>('time_entries').length : 0,
      'projects': Hive.isBoxOpen('projects') ? Hive.box<Project>('projects').length : 0,
    };
  }

  /// Converts all existing data across the app to [toCurrency] at current exchange rate
  static Future<CurrencyConversionSummary> convertAllData({
    required String fromCurrency,
    required String toCurrency,
    required WidgetRef ref,
    double? customRate,
  }) async {
    final from = fromCurrency.toUpperCase().trim();
    final to = toCurrency.toUpperCase().trim();
    final rate = customRate ?? await getExchangeRate(from, to);

    final firestore = ref.read(firestoreServiceProvider);

    final productsBox = Hive.box<Product>('products');
    final invoicesBox = Hive.box<Invoice>('invoices');
    final expensesBox = Hive.box<Expense>('expenses');
    final timeEntriesBox = Hive.box<TimeEntry>('time_entries');
    final projectsBox = Hive.box<Project>('projects');

    int productsCount = 0;
    int invoicesCount = 0;
    int expensesCount = 0;
    int timeEntriesCount = 0;
    int projectsCount = 0;

    // 1. Convert Products
    for (var product in productsBox.values.toList()) {
      final convertedPrice = _round(product.defaultPrice * rate, to);
      final updated = product.copyWith(defaultPrice: convertedPrice);
      await productsBox.put(updated.id, updated);
      try {
        await firestore.saveProduct(updated);
      } catch (_) {}
      productsCount++;
    }

    // 2. Convert Invoices (Items and Discount)
    for (var invoice in invoicesBox.values.toList()) {
      final updatedItems = invoice.items.map((item) {
        final convertedPrice = _round(item.price * rate, to);
        return item.copyWith(price: convertedPrice);
      }).toList();

      final convertedDiscount = _round(invoice.discount * rate, to);
      final updated = invoice.copyWith(
        items: updatedItems,
        discount: convertedDiscount,
      );
      await invoicesBox.put(updated.id, updated);
      try {
        await firestore.saveInvoice(updated);
      } catch (_) {}
      invoicesCount++;
    }

    // 3. Convert Expenses
    for (var expense in expensesBox.values.toList()) {
      final convertedAmount = _round(expense.amount * rate, to);
      final updated = expense.copyWith(amount: convertedAmount);
      await expensesBox.put(updated.id, updated);
      try {
        await firestore.saveExpense(updated);
      } catch (_) {}
      expensesCount++;
    }

    // 4. Convert Time Entries (Hourly Rate)
    for (var entry in timeEntriesBox.values.toList()) {
      final convertedRate = _round(entry.hourlyRate * rate, to);
      final updated = entry.copyWith(hourlyRate: convertedRate);
      await timeEntriesBox.put(updated.id, updated);
      try {
        await firestore.saveTimeEntry(updated);
      } catch (_) {}
      timeEntriesCount++;
    }

    // 5. Convert Projects (Budget & Received Amount)
    for (var project in projectsBox.values.toList()) {
      final convertedBudget = _round(project.budget * rate, to);
      final convertedReceived = _round(project.receivedAmount * rate, to);
      final updated = project.copyWith(
        budget: convertedBudget,
        receivedAmount: convertedReceived,
      );
      await projectsBox.put(updated.id, updated);
      try {
        await firestore.saveProject(updated);
      } catch (_) {}
      projectsCount++;
    }

    // 6. Update Profile Currency
    final currentProfile = ref.read(profileProvider);
    final updatedProfile = currentProfile.copyWith(currency: to);
    await ref.read(profileProvider.notifier).updateProfile(updatedProfile);

    // 7. Refresh all Riverpod notifiers to immediately reflect changes on screen
    ref.read(productsProvider.notifier).refreshFromLocal();
    ref.read(invoiceProvider.notifier).refreshFromLocal();
    ref.read(expenseProvider.notifier).refreshFromLocal();
    ref.read(timeEntriesProvider.notifier).refreshFromLocal();
    ref.read(projectProvider.notifier).refreshFromLocal();
    ref.read(profileProvider.notifier).loadFromLocal();

    return CurrencyConversionSummary(
      fromCurrency: from,
      toCurrency: to,
      rate: rate,
      invoicesCount: invoicesCount,
      productsCount: productsCount,
      expensesCount: expensesCount,
      timeEntriesCount: timeEntriesCount,
      projectsCount: projectsCount,
    );
  }

  /// Decimal rounding helper
  static double _round(double amount, String currency) {
    if (amount == 0.0) return 0.0;
    if (currency.toUpperCase() == 'JPY') {
      return amount.roundToDouble();
    }
    return double.parse((amount).toStringAsFixed(2));
  }
}
