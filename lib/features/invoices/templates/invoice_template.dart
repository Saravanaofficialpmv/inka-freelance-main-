import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/business_profile.dart';
import '../../../data/models/invoice.dart';
import '../../../services/currency_tax_service.dart';
import '../../../services/payment_qr_service.dart';
import 'invoice_template_config.dart';

/// Context provided to every template builder containing validated models,
/// loaded typography, decoded images, and appearance settings.
class TemplateRenderContext {
  final Invoice invoice;
  final BusinessProfile profile;
  final InvoiceTemplateConfig config;
  final pw.Font? regularFont;
  final pw.Font? boldFont;
  final pw.MemoryImage? logoImage;
  final pw.MemoryImage? signatureImage;
  final NumberFormat currencyFormat;

  const TemplateRenderContext({
    required this.invoice,
    required this.profile,
    required this.config,
    this.regularFont,
    this.boldFont,
    this.logoImage,
    this.signatureImage,
    required this.currencyFormat,
  });

  /// The active accent color resolved from user configuration or fallback.
  pdf_lib.PdfColor get accentColor =>
      pdf_lib.PdfColor.fromHex(config.accentColorHex);

  /// Margins scaled according to density.
  pw.EdgeInsets get pageMargins {
    switch (config.density) {
      case InvoiceDensity.compact:
        return const pw.EdgeInsets.all(24);
      case InvoiceDensity.spacious:
        return const pw.EdgeInsets.all(40);
      case InvoiceDensity.normal:
        return const pw.EdgeInsets.all(32);
    }
  }

  /// Vertical padding for table rows scaled by density.
  double get rowVerticalPadding {
    switch (config.density) {
      case InvoiceDensity.compact:
        return 3.5;
      case InvoiceDensity.spacious:
        return 7.0;
      case InvoiceDensity.normal:
        return 5.0;
    }
  }

  /// Section spacing scaled by density.
  double get sectionSpacing {
    switch (config.density) {
      case InvoiceDensity.compact:
        return 10.0;
      case InvoiceDensity.spacious:
        return 20.0;
      case InvoiceDensity.normal:
        return 14.0;
    }
  }

  String get currencySymbol =>
      CurrencyTaxService.getCurrencySymbol(profile.currency);

  String get formattedSubtotal => currencyFormat.format(invoice.subtotal);
  String get formattedTax => currencyFormat.format(invoice.taxAmount);
  String get formattedDiscount => currencyFormat.format(invoice.discount);
  String get formattedTotal => currencyFormat.format(invoice.total);

  String get taxLabel =>
      profile.taxLabel.isNotEmpty ? profile.taxLabel : 'Tax';

  bool get hasBankDetails =>
      (profile.accountNo != null && profile.accountNo!.trim().isNotEmpty) ||
      (profile.upiId != null && profile.upiId!.trim().isNotEmpty);

  bool get hasUpiPayment =>
      profile.upiId != null && profile.upiId!.trim().isNotEmpty;
}

/// Abstract contract that each of the 10 invoice templates implements.
abstract class InvoiceTemplate {
  String get id;
  String get name;
  String get description;
  String get defaultAccentColorHex;
  String get icon;
  String get tag;
  String get assetPreview;

  /// Builds and appends pages to the provided PDF document.
  void buildPage(pw.Document pdf, TemplateRenderContext ctx);
}

