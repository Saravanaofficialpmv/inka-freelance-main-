import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'invoice_template.dart';

/// Template 04 — Creative Modern
/// Vibrant violet styling, geometric ribbon accents, creative agency branding, and clean modern layout.
class CreativeModernTemplate extends InvoiceTemplate {
  @override
  String get id => 'creative_modern';

  @override
  String get name => 'Creative Modern';

  @override
  String get description => 'Vibrant violet accents, geometric styling, designed for creative studios & freelancers';

  @override
  String get defaultAccentColorHex => '#7C3AED';

  @override
  String get icon => '🎨';

  @override
  String get tag => 'Creative / Agency';

  @override
  String get assetPreview => 'assets/templates/template_service.jpg';

  @override
  void buildPage(pw.Document pdf, TemplateRenderContext ctx) {
    final violetColor = pdf_lib.PdfColor.fromHex('#7C3AED');
    final darkColor = pdf_lib.PdfColor.fromHex('#1E1B4B');
    final secondaryText = pdf_lib.PdfColor.fromHex('#6B7280');
    final violetLightBg = pdf_lib.PdfColor.fromHex('#F5F3FF');
    final borderLight = pdf_lib.PdfColor.fromHex('#DDD6FE');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: ctx.pageMargins,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 6),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: violetColor, width: 1.2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    ctx.profile.businessName.isNotEmpty ? ctx.profile.businessName : 'CREATIVE STUDIO',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkColor),
                  ),
                  pw.Text(
                    'INV-${ctx.invoice.invoiceNumber}  •  Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 8, color: secondaryText),
                  ),
                ],
              ),
            );
          }
          return pw.SizedBox();
        },
        build: (pw.Context context) {
          return [
            // ── Top Bar with Geometric Violet Ribbon ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (ctx.config.showLogo && ctx.logoImage != null)
                      pw.Container(
                        height: 40,
                        margin: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Image(ctx.logoImage!),
                      )
                    else
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: violetColor,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          ctx.profile.businessName.isNotEmpty
                              ? ctx.profile.businessName.toUpperCase()
                              : 'CREATIVE STUDIO',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.white, letterSpacing: 0.5),
                        ),
                      ),
                    if (ctx.config.showContactDetails) ...[
                      pw.SizedBox(height: 4),
                      if (ctx.profile.taxIdNumber != null && ctx.profile.taxIdNumber!.isNotEmpty)
                        pw.Text('${ctx.taxLabel}: ${ctx.profile.taxIdNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: violetColor))
                      else if (ctx.profile.gstNumber != null && ctx.profile.gstNumber!.isNotEmpty)
                        pw.Text('Tax ID: ${ctx.profile.gstNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: violetColor)),
                      if (ctx.profile.address.isNotEmpty)
                        pw.Text(ctx.profile.address, style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                      pw.Text('${ctx.profile.phone}  •  ${ctx.profile.email}', style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                    ],
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 1.0),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: violetLightBg,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: borderLight, width: 0.8),
                      ),
                      child: pw.Text(
                        '#${ctx.invoice.invoiceNumber}',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: violetColor),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Date: ${DateFormat('dd MMM yyyy').format(ctx.invoice.issueDate)}', style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                    pw.Text('Due: ${DateFormat('dd MMM yyyy').format(ctx.invoice.dueDate)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkColor)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Client Project Card ──
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: violetLightBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderLight, width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ISSUED FOR', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: violetColor, letterSpacing: 0.5)),
                      pw.SizedBox(height: 2),
                      pw.Text(ctx.invoice.client.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkColor)),
                      if (ctx.invoice.client.address.isNotEmpty)
                        pw.Text(ctx.invoice.client.address, style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                      if (ctx.invoice.client.email.isNotEmpty)
                        pw.Text(ctx.invoice.client.email, style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('STATUS', style: pw.TextStyle(fontSize: 7, color: secondaryText)),
                      pw.Text(ctx.invoice.status.toUpperCase(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: violetColor)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Items Table ──
            pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(24),
                1: pw.FlexColumnWidth(4.5),
                2: pw.FlexColumnWidth(1.2),
                3: pw.FlexColumnWidth(2.0),
                4: pw.FlexColumnWidth(2.2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: violetColor,
                    borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
                  ),
                  children: [
                    _cell('#', align: pw.TextAlign.left, isHeader: true, vPad: ctx.rowVerticalPadding),
                    _cell('SERVICES / DELIVERABLES', align: pw.TextAlign.left, isHeader: true, vPad: ctx.rowVerticalPadding),
                    _cell('QTY', align: pw.TextAlign.center, isHeader: true, vPad: ctx.rowVerticalPadding),
                    _cell('RATE', align: pw.TextAlign.right, isHeader: true, vPad: ctx.rowVerticalPadding),
                    _cell('TOTAL', align: pw.TextAlign.right, isHeader: true, vPad: ctx.rowVerticalPadding),
                  ],
                ),
                ...ctx.invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey200, width: 0.5)),
                    ),
                    children: [
                      _cell('$idx', align: pw.TextAlign.left, color: secondaryText, vPad: ctx.rowVerticalPadding),
                      _cell(item.name, align: pw.TextAlign.left, color: darkColor, isBold: true, vPad: ctx.rowVerticalPadding),
                      _cell('${item.quantity}', align: pw.TextAlign.center, color: darkColor, vPad: ctx.rowVerticalPadding),
                      _cell(ctx.currencyFormat.format(item.price), align: pw.TextAlign.right, color: darkColor, vPad: ctx.rowVerticalPadding),
                      _cell(ctx.currencyFormat.format(item.total), align: pw.TextAlign.right, color: darkColor, isBold: true, vPad: ctx.rowVerticalPadding),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Totals Box ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 220,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: violetLightBg,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: borderLight, width: 0.8),
                  ),
                  child: pw.Column(
                    children: [
                      _row('Subtotal', ctx.formattedSubtotal, darkColor, secondaryText),
                      if (ctx.invoice.taxPercentage > 0)
                        _row('${ctx.taxLabel} (${ctx.invoice.taxPercentage.toStringAsFixed(0)}%)', ctx.formattedTax, darkColor, secondaryText),
                      if (ctx.invoice.discount > 0)
                        _row('Discount', '- ${ctx.formattedDiscount}', pdf_lib.PdfColor.fromHex('#10B981'), secondaryText),
                      pw.Divider(color: violetColor, thickness: 1.0),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Due:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkColor)),
                          pw.Text(ctx.formattedTotal, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: violetColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Bottom: Payment details, QR, Notes, Signature ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      PdfSharedComponents.buildBankDetailsWidget(ctx, labelColor: violetColor, valueColor: darkColor),
                      if (ctx.hasBankDetails) pw.SizedBox(height: 8),
                      PdfSharedComponents.buildNotesWidget(ctx, labelColor: violetColor, bodyColor: darkColor),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                if (ctx.config.showQrCode && ctx.hasUpiPayment)
                  PdfSharedComponents.buildUpiQrWidget(ctx, size: 54),
                pw.SizedBox(width: 16),
                if (ctx.config.showSignature)
                  PdfSharedComponents.buildSignatureWidget(ctx, textColor: darkColor, lineColor: violetColor),
              ],
            ),
          ];
        },
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isHeader = false,
    bool isBold = false,
    pdf_lib.PdfColor? color,
    double vPad = 5.0,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 5, vertical: vPad),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 7.5 : 8.5,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? pdf_lib.PdfColors.white : (color ?? pdf_lib.PdfColors.black),
        ),
      ),
    );
  }

  static pw.Widget _row(String label, String value, pdf_lib.PdfColor valColor, pdf_lib.PdfColor lblColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: lblColor)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: valColor)),
        ],
      ),
    );
  }
}
