import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'invoice_template.dart';

/// Template 05 — Professional Classic
/// Warm ivory tinted background, distinguished double borders, traditional ledger styling, and grayscale print-ready.
class ProfessionalClassicTemplate extends InvoiceTemplate {
  @override
  String get id => 'professional_classic';

  @override
  String get name => 'Professional Classic';

  @override
  String get description => 'Warm ivory document, distinguished ledger layout, and formal business styling';

  @override
  String get defaultAccentColorHex => '#334155';

  @override
  String get icon => '📜';

  @override
  String get tag => 'Traditional / Formal';

  @override
  String get assetPreview => 'assets/templates/template_professional.jpg';

  @override
  void buildPage(pw.Document pdf, TemplateRenderContext ctx) {
    final ivoryBg = pdf_lib.PdfColor.fromHex('#FBFBF6');
    final darkCharcoal = pdf_lib.PdfColor.fromHex('#1E293B');
    final formalBorder = pdf_lib.PdfColor.fromHex('#CBD5E1');
    final secondaryText = pdf_lib.PdfColor.fromHex('#64748B');

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
                border: pw.Border(bottom: pw.BorderSide(color: formalBorder, width: 1.0)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    ctx.profile.businessName.isNotEmpty ? ctx.profile.businessName : 'TAX INVOICE',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkCharcoal),
                  ),
                  pw.Text(
                    'Invoice #${ctx.invoice.invoiceNumber}  •  Page ${context.pageNumber} of ${context.pagesCount}',
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
            // ── Outer Decorative Border Box ──
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: ivoryBg,
                border: pw.Border.all(color: darkCharcoal, width: 1.2),
              ),
              child: pw.Column(
                children: [
                  // Formal Business Header & Title
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (ctx.config.showLogo && ctx.logoImage != null)
                            pw.Container(
                              height: 38,
                              margin: const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Image(ctx.logoImage!),
                            )
                          else
                            pw.Text(
                              ctx.profile.businessName.isNotEmpty
                                  ? ctx.profile.businessName.toUpperCase()
                                  : 'ESTABLISHED TRADERS',
                              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: darkCharcoal, letterSpacing: 1.0),
                            ),
                          if (ctx.config.showContactDetails) ...[
                            if (ctx.profile.taxIdNumber != null && ctx.profile.taxIdNumber!.isNotEmpty)
                              pw.Text('${ctx.taxLabel}: ${ctx.profile.taxIdNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkCharcoal))
                            else if (ctx.profile.gstNumber != null && ctx.profile.gstNumber!.isNotEmpty)
                              pw.Text('Tax ID: ${ctx.profile.gstNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkCharcoal)),
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
                            'COMMERCIAL INVOICE',
                            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: darkCharcoal, letterSpacing: 1.2),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('Invoice No: ${ctx.invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkCharcoal)),
                          pw.Text('Date of Issue: ${DateFormat('dd/MM/yyyy').format(ctx.invoice.issueDate)}', style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                          pw.Text('Due Date: ${DateFormat('dd/MM/yyyy').format(ctx.invoice.dueDate)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkCharcoal)),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 8),
                  pw.Divider(color: darkCharcoal, thickness: 1.0),
                  pw.SizedBox(height: 6),

                  // Billed To & Logistics Info
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('BUYER / BILLED TO:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkCharcoal)),
                            pw.SizedBox(height: 2),
                            pw.Text(ctx.invoice.client.name, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkCharcoal)),
                            if (ctx.invoice.client.address.isNotEmpty)
                              pw.Text(ctx.invoice.client.address, style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                            if (ctx.invoice.client.email.isNotEmpty)
                              pw.Text(ctx.invoice.client.email, style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                            if (ctx.invoice.client.phone.isNotEmpty)
                              pw.Text(ctx.invoice.client.phone, style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: darkCharcoal, width: 0.8),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('PAYMENT TERMS: DUE ON RECEIPT', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: darkCharcoal)),
                            pw.Text('STATUS: ${ctx.invoice.status.toUpperCase()}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkCharcoal)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Formal Ledger Item Table ──
            pw.Table(
              border: pw.TableBorder.all(color: darkCharcoal, width: 0.8),
              columnWidths: const {
                0: pw.FixedColumnWidth(26),
                1: pw.FlexColumnWidth(4.5),
                2: pw.FlexColumnWidth(1.2),
                3: pw.FlexColumnWidth(2.0),
                4: pw.FlexColumnWidth(2.2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: pdf_lib.PdfColor.fromHex('#E2E8F0')),
                  children: [
                    _cell('S.No', align: pw.TextAlign.center, isHeader: true, vPad: ctx.rowVerticalPadding),
                    _cell('Particulars / Description', align: pw.TextAlign.left, isHeader: true, vPad: ctx.rowVerticalPadding),
                    _cell('Qty', align: pw.TextAlign.center, isHeader: true, vPad: ctx.rowVerticalPadding),
                    _cell('Rate', align: pw.TextAlign.right, isHeader: true, vPad: ctx.rowVerticalPadding),
                    _cell('Amount', align: pw.TextAlign.right, isHeader: true, vPad: ctx.rowVerticalPadding),
                  ],
                ),
                ...ctx.invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _cell('$idx', align: pw.TextAlign.center, color: secondaryText, vPad: ctx.rowVerticalPadding),
                      _cell(item.name, align: pw.TextAlign.left, color: darkCharcoal, isBold: true, vPad: ctx.rowVerticalPadding),
                      _cell('${item.quantity}', align: pw.TextAlign.center, color: darkCharcoal, vPad: ctx.rowVerticalPadding),
                      _cell(ctx.currencyFormat.format(item.price), align: pw.TextAlign.right, color: darkCharcoal, vPad: ctx.rowVerticalPadding),
                      _cell(ctx.currencyFormat.format(item.total), align: pw.TextAlign.right, color: darkCharcoal, isBold: true, vPad: ctx.rowVerticalPadding),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Totals Grid ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 230,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: darkCharcoal, width: 0.8),
                  ),
                  child: pw.Column(
                    children: [
                      _row('Subtotal', ctx.formattedSubtotal, darkCharcoal, secondaryText),
                      if (ctx.invoice.taxPercentage > 0)
                        _row('${ctx.taxLabel} (${ctx.invoice.taxPercentage.toStringAsFixed(0)}%)', ctx.formattedTax, darkCharcoal, secondaryText),
                      if (ctx.invoice.discount > 0)
                        _row('Less: Discount', '- ${ctx.formattedDiscount}', pdf_lib.PdfColor.fromHex('#16A34A'), secondaryText),
                      pw.Container(
                        color: darkCharcoal,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL PAYABLE:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.white)),
                            pw.Text(ctx.formattedTotal, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Bottom: Banking, QR, Terms, Stamp ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      PdfSharedComponents.buildBankDetailsWidget(ctx, labelColor: darkCharcoal, valueColor: darkCharcoal),
                      if (ctx.hasBankDetails) pw.SizedBox(height: 8),
                      PdfSharedComponents.buildNotesWidget(ctx, labelColor: darkCharcoal, bodyColor: secondaryText),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                if (ctx.config.showQrCode && ctx.hasUpiPayment)
                  PdfSharedComponents.buildUpiQrWidget(ctx, size: 54),
                pw.SizedBox(width: 16),
                if (ctx.config.showSignature)
                  PdfSharedComponents.buildSignatureWidget(ctx, textColor: darkCharcoal, lineColor: darkCharcoal),
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
          color: color ?? pdf_lib.PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _row(String label, String value, pdf_lib.PdfColor valColor, pdf_lib.PdfColor lblColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: lblColor)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: valColor)),
        ],
      ),
    );
  }
}
