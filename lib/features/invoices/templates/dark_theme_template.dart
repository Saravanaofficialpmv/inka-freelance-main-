import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'invoice_template.dart';

/// Template 06 — Dark Theme
/// Genuinely dark background (#14161D), high-contrast white typography, vibrant orange accents,
/// and scannable white-backed QR code.
class DarkThemeTemplate extends InvoiceTemplate {
  @override
  String get id => 'dark_theme';

  @override
  String get name => 'Dark Theme';

  @override
  String get description => 'Deep charcoal canvas with high-contrast typography and neon orange accents';

  @override
  String get defaultAccentColorHex => '#FF533D';

  @override
  String get icon => '🌙';

  @override
  String get tag => 'Dark Mode / OLED';

  @override
  String get assetPreview => 'assets/templates/template_genz.jpg';

  @override
  void buildPage(pw.Document pdf, TemplateRenderContext ctx) {
    final bgDark = pdf_lib.PdfColor.fromHex('#14161D');
    final cardDark = pdf_lib.PdfColor.fromHex('#1E222D');
    final rowDarkEven = pdf_lib.PdfColor.fromHex('#181B24');
    final orangeAccent = ctx.accentColor;
    final textWhite = pdf_lib.PdfColors.white;
    final textMuted = pdf_lib.PdfColor.fromHex('#94A3B8');
    final borderDark = pdf_lib.PdfColor.fromHex('#2E3545');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pdf_lib.PdfPageFormat.a4,
          margin: ctx.pageMargins,
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: bgDark),
          ),
        ),
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 6),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: borderDark, width: 0.8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    ctx.profile.businessName.isNotEmpty ? ctx.profile.businessName : 'INVOICE',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textWhite),
                  ),
                  pw.Text(
                    '#${ctx.invoice.invoiceNumber}  •  Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 8, color: textMuted),
                  ),
                ],
              ),
            );
          }
          return pw.SizedBox();
        },
        build: (pw.Context context) {
          return [
                  // ── Top Header Row ──
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
                              ctx.profile.businessName.isNotEmpty
                                  ? ctx.profile.businessName.toUpperCase()
                                  : 'INKA DARK',
                              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: textWhite, letterSpacing: 0.5),
                            ),
                          if (ctx.config.showContactDetails) ...[
                            if (ctx.profile.taxIdNumber != null && ctx.profile.taxIdNumber!.isNotEmpty)
                              pw.Text('${ctx.taxLabel}: ${ctx.profile.taxIdNumber}', style: pw.TextStyle(fontSize: 8, color: orangeAccent, fontWeight: pw.FontWeight.bold))
                            else if (ctx.profile.gstNumber != null && ctx.profile.gstNumber!.isNotEmpty)
                              pw.Text('Tax ID: ${ctx.profile.gstNumber}', style: pw.TextStyle(fontSize: 8, color: orangeAccent, fontWeight: pw.FontWeight.bold)),
                            if (ctx.profile.address.isNotEmpty)
                              pw.Text(ctx.profile.address, style: pw.TextStyle(fontSize: 8, color: textMuted)),
                            pw.Text('${ctx.profile.phone}  •  ${ctx.profile.email}', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                          ],
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'INVOICE',
                            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: orangeAccent, letterSpacing: 1.5),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text('#${ctx.invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textWhite)),
                          pw.Text('Date: ${DateFormat('dd MMM yyyy').format(ctx.invoice.issueDate)}', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                          pw.Text('Due: ${DateFormat('dd MMM yyyy').format(ctx.invoice.dueDate)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textWhite)),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: ctx.sectionSpacing),

                  // ── Client Information Card ──
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: cardDark,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: borderDark, width: 0.8),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('BILLED TO', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: orangeAccent, letterSpacing: 0.5)),
                            pw.SizedBox(height: 3),
                            pw.Text(ctx.invoice.client.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textWhite)),
                            if (ctx.invoice.client.address.isNotEmpty)
                              pw.Text(ctx.invoice.client.address, style: pw.TextStyle(fontSize: 8, color: textMuted)),
                            if (ctx.invoice.client.email.isNotEmpty)
                              pw.Text(ctx.invoice.client.email, style: pw.TextStyle(fontSize: 8, color: textMuted)),
                          ],
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: bgDark,
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: orangeAccent, width: 0.8),
                          ),
                          child: pw.Text(
                            ctx.invoice.status.toUpperCase(),
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: orangeAccent),
                          ),
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
                          color: cardDark,
                          borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
                        ),
                        children: [
                          _cell('#', align: pw.TextAlign.left, isHeader: true, color: orangeAccent, vPad: ctx.rowVerticalPadding),
                          _cell('DESCRIPTION', align: pw.TextAlign.left, isHeader: true, color: orangeAccent, vPad: ctx.rowVerticalPadding),
                          _cell('QTY', align: pw.TextAlign.center, isHeader: true, color: orangeAccent, vPad: ctx.rowVerticalPadding),
                          _cell('RATE', align: pw.TextAlign.right, isHeader: true, color: orangeAccent, vPad: ctx.rowVerticalPadding),
                          _cell('AMOUNT', align: pw.TextAlign.right, isHeader: true, color: orangeAccent, vPad: ctx.rowVerticalPadding),
                        ],
                      ),
                      ...ctx.invoice.items.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final item = entry.value;
                        final isEven = entry.key % 2 == 0;
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: isEven ? bgDark : rowDarkEven,
                            border: pw.Border(bottom: pw.BorderSide(color: borderDark, width: 0.6)),
                          ),
                          children: [
                            _cell('$idx', align: pw.TextAlign.left, color: textMuted, vPad: ctx.rowVerticalPadding),
                            _cell(item.name, align: pw.TextAlign.left, color: textWhite, isBold: true, vPad: ctx.rowVerticalPadding),
                            _cell('${item.quantity}', align: pw.TextAlign.center, color: textWhite, vPad: ctx.rowVerticalPadding),
                            _cell(ctx.currencyFormat.format(item.price), align: pw.TextAlign.right, color: textWhite, vPad: ctx.rowVerticalPadding),
                            _cell(ctx.currencyFormat.format(item.total), align: pw.TextAlign.right, color: textWhite, isBold: true, vPad: ctx.rowVerticalPadding),
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
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: cardDark,
                          borderRadius: pw.BorderRadius.circular(8),
                          border: pw.Border.all(color: borderDark, width: 0.8),
                        ),
                        child: pw.Column(
                          children: [
                            _row('Subtotal', ctx.formattedSubtotal, textWhite, textMuted),
                            if (ctx.invoice.taxPercentage > 0)
                              _row('${ctx.taxLabel} (${ctx.invoice.taxPercentage.toStringAsFixed(0)}%)', ctx.formattedTax, textWhite, textMuted),
                            if (ctx.invoice.discount > 0)
                              _row('Discount', '- ${ctx.formattedDiscount}', pdf_lib.PdfColor.fromHex('#10B981'), textMuted),
                            pw.Divider(color: orangeAccent, thickness: 1.0),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Net Payable:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textWhite)),
                                pw.Text(ctx.formattedTotal, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: orangeAccent)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: ctx.sectionSpacing),

                  // ── Bottom: Bank details, Scannable QR on White Backing, Notes, Signature ──
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            PdfSharedComponents.buildBankDetailsWidget(ctx, labelColor: orangeAccent, valueColor: textWhite),
                            if (ctx.hasBankDetails) pw.SizedBox(height: 8),
                            PdfSharedComponents.buildNotesWidget(ctx, labelColor: orangeAccent, bodyColor: textMuted),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      if (ctx.config.showQrCode && ctx.hasUpiPayment)
                        PdfSharedComponents.buildUpiQrWidget(ctx, size: 54, darkBackground: true),
                      pw.SizedBox(width: 16),
                      if (ctx.config.showSignature)
                        PdfSharedComponents.buildSignatureWidget(ctx, textColor: textWhite, lineColor: orangeAccent),
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
          color: color ?? pdf_lib.PdfColors.white,
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
