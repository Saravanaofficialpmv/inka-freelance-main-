import 'package:flutter_test/flutter_test.dart';
import 'package:inka/services/currency_conversion_service.dart';

void main() {
  group('CurrencyConversionService Tests', () {
    test('Calculates identical currency rate as 1.0', () async {
      final rate = await CurrencyConversionService.getExchangeRate('USD', 'USD');
      expect(rate, 1.0);
    });

    test('Calculates cross rate from USD to INR using fallback rates', () async {
      final rate = await CurrencyConversionService.getExchangeRate('USD', 'INR');
      expect(rate, greaterThan(80.0));
    });

    test('Calculates cross rate from INR to USD', () async {
      final rate = await CurrencyConversionService.getExchangeRate('INR', 'USD');
      expect(rate, lessThan(1.0));
      expect(rate, greaterThan(0.0));
    });

    test('Calculates cross rate between non-USD pairs (EUR to INR)', () async {
      final rate = await CurrencyConversionService.getExchangeRate('EUR', 'INR');
      expect(rate, greaterThan(90.0));
    });

    test('Handles case insensitivity and whitespace', () async {
      final rate1 = await CurrencyConversionService.getExchangeRate('  usd ', 'eur ');
      final rate2 = await CurrencyConversionService.getExchangeRate('USD', 'EUR');
      expect(rate1, equals(rate2));
    });

    test('Fetches rates returns valid map with top currencies', () async {
      final rates = await CurrencyConversionService.fetchLatestUsdRates();
      expect(rates.containsKey('USD'), isTrue);
      expect(rates.containsKey('EUR'), isTrue);
      expect(rates.containsKey('INR'), isTrue);
      expect(rates.containsKey('JPY'), isTrue);
      expect(rates['USD'], 1.0);
    });
  });
}
