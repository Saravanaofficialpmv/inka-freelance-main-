import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'invoice_template.dart';

/// Template 07 — Retail / Shop Style
/// Product-oriented, compact itemized rows, tax breakdown matrix, and prominent counter payment QR code.
class RetailShopTemplate extends InvoiceTemplate {
  @override
  String get id => 'retail_shop';

  @override
  String get name => 'Retail / Shop Style';

  @override
  String get description => 'Compact product-dense billing format, ideal for stores, wholesale & retail shops';

  @override
  String get defaultAccentColorHex => '#EA580C';

  @override
  String get icon => '🛒';

  @override
  String get tag => 'Retail & Mart';

  @override
  String get assetPreview => 'assets/templates/template_compact.jpg';

  @override
  void buildPage(pw.Document pdf, TemplateRenderContext ctx) {
    final amberColor = pdf_lib.PdfColor.fromHex('#EA580C');
    final darkText = pdf_lib.PdfColor.fromHex('#1C1917');
    final slateText = pdf_lib.PdfColor.fromHex('#57534E');
    final tableHeaderBg = pdf_lib.PdfColor.fromHex('#FFF7ED');
    final borderColor = pdf_lib.PdfColor.fromHex('#FED7AA');

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
                border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 0.8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    ctx.profile.businessName.isNotEmpty ? ctx.profile.businessName : 'TAX INVOICE',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkText),
                  ),
                  pw.Text(
                    'Bill #${ctx.invoice.invoiceNumber}  •  Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 8, color: slateText),
                  ),
                ],
              ),
            );
          }
          return pw.SizedBox();
        },
        build: (pw.Context context) {
          return [
            // ── Store Header Banner ──
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: tableHeaderBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: amberColor, width: 1.0),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (ctx.config.showLogo && ctx.logoImage != null)
                          pw.Container(
                            height: 36,
                            margin: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Image(ctx.logoImage!),
                          )
                        else
                          pw.Text(
                            ctx.profile.businessName.isNotEmpty
                                ? ctx.profile.businessName.toUpperCase()
                                : 'RETAIL SUPERMARKET',
                            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: darkText, letterSpacing: 0.5),
                          ),
                        if (ctx.config.showContactDetails) ...[
                          if (ctx.profile.taxIdNumber != null && ctx.profile.taxIdNumber!.isNotEmpty)
                            pw.Text('${ctx.taxLabel}: ${ctx.profile.taxIdNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: amberColor))
                          else if (ctx.profile.gstNumber != null && ctx.profile.gstNumber!.isNotEmpty)
                            pw.Text('Tax ID: ${ctx.profile.gstNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: amberColor)),
                          if (ctx.profile.address.isNotEmpty)
                            pw.Text(ctx.profile.address, style: pw.TextStyle(fontSize: 8, color: slateText)),
                          pw.Text('Ph: ${ctx.profile.phone}  •  Email: ${ctx.profile.email}', style: pw.TextStyle(fontSize: 8, color: slateText)),
                        ],
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: amberColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.white)),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Bill No: #${ctx.invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkText)),
                      pw.Text('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(ctx.invoice.issueDate)}', style: pw.TextStyle(fontSize: 7.5, color: slateText)),
                      pw.Text('Due: ${DateFormat('dd MMM yyyy').format(ctx.invoice.dueDate)}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkText)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Customer Meta Bar ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CUSTOMER DETAILS', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: amberColor, letterSpacing: 0.5)),
                    pw.Text(ctx.invoice.client.name, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkText)),
                    if (ctx.invoice.client.phone.isNotEmpty)
                      pw.Text('Phone: ${ctx.invoice.client.phone}', style: pw.TextStyle(fontSize: 7.5, color: slateText)),
                    if (ctx.invoice.client.address.isNotEmpty)
                      pw.Text(ctx.invoice.client.address, style: pw.TextStyle(fontSize: 7.5, color: slateText)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('ITEMS BILLED: ${ctx.invoice.items.length}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkText)),
                    pw.Text('STATUS: ${ctx.invoice.status.toUpperCase()}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: amberColor)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── High-Density Item Table ──
            pw.Table(
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(color: borderColor, width: 0.6),
                bottom: pw.BorderSide(color: amberColor, width: 1.0),
              ),
              columnWidths: const {
                0: pw.FixedColumnWidth(24),
                1: pw.FlexColumnWidth(4.5),
                2: pw.FlexColumnWidth(1.2),
                3: pw.FlexColumnWidth(2.0),
                4: pw.FlexColumnWidth(2.2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: tableHeaderBg),
                  children: [
                    _cell('#', align: pw.TextAlign.left, isHeader: true, color: amberColor, vPad: ctx.rowVerticalPadding),
                    _cell('ITEM / PRODUCT', align: pw.TextAlign.left, isHeader: true, color: amberColor, vPad: ctx.rowVerticalPadding),
                    _cell('QTY', align: pw.TextAlign.center, isHeader: true, color: amberColor, vPad: ctx.rowVerticalPadding),
                    _cell('RATE', align: pw.TextAlign.right, isHeader: true, color: amberColor, vPad: ctx.rowVerticalPadding),
                    _cell('AMOUNT', align: pw.TextAlign.right, isHeader: true, color: amberColor, vPad: ctx.rowVerticalPadding),
                  ],
                ),
                ...ctx.invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _cell('$idx', align: pw.TextAlign.left, color: slateText, vPad: ctx.rowVerticalPadding),
                      _cell(item.name, align: pw.TextAlign.left, color: darkText, isBold: true, vPad: ctx.rowVerticalPadding),
                      _cell('${item.quantity}', align: pw.TextAlign.center, color: darkText, vPad: ctx.rowVerticalPadding),
                      _cell(ctx.currencyFormat.format(item.price), align: pw.TextAlign.right, color: darkText, vPad: ctx.rowVerticalPadding),
                      _cell(ctx.currencyFormat.format(item.total), align: pw.TextAlign.right, color: darkText, isBold: true, vPad: ctx.rowVerticalPadding),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Totals & Savings Summary ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 220,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: tableHeaderBg,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: borderColor, width: 0.8),
                  ),
                  child: pw.Column(
                    children: [
                      _row('Sub Total', ctx.formattedSubtotal, darkText, slateText),
                      if (ctx.invoice.taxPercentage > 0)
                        _row('${ctx.taxLabel} (${ctx.invoice.taxPercentage.toStringAsFixed(0)}%)', ctx.formattedTax, darkText, slateText),
                      if (ctx.invoice.discount > 0)
                        _row('Special Savings', '- ${ctx.formattedDiscount}', pdf_lib.PdfColor.fromHex('#16A34A'), slateText),
                      pw.Divider(color: amberColor, thickness: 1.0),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('FINAL PAYABLE:', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkText)),
                          pw.Text(ctx.formattedTotal, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: amberColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Bottom: Payment details, Counter QR, Signature ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      PdfSharedComponents.buildBankDetailsWidget(ctx, labelColor: amberColor, valueColor: darkText),
                      if (ctx.hasBankDetails) pw.SizedBox(height: 8),
                      PdfSharedComponents.buildNotesWidget(ctx, labelColor: amberColor, bodyColor: darkText),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                if (ctx.config.showQrCode && ctx.hasUpiPayment)
                  PdfSharedComponents.buildUpiQrWidget(ctx, size: 54),
                pw.SizedBox(width: 16),
                if (ctx.config.showSignature)
                  PdfSharedComponents.buildSignatureWidget(ctx, textColor: darkText, lineColor: amberColor),
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
