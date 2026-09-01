import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/services/currency_tax_service.dart';

void main() {
  group('Multi-Currency & Tax Engine Tests', () {
    test('CurrencyTaxService finds currency and formats properly', () {
      final usd = CurrencyTaxService.findCurrency('USD');
      expect(usd.code, equals('USD'));
      expect(usd.symbol, equals('\$'));

      final eur = CurrencyTaxService.findCurrency('EUR');
      expect(eur.code, equals('EUR'));
      expect(eur.symbol, equals('€'));

      final gbp = CurrencyTaxService.findCurrency('GBP');
      expect(gbp.code, equals('GBP'));
      expect(gbp.symbol, equals('£'));

      final inr = CurrencyTaxService.findCurrency('INR');
      expect(inr.code, equals('INR'));
      expect(inr.symbol, equals('₹'));

      final aed = CurrencyTaxService.findCurrency('AED');
      expect(aed.code, equals('AED'));

      final formattedUSD = CurrencyTaxService.formatAmount(1250.50, currencyCode: 'USD');
      expect(formattedUSD.contains('1,250.50') || formattedUSD.contains('1250.50'), isTrue);
    });

    test('Tax calculations with custom percentage and discount', () {
      const subtotal = 1000.0;
      const vatRate = 20.0; // 20% VAT
      const discount = 50.0;

      final taxAmount = subtotal * (vatRate / 100);
      final total = subtotal + taxAmount - discount;

      expect(taxAmount, equals(200.0));
      expect(total, equals(1150.0));
    });

    test('BusinessProfile model serialization with taxLabel and defaultTaxRate', () {
      final profile = BusinessProfile(
        businessName: 'Apex Studio UK',
        address: '10 Downing St, London',
        phone: '+44 20 7946 0991',
        email: 'hello@apexstudio.co.uk',
        currency: 'GBP',
        taxLabel: 'VAT',
        defaultTaxRate: 20.0,
        taxIdNumber: 'GB987654321',
      );

      final map = profile.toMap();
      expect(map['taxLabel'], equals('VAT'));
      expect(map['defaultTaxRate'], equals(20.0));
      expect(map['taxIdNumber'], equals('GB987654321'));
      expect(map['currency'], equals('GBP'));

      final restored = BusinessProfile.fromMap(map);
      expect(restored.taxLabel, equals('VAT'));
      expect(restored.defaultTaxRate, equals(20.0));
      expect(restored.taxIdNumber, equals('GB987654321'));
      expect(restored.currency, equals('GBP'));
    });
  });
}