/// Shared reusable vector widgets for consistent, high-fidelity PDF rendering.
class PdfSharedComponents {
  /// Renders a dynamic vector UPI QR code inside a high-contrast container.
  /// Includes quiet zone margins so it scans accurately on any background.
  static pw.Widget buildUpiQrWidget(
    TemplateRenderContext ctx, {
    double size = 56,
    bool darkBackground = false,
  }) {
    if (!ctx.config.showQrCode || !ctx.hasUpiPayment) {
      return pw.SizedBox();
    }

    final upiUrl = PaymentQrService.buildUpiUrl(
      upiId: ctx.profile.upiId!,
      payeeName: ctx.profile.businessName.isNotEmpty
          ? ctx.profile.businessName
          : 'Business Payment',
      amount: ctx.invoice.total,
      invoiceNumber: ctx.invoice.invoiceNumber,
      currency: ctx.profile.currency.isNotEmpty ? ctx.profile.currency : 'INR',
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        color: pdf_lib.PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(
          color: darkBackground
              ? pdf_lib.PdfColors.white
              : pdf_lib.PdfColors.grey300,
          width: 0.8,
        ),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: upiUrl,
            width: size,
            height: size,
            color: pdf_lib.PdfColors.black,
            backgroundColor: pdf_lib.PdfColors.white,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'SCAN & PAY',
            style: pw.TextStyle(
              fontSize: 5.5,
              fontWeight: pw.FontWeight.bold,
              color: pdf_lib.PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Renders formatted bank account particulars.
  static pw.Widget buildBankDetailsWidget(
    TemplateRenderContext ctx, {
    pdf_lib.PdfColor? labelColor,
    pdf_lib.PdfColor? valueColor,
  }) {
    if (!ctx.config.showBankDetails || !ctx.hasBankDetails) {
      return pw.SizedBox();
    }

    final lColor = labelColor ?? pdf_lib.PdfColors.grey600;
    final vColor = valueColor ?? pdf_lib.PdfColors.grey900;
    final p = ctx.profile;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          'PAYMENT DETAILS',
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: lColor,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 3),
        if (p.bankName != null && p.bankName!.isNotEmpty)
          pw.Row(children: [
            pw.Text('Bank: ', style: pw.TextStyle(fontSize: 7.5, color: lColor)),
            pw.Text(p.bankName!, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: vColor)),
          ]),
        if (p.accountNo != null && p.accountNo!.isNotEmpty)
          pw.Row(children: [
            pw.Text('A/C No: ', style: pw.TextStyle(fontSize: 7.5, color: lColor)),
            pw.Text(p.accountNo!, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: vColor)),
          ]),
        if (p.ifscCode != null && p.ifscCode!.isNotEmpty)
          pw.Row(children: [
            pw.Text('IFSC / SWIFT: ', style: pw.TextStyle(fontSize: 7.5, color: lColor)),
            pw.Text(p.ifscCode!, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: vColor)),
          ]),
        if (p.upiId != null && p.upiId!.isNotEmpty)
          pw.Row(children: [
            pw.Text('UPI VPA: ', style: pw.TextStyle(fontSize: 7.5, color: lColor)),
            pw.Text(p.upiId!, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: vColor)),
          ]),
      ],
    );
  }

  /// Renders authorized signature and stamp line.
  static pw.Widget buildSignatureWidget(
    TemplateRenderContext ctx, {
    pdf_lib.PdfColor? textColor,
    pdf_lib.PdfColor? lineColor,
    double maxHeight = 40,
  }) {
    if (!ctx.config.showSignature) {
      return pw.SizedBox();
    }

    final tColor = textColor ?? pdf_lib.PdfColors.grey800;
    final lColor = lineColor ?? pdf_lib.PdfColors.grey400;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (ctx.signatureImage != null)
          pw.Container(
            height: maxHeight,
            alignment: pw.Alignment.bottomCenter,
            child: pw.Image(ctx.signatureImage!, height: maxHeight, fit: pw.BoxFit.contain),
          )
        else
          pw.SizedBox(height: maxHeight),
        pw.Container(
          width: 120,
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: lColor, width: 0.8)),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'Authorized Signature',
          style: pw.TextStyle(fontSize: 7.5, color: tColor),
        ),
      ],
    );
  }

  /// Renders notes and terms.
  static pw.Widget buildNotesWidget(
    TemplateRenderContext ctx, {
    pdf_lib.PdfColor? labelColor,
    pdf_lib.PdfColor? bodyColor,
  }) {
    if (!ctx.config.showNotesAndTerms || ctx.invoice.notes.trim().isEmpty) {
      return pw.SizedBox();
    }

    final lColor = labelColor ?? pdf_lib.PdfColors.grey600;
    final bColor = bodyColor ?? pdf_lib.PdfColors.grey800;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          'TERMS & NOTES',
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: lColor,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          ctx.invoice.notes.trim(),
          style: pw.TextStyle(fontSize: 7.5, color: bColor),
        ),
      ],
    );
  }

  /// Converts positive integer to words.
  static String numberToWords(int number) {
    if (number == 0) return 'Zero';
    if (number < 0) return 'Minus ${numberToWords(-number)}';
    const units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];
    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    if (number < 20) return units[number];
    if (number < 100) {
      return tens[number ~/ 10] + (number % 10 != 0 ? ' ${units[number % 10]}' : '');
    }
    if (number < 1000) {
      return '${units[number ~/ 100]} Hundred${number % 100 != 0 ? ' and ${numberToWords(number % 100)}' : ''}';
    }
    if (number < 1000000) {
      return '${numberToWords(number ~/ 1000)} Thousand${number % 1000 != 0 ? ' ${numberToWords(number % 1000)}' : ''}';
    }
    if (number < 1000000000) {
      return '${numberToWords(number ~/ 1000000)} Million${number % 1000000 != 0 ? ' ${numberToWords(number % 1000000)}' : ''}';
    }
    return number.toString();
  }
}
