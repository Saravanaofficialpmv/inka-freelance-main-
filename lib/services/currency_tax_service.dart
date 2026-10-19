import 'package:intl/intl.dart';

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final String flag;
  final int decimalDigits;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
    this.decimalDigits = 2,
  });
}

class TaxScheme {
  final String label;
  final String region;
  final double defaultRate;
  final String idPrompt; // e.g. "VAT Number", "GSTIN", "Sales Tax ID"

  const TaxScheme({
    required this.label,
    required this.region,
    required this.defaultRate,
    required this.idPrompt,
  });
}

class CurrencyTaxService {
  static const List<CurrencyInfo> top10Currencies = [
    CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar', flag: '🇺🇸'),
    CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇺'),
    CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound', flag: '🇬🇧'),
    CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee', flag: '🇮🇳'),
    CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen', flag: '🇯🇵', decimalDigits: 0),
    CurrencyInfo(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar', flag: '🇨🇦'),
    CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', flag: '🇦🇺'),
    CurrencyInfo(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc', flag: '🇨🇭'),
    CurrencyInfo(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', flag: '🇸🇬'),
    CurrencyInfo(code: 'AED', symbol: 'AED', name: 'UAE Dirham', flag: '🇦🇪'),
  ];

  static const List<CurrencyInfo> supportedCurrencies = [
    ...top10Currencies,
    CurrencyInfo(code: 'SAR', symbol: 'SAR', name: 'Saudi Riyal', flag: '🇸🇦'),
    CurrencyInfo(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar', flag: '🇳🇿'),
  ];

  static const List<TaxScheme> commonTaxSchemes = [
    TaxScheme(label: 'GST', region: 'India / Australia / Singapore', defaultRate: 18.0, idPrompt: 'GSTIN / GST Reg Number'),
    TaxScheme(label: 'VAT', region: 'Europe / UK / Middle East', defaultRate: 20.0, idPrompt: 'VAT Identification Number'),
    TaxScheme(label: 'Sales Tax', region: 'United States', defaultRate: 8.25, idPrompt: 'State Tax Permit / EIN'),
    TaxScheme(label: 'HST', region: 'Canada (Harmonized)', defaultRate: 13.0, idPrompt: 'CRA Business Number'),
    TaxScheme(label: 'TVA', region: 'France / Belgium', defaultRate: 20.0, idPrompt: 'Numéro de TVA'),
    TaxScheme(label: 'None / 0%', region: 'Tax Exempt / Export', defaultRate: 0.0, idPrompt: 'Tax Exempt ID'),
  ];

  static CurrencyInfo findCurrency(String? codeOrSymbol) {
    if (codeOrSymbol == null || codeOrSymbol.trim().isEmpty) {
      return supportedCurrencies.first;
    }
    final trimmed = codeOrSymbol.trim().toLowerCase();
    return supportedCurrencies.firstWhere(
      (c) => c.code.toLowerCase() == trimmed || c.symbol.toLowerCase() == trimmed,
      orElse: () => supportedCurrencies.first,
    );
  }

  static String getCurrencySymbol(String? currencyCode) {
    return findCurrency(currencyCode ?? 'USD').symbol;
  }

  static NumberFormat getCurrencyFormatter({String? currencyCode, int? decimalDigits}) {
    final cur = findCurrency(currencyCode ?? 'USD');
    return NumberFormat.currency(
      symbol: cur.symbol,
      decimalDigits: decimalDigits ?? cur.decimalDigits,
    );
  }

  static String formatAmount(double amount, {String? currencyCode}) {
    return getCurrencyFormatter(currencyCode: currencyCode).format(amount);
  }
}
