import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'invoice_template.dart';

/// Template 01 — Minimal Clean
/// Minimal, white, clean, professional. Restrained typography and thin light-grey borders.
class MinimalCleanTemplate extends InvoiceTemplate {
  @override
  String get id => 'minimal_clean';

  @override
  String get name => 'Minimal Clean';

  @override
  String get description => 'Pure white minimalist design with subtle borders and clear typography';

  @override
  String get defaultAccentColorHex => '#111827';

  @override
  String get icon => '📄';

  @override
  String get tag => 'Default / Minimal';

  @override
  String get assetPreview => 'assets/templates/template_elegant.jpg';

  @override
  void buildPage(pw.Document pdf, TemplateRenderContext ctx) {
    final textColor = pdf_lib.PdfColor.fromHex('#111827');
    final secondaryText = pdf_lib.PdfColor.fromHex('#6B7280');
    final borderColor = pdf_lib.PdfColor.fromHex('#E5E7EB');
    final headerBg = pdf_lib.PdfColor.fromHex('#F9FAFB');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: ctx.pageMargins,
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 8),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 0.8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    ctx.profile.businessName.isNotEmpty ? ctx.profile.businessName : 'INVOICE',
                    style: pw.TextStyle(fontSize: 8.5, color: secondaryText),
                  ),
                  pw.Text(
                    'Invoice #${ctx.invoice.invoiceNumber}  •  Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 8.5, color: secondaryText),
                  ),
                ],
              ),
            );
          }
          return pw.SizedBox();
        },
        build: (pw.Context context) {
          return [
            // ── Top Header: Logo / Business Name & INVOICE Heading ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (ctx.config.showLogo && ctx.logoImage != null)
                      pw.Container(
                        height: 38,
                        margin: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Image(ctx.logoImage!, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.Text(
                        ctx.profile.businessName.isNotEmpty ? ctx.profile.businessName : 'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: textColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    if (ctx.config.showContactDetails) ...[
                      if (ctx.profile.taxIdNumber != null && ctx.profile.taxIdNumber!.isNotEmpty)
                        pw.Text(
                          '${ctx.taxLabel}: ${ctx.profile.taxIdNumber}',
                          style: pw.TextStyle(fontSize: 8, color: secondaryText),
                        )
                      else if (ctx.profile.gstNumber != null && ctx.profile.gstNumber!.isNotEmpty)
                        pw.Text(
                          'Tax ID: ${ctx.profile.gstNumber}',
                          style: pw.TextStyle(fontSize: 8, color: secondaryText),
                        ),
                      if (ctx.profile.address.isNotEmpty)
                        pw.Text(ctx.profile.address, style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                      if (ctx.profile.phone.isNotEmpty || ctx.profile.email.isNotEmpty)
                        pw.Text(
                          '${ctx.profile.phone}${ctx.profile.phone.isNotEmpty && ctx.profile.email.isNotEmpty ? " • " : ""}${ctx.profile.email}',
                          style: pw.TextStyle(fontSize: 8, color: secondaryText),
                        ),
                    ],
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: textColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '#${ctx.invoice.invoiceNumber}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('Date: ', style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                        pw.Text(DateFormat('dd MMM yyyy').format(ctx.invoice.issueDate), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textColor)),
                      ],
                    ),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('Due: ', style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                        pw.Text(DateFormat('dd MMM yyyy').format(ctx.invoice.dueDate), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textColor)),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),
            pw.Divider(color: borderColor, thickness: 0.8),
            pw.SizedBox(height: ctx.sectionSpacing * 0.7),

            // ── Sender & Recipient Information ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILLED TO',
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: secondaryText, letterSpacing: 0.5),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        ctx.invoice.client.name.isNotEmpty ? ctx.invoice.client.name : 'Valued Client',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textColor),
                      ),
                      if (ctx.invoice.client.address.isNotEmpty)
                        pw.Text(ctx.invoice.client.address, style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                      if (ctx.invoice.client.email.isNotEmpty)
                        pw.Text(ctx.invoice.client.email, style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                      if (ctx.invoice.client.phone.isNotEmpty)
                        pw.Text(ctx.invoice.client.phone, style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                      if (ctx.invoice.client.gstNumber != null && ctx.invoice.client.gstNumber!.isNotEmpty)
                        pw.Text('Tax ID: ${ctx.invoice.client.gstNumber}', style: pw.TextStyle(fontSize: 8, color: secondaryText)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PAYMENT STATUS',
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: secondaryText, letterSpacing: 0.5),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: pw.BoxDecoration(
                          color: headerBg,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: borderColor, width: 0.8),
                        ),
                        child: pw.Text(
                          ctx.invoice.status.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: ctx.invoice.status.toLowerCase() == 'paid'
                                ? pdf_lib.PdfColor.fromHex('#16A34A')
                                : (ctx.invoice.status.toLowerCase() == 'overdue'
                                    ? pdf_lib.PdfColor.fromHex('#DC2626')
                                    : textColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Item Table with Thin Borders ──
            pw.Table(
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(color: borderColor, width: 0.6),
                bottom: pw.BorderSide(color: borderColor, width: 0.8),
              ),
              columnWidths: const {
                0: pw.FixedColumnWidth(24),
                1: pw.FlexColumnWidth(4.5),
                2: pw.FlexColumnWidth(1.2),
                3: pw.FlexColumnWidth(1.8),
                4: pw.FlexColumnWidth(2.0),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: headerBg),
                  children: [
                    _cell('#', align: pw.TextAlign.left, isHeader: true, color: secondaryText, vPad: ctx.rowVerticalPadding),
                    _cell('DESCRIPTION', align: pw.TextAlign.left, isHeader: true, color: secondaryText, vPad: ctx.rowVerticalPadding),
                    _cell('QTY', align: pw.TextAlign.center, isHeader: true, color: secondaryText, vPad: ctx.rowVerticalPadding),
                    _cell('UNIT PRICE', align: pw.TextAlign.right, isHeader: true, color: secondaryText, vPad: ctx.rowVerticalPadding),
                    _cell('AMOUNT', align: pw.TextAlign.right, isHeader: true, color: secondaryText, vPad: ctx.rowVerticalPadding),
                  ],
                ),
                // Rows
                ...ctx.invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _cell('$idx', align: pw.TextAlign.left, color: secondaryText, vPad: ctx.rowVerticalPadding),
                      _cell(item.name, align: pw.TextAlign.left, color: textColor, isBold: true, vPad: ctx.rowVerticalPadding),
                      _cell('${item.quantity}', align: pw.TextAlign.center, color: textColor, vPad: ctx.rowVerticalPadding),
                      _cell(ctx.currencyFormat.format(item.price), align: pw.TextAlign.right, color: textColor, vPad: ctx.rowVerticalPadding),
                      _cell(ctx.currencyFormat.format(item.total), align: pw.TextAlign.right, color: textColor, isBold: true, vPad: ctx.rowVerticalPadding),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Financial Totals (Right Aligned) ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 210,
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal', ctx.formattedSubtotal, textColor, secondaryText),
                      if (ctx.invoice.taxPercentage > 0)
                        _summaryRow('${ctx.taxLabel} (${ctx.invoice.taxPercentage.toStringAsFixed(0)}%)', ctx.formattedTax, textColor, secondaryText),
                      if (ctx.invoice.discount > 0)
                        _summaryRow('Discount', '- ${ctx.formattedDiscount}', pdf_lib.PdfColor.fromHex('#16A34A'), secondaryText),
                      pw.SizedBox(height: 4),
                      pw.Divider(color: borderColor, thickness: 1.0),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Grand Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textColor)),
                          pw.Text(ctx.formattedTotal, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Bottom Section: Payment Details, QR Code, Notes, Signature ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      PdfSharedComponents.buildBankDetailsWidget(
                        ctx,
                        labelColor: secondaryText,
                        valueColor: textColor,
                      ),
                      if (ctx.hasBankDetails) pw.SizedBox(height: 8),
                      PdfSharedComponents.buildNotesWidget(
                        ctx,
                        labelColor: secondaryText,
                        bodyColor: textColor,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                if (ctx.config.showQrCode && ctx.hasUpiPayment)
                  PdfSharedComponents.buildUpiQrWidget(ctx, size: 54),
                pw.SizedBox(width: 16),
                if (ctx.config.showSignature)
                  PdfSharedComponents.buildSignatureWidget(
                    ctx,
                    textColor: secondaryText,
                    lineColor: borderColor,
                  ),
              ],
            ),

            pw.SizedBox(height: 14),
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(fontSize: 7.5, color: secondaryText, fontStyle: pw.FontStyle.italic),
              ),
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
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, pdf_lib.PdfColor valColor, pdf_lib.PdfColor lblColor) {
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
