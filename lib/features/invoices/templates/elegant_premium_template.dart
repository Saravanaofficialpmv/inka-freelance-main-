import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'invoice_template.dart';

/// Template 03 — Elegant Premium
/// Deep navy corporate aesthetic, elegant typography hierarchy, structured two-column info, and solid navy headers.
class ElegantPremiumTemplate extends InvoiceTemplate {
  @override
  String get id => 'elegant_premium';

  @override
  String get name => 'Elegant Premium';

  @override
  String get description => 'Deep navy corporate header, refined typography, and executive financial summary';

  @override
  String get defaultAccentColorHex => '#1E3A8A';

  @override
  String get icon => '🏛️';

  @override
  String get tag => 'Executive / B2B';

  @override
  String get assetPreview => 'assets/templates/template_classic.jpg';

  @override
  void buildPage(pw.Document pdf, TemplateRenderContext ctx) {
    final navyColor = pdf_lib.PdfColor.fromHex('#1E3A8A');
    final darkNavy = pdf_lib.PdfColor.fromHex('#0F172A');
    final slate = pdf_lib.PdfColor.fromHex('#475569');
    final lightNavyBg = pdf_lib.PdfColor.fromHex('#F8FAFC');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: ctx.pageMargins,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 6),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey300, width: 0.8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    ctx.profile.businessName.isNotEmpty ? ctx.profile.businessName : 'TAX INVOICE',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkNavy),
                  ),
                  pw.Text(
                    'Invoice #${ctx.invoice.invoiceNumber}  •  Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 8, color: slate),
                  ),
                ],
              ),
            );
          }
          return pw.SizedBox();
        },
        build: (pw.Context context) {
          return [
            // ── Top Header Bar (Navy Accented) ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (ctx.config.showLogo && ctx.logoImage != null)
                      pw.Container(
                        height: 42,
                        margin: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Image(ctx.logoImage!),
                      )
                    else
                      pw.Text(
                        ctx.profile.businessName.isNotEmpty ? ctx.profile.businessName : 'CORPORATION',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: darkNavy,
                          letterSpacing: 0.8,
                        ),
                      ),
                    if (ctx.config.showContactDetails) ...[
                      if (ctx.profile.taxIdNumber != null && ctx.profile.taxIdNumber!.isNotEmpty)
                        pw.Text('${ctx.taxLabel}: ${ctx.profile.taxIdNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: navyColor))
                      else if (ctx.profile.gstNumber != null && ctx.profile.gstNumber!.isNotEmpty)
                        pw.Text('Tax ID: ${ctx.profile.gstNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: navyColor)),
                      if (ctx.profile.address.isNotEmpty)
                        pw.Text(ctx.profile.address, style: pw.TextStyle(fontSize: 8, color: slate)),
                      pw.Text('${ctx.profile.phone}  •  ${ctx.profile.email}', style: pw.TextStyle(fontSize: 8, color: slate)),
                    ],
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: darkNavy,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.white, letterSpacing: 1.5),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Invoice #: INV-${ctx.invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkNavy)),
                    pw.Text('Issue Date: ${DateFormat('dd MMM yyyy').format(ctx.invoice.issueDate)}', style: pw.TextStyle(fontSize: 8, color: slate)),
                    pw.Text('Due Date: ${DateFormat('dd MMM yyyy').format(ctx.invoice.dueDate)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: navyColor)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),
            pw.Divider(color: navyColor, thickness: 1.5),
            pw.SizedBox(height: ctx.sectionSpacing * 0.7),

            // ── Two Column Info Grid ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: lightNavyBg,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: pdf_lib.PdfColors.grey200, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILL TO / RECIPIENT', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: navyColor, letterSpacing: 0.5)),
                        pw.SizedBox(height: 3),
                        pw.Text(ctx.invoice.client.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkNavy)),
                        if (ctx.invoice.client.address.isNotEmpty)
                          pw.Text(ctx.invoice.client.address, style: pw.TextStyle(fontSize: 8, color: slate)),
                        if (ctx.invoice.client.email.isNotEmpty)
                          pw.Text(ctx.invoice.client.email, style: pw.TextStyle(fontSize: 8, color: slate)),
                        if (ctx.invoice.client.phone.isNotEmpty)
                          pw.Text(ctx.invoice.client.phone, style: pw.TextStyle(fontSize: 8, color: slate)),
                        if (ctx.invoice.client.gstNumber != null && ctx.invoice.client.gstNumber!.isNotEmpty)
                          pw.Text('Tax ID: ${ctx.invoice.client.gstNumber}', style: pw.TextStyle(fontSize: 8, color: slate)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: lightNavyBg,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: pdf_lib.PdfColors.grey200, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TERMS OF PAYMENT', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: navyColor, letterSpacing: 0.5)),
                        pw.SizedBox(height: 3),
                        pw.Text('Status: ${ctx.invoice.status.toUpperCase()}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkNavy)),
                        pw.Text('Due: ${DateFormat('dd MMMM yyyy').format(ctx.invoice.dueDate)}', style: pw.TextStyle(fontSize: 8, color: slate)),
                        pw.Text('Currency: ${ctx.profile.currency}', style: pw.TextStyle(fontSize: 8, color: slate)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Table with Deep Navy Header ──
            pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(26),
                1: pw.FlexColumnWidth(4.5),
                2: pw.FlexColumnWidth(1.2),
                3: pw.FlexColumnWidth(2.0),
                4: pw.FlexColumnWidth(2.2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: darkNavy),
                  children: [
                    _cell('#', align: pw.TextAlign.left, isHeader: true, vPad: ctx.rowVerticalPadding),
                    _cell('DESCRIPTION OF GOODS / SERVICES', align: pw.TextAlign.left, isHeader: true, vPad: ctx.rowVerticalPadding),
                    _cell('QTY', align: pw.TextAlign.center, isHeader: true, vPad: ctx.rowVerticalPadding),
                    _cell('UNIT RATE', align: pw.TextAlign.right, isHeader: true, vPad: ctx.rowVerticalPadding),
                    _cell('AMOUNT', align: pw.TextAlign.right, isHeader: true, vPad: ctx.rowVerticalPadding),
                  ],
                ),
                ...ctx.invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final isEven = entry.key % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? pdf_lib.PdfColors.white : lightNavyBg,
                      border: const pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey200, width: 0.5)),
                    ),
                    children: [
                      _cell('$idx', align: pw.TextAlign.left, color: slate, vPad: ctx.rowVerticalPadding),
                      _cell(item.name, align: pw.TextAlign.left, color: darkNavy, isBold: true, vPad: ctx.rowVerticalPadding),
                      _cell('${item.quantity}', align: pw.TextAlign.center, color: darkNavy, vPad: ctx.rowVerticalPadding),
                      _cell(ctx.currencyFormat.format(item.price), align: pw.TextAlign.right, color: darkNavy, vPad: ctx.rowVerticalPadding),
                      _cell(ctx.currencyFormat.format(item.total), align: pw.TextAlign.right, color: darkNavy, isBold: true, vPad: ctx.rowVerticalPadding),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Financial Summary ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 230,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: pdf_lib.PdfColors.grey300, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 4),
                        child: pw.Column(
                          children: [
                            _row('Subtotal:', ctx.formattedSubtotal, darkNavy, slate),
                            if (ctx.invoice.taxPercentage > 0)
                              _row('${ctx.taxLabel} (${ctx.invoice.taxPercentage.toStringAsFixed(0)}%):', ctx.formattedTax, darkNavy, slate),
                            if (ctx.invoice.discount > 0)
                              _row('Discount Savings:', '- ${ctx.formattedDiscount}', pdf_lib.PdfColor.fromHex('#16A34A'), slate),
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: pw.BoxDecoration(
                          color: darkNavy,
                          borderRadius: const pw.BorderRadius.vertical(bottom: pw.Radius.circular(3)),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL AMOUNT:', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.white)),
                            pw.Text(ctx.formattedTotal, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Bottom: Bank particulars, QR, Authorized Signature ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      PdfSharedComponents.buildBankDetailsWidget(ctx, labelColor: navyColor, valueColor: darkNavy),
                      if (ctx.hasBankDetails) pw.SizedBox(height: 8),
                      PdfSharedComponents.buildNotesWidget(ctx, labelColor: navyColor, bodyColor: darkNavy),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                if (ctx.config.showQrCode && ctx.hasUpiPayment)
                  PdfSharedComponents.buildUpiQrWidget(ctx, size: 54),
                pw.SizedBox(width: 16),
                if (ctx.config.showSignature)
                  PdfSharedComponents.buildSignatureWidget(ctx, textColor: darkNavy, lineColor: darkNavy),
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
