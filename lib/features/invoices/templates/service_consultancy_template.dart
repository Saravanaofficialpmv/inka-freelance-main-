import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'invoice_template.dart';

/// Template 08 — Service / Consultancy
/// Blue/cyan accented professional services format, generous service scope column, and formal engagement agreement layout.
class ServiceConsultancyTemplate extends InvoiceTemplate {
  @override
  String get id => 'service_consultancy';

  @override
  String get name => 'Service / Consultancy';

  @override
  String get description => 'Clean cyan & blue consulting invoice with generous description space for project milestones';

  @override
  String get defaultAccentColorHex => '#0284C7';

  @override
  String get icon => '💼';

  @override
  String get tag => 'Consulting & IT';

  @override
  String get assetPreview => 'assets/templates/template_service_2.jpg';

  @override
  void buildPage(pw.Document pdf, TemplateRenderContext ctx) {
    final cyanColor = pdf_lib.PdfColor.fromHex('#0284C7');
    final darkNavy = pdf_lib.PdfColor.fromHex('#0F172A');
    final slate = pdf_lib.PdfColor.fromHex('#475569');
    final cyanBg = pdf_lib.PdfColor.fromHex('#F0F9FF');
    final borderCyan = pdf_lib.PdfColor.fromHex('#BAE6FD');

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
                border: pw.Border(bottom: pw.BorderSide(color: borderCyan, width: 0.8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    ctx.profile.businessName.isNotEmpty ? ctx.profile.businessName : 'CONSULTING SERVICES',
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
            // ── Top Header Band ──
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
                        margin: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Image(ctx.logoImage!),
                      )
                    else
                      pw.Text(
                        ctx.profile.businessName.isNotEmpty ? ctx.profile.businessName : 'CONSULTING FIRM',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: darkNavy, letterSpacing: 0.5),
                      ),
                    if (ctx.config.showContactDetails) ...[
                      if (ctx.profile.taxIdNumber != null && ctx.profile.taxIdNumber!.isNotEmpty)
                        pw.Text('${ctx.taxLabel}: ${ctx.profile.taxIdNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: cyanColor))
                      else if (ctx.profile.gstNumber != null && ctx.profile.gstNumber!.isNotEmpty)
                        pw.Text('Tax ID: ${ctx.profile.gstNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: cyanColor)),
                      if (ctx.profile.address.isNotEmpty)
                        pw.Text(ctx.profile.address, style: pw.TextStyle(fontSize: 8, color: slate)),
                      pw.Text('${ctx.profile.phone}  •  ${ctx.profile.email}', style: pw.TextStyle(fontSize: 8, color: slate)),
                    ],
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'CONSULTING INVOICE',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: cyanColor, letterSpacing: 1.0),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Invoice Ref: INV-${ctx.invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkNavy)),
                    pw.Text('Billing Date: ${DateFormat('dd MMM yyyy').format(ctx.invoice.issueDate)}', style: pw.TextStyle(fontSize: 8, color: slate)),
                    pw.Text('Due Date: ${DateFormat('dd MMM yyyy').format(ctx.invoice.dueDate)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkNavy)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),
            pw.Divider(color: cyanColor, thickness: 1.2),
            pw.SizedBox(height: ctx.sectionSpacing * 0.7),

            // ── Client & Engagement Scope ──
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: cyanBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: borderCyan, width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CLIENT / ENGAGEMENT SPONSOR', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: cyanColor, letterSpacing: 0.5)),
                      pw.SizedBox(height: 3),
                      pw.Text(ctx.invoice.client.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkNavy)),
                      if (ctx.invoice.client.address.isNotEmpty)
                        pw.Text(ctx.invoice.client.address, style: pw.TextStyle(fontSize: 8, color: slate)),
                      if (ctx.invoice.client.email.isNotEmpty)
                        pw.Text(ctx.invoice.client.email, style: pw.TextStyle(fontSize: 8, color: slate)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('PAYMENT TERMS', style: pw.TextStyle(fontSize: 7, color: slate)),
                      pw.Text(ctx.invoice.status.toUpperCase(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: cyanColor)),
                      pw.Text('Currency: ${ctx.profile.currency}', style: pw.TextStyle(fontSize: 7.5, color: slate)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Services Table ──
            pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(24),
                1: pw.FlexColumnWidth(5.0),
                2: pw.FlexColumnWidth(1.2),
                3: pw.FlexColumnWidth(1.8),
                4: pw.FlexColumnWidth(2.0),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: cyanColor),
                  children: [
                    _cell('#', align: pw.TextAlign.left, isHeader: true, vPad: ctx.rowVerticalPadding),
                    _cell('SERVICE SCOPE & MILESTONES', align: pw.TextAlign.left, isHeader: true, vPad: ctx.rowVerticalPadding),
                    _cell('UNITS', align: pw.TextAlign.center, isHeader: true, vPad: ctx.rowVerticalPadding),
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
                  width: 220,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: cyanBg,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: borderCyan, width: 0.8),
                  ),
                  child: pw.Column(
                    children: [
                      _row('Consulting Subtotal', ctx.formattedSubtotal, darkNavy, slate),
                      if (ctx.invoice.taxPercentage > 0)
                        _row('${ctx.taxLabel} (${ctx.invoice.taxPercentage.toStringAsFixed(0)}%)', ctx.formattedTax, darkNavy, slate),
                      if (ctx.invoice.discount > 0)
                        _row('Negotiated Retainer Credit', '- ${ctx.formattedDiscount}', pdf_lib.PdfColor.fromHex('#10B981'), slate),
                      pw.Divider(color: cyanColor, thickness: 1.0),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Net Due Amount:', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkNavy)),
                          pw.Text(ctx.formattedTotal, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: cyanColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: ctx.sectionSpacing),

            // ── Bottom: Banking, Wire Remittance, QR, Authorized Sign ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      PdfSharedComponents.buildBankDetailsWidget(ctx, labelColor: cyanColor, valueColor: darkNavy),
                      if (ctx.hasBankDetails) pw.SizedBox(height: 8),
                      PdfSharedComponents.buildNotesWidget(ctx, labelColor: cyanColor, bodyColor: darkNavy),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                if (ctx.config.showQrCode && ctx.hasUpiPayment)
                  PdfSharedComponents.buildUpiQrWidget(ctx, size: 54),
                pw.SizedBox(width: 16),
                if (ctx.config.showSignature)
                  PdfSharedComponents.buildSignatureWidget(ctx, textColor: darkNavy, lineColor: cyanColor),
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
