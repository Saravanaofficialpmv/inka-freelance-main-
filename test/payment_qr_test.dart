import 'package:flutter_test/flutter_test.dart';
import 'package:inka/services/payment_qr_service.dart';

void main() {
  group('PaymentQrService Tests (subhadeepdutta12/paymentqrgenerator port)', () {
    test('Builds generic UPI payment URL correctly', () {
      final url = PaymentQrService.buildUpiUrl(
        upiId: 'freelancer@okhdfcbank',
        payeeName: 'John Doe',
        amount: 2500.0,
        invoiceNumber: 'INV-2026-001',
      );

      expect(url, contains('upi://pay?'));
      expect(url, contains('pa=freelancer@okhdfcbank'));
      expect(url, contains('pn=John%20Doe'));
      expect(url, contains('am=2500.00'));
      expect(url, contains('cu=INR'));
      expect(url, contains('tr=INV-2026-001'));
    });

    test('Builds PhonePe optimized URL correctly with merchant code', () {
      final url = PaymentQrService.buildUpiUrl(
        upiId: 'merchant@ybl',
        payeeName: 'Studio Design',
        amount: 5000.0,
        appType: UpiAppType.phonePe,
      );

      expect(url, contains('pa=merchant@ybl'));
      expect(url, contains('pn=Studio%20Design'));
      expect(url, contains('am=5000.00'));
      expect(url, contains('mc=1234'));
    });

    test('Builds Google Pay and Paytm URLs correctly', () {
      final gpayUrl = PaymentQrService.buildUpiUrl(
        upiId: 'gpayuser@okaxis',
        payeeName: 'Dev Agency',
        amount: 1200.0,
        appType: UpiAppType.googlePay,
      );
      expect(gpayUrl, contains('pa=gpayuser@okaxis'));
      expect(gpayUrl, contains('am=1200.00'));

      final paytmUrl = PaymentQrService.buildUpiUrl(
        upiId: '9876543210@paytm',
        payeeName: 'Consultant',
        amount: 350.0,
        appType: UpiAppType.paytm,
      );
      expect(paytmUrl, contains('pa=9876543210@paytm'));
      expect(paytmUrl, contains('am=350.00'));
    });
  });
}
