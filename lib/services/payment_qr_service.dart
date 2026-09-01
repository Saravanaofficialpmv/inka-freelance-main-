import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpiAppType {
  generic,
  googlePay,
  phonePe,
  paytm,
}

class PaymentQrService {
  /// Builds a standard or app-specific UPI payment URL based on the subhadeepdutta12/paymentqrgenerator specification
  static String buildUpiUrl({
    required String upiId,
    required String payeeName,
    double? amount,
    String? transactionNote,
    String? invoiceNumber,
    String currency = 'INR',
    UpiAppType appType = UpiAppType.generic,
  }) {
    final cleanUpiId = upiId.trim();
    final encodedName = Uri.encodeComponent(payeeName.trim());
    final encodedNote = Uri.encodeComponent(
      transactionNote ?? (invoiceNumber != null ? 'Invoice $invoiceNumber' : 'Payment'),
    );

    final params = <String>[
      'pa=$cleanUpiId',
      'pn=$encodedName',
      if (amount != null && amount > 0) 'am=${amount.toStringAsFixed(2)}',
      'cu=$currency',
      'tn=$encodedNote',
      if (invoiceNumber != null) 'tr=$invoiceNumber',
    ];

    switch (appType) {
      case UpiAppType.phonePe:
        params.add('mc=1234');
        return 'upi://pay?${params.join('&')}';
      case UpiAppType.paytm:
        return 'upi://pay?${params.join('&')}';
      case UpiAppType.googlePay:
        return 'upi://pay?${params.join('&')}';
      case UpiAppType.generic:
        return 'upi://pay?${params.join('&')}';
    }
  }

  /// Launch UPI payment intent directly into PhonePe, Paytm, Google Pay or device default
  static Future<bool> launchPayment({
    required String upiId,
    required String payeeName,
    double? amount,
    String? transactionNote,
    String? invoiceNumber,
    UpiAppType appType = UpiAppType.generic,
  }) async {
    final urlString = buildUpiUrl(
      upiId: upiId,
      payeeName: payeeName,
      amount: amount,
      transactionNote: transactionNote,
      invoiceNumber: invoiceNumber,
      appType: appType,
    );

    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching UPI URI $urlString: $e');
    }
    return false;
  }

  /// Generates high-resolution PNG image bytes of the QR Code
  static Future<Uint8List?> generateQrImageBytes({
    required String data,
    double size = 400.0,
  }) async {
    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: true,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF000000),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF000000),
        ),
      );

      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      painter.paint(canvas, Size(size, size));
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating QR image bytes: $e');
      return null;
    }
  }
}
