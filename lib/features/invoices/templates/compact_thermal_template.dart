import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'invoice_template.dart';
import 'invoice_template_config.dart';

/// Template 09 — Compact / Thermal-Inspired
/// Visual direction: Compact, receipt-inspired, monochrome, dashed dividers.
/// Supports both standard A4 (neat centered slip) and 80mm roll format.
class CompactThermalTemplate implements InvoiceTemplate {
  @override
  String get id => 'compact_thermal';

  @override
  String get name => 'Compact / Thermal';

  @override
  String get description => 'Receipt-inspired compact layout with dashed dividing rules and high density.';

  @override
  String get defaultAccentColorHex => '#18181B';

  @override
  String get icon => '🧾';

  @override
  String get tag => 'Receipt / POS';

  @override
  String get assetPreview => 'assets/templates/template_compact.jpg';

  static const primaryBlack = pdf_lib.PdfColors.black;
  static const secondaryGrey = pdf_lib.PdfColors.grey800;

  @override
  void buildPage(pw.Document pdf, TemplateRenderContext ctx) {
    final isThermalRoll = ctx.config.pageFormat == InvoicePageFormatType.thermalRoll;

    final pageFormat = isThermalRoll
        ? const pdf_lib.PdfPageFormat(
            80 * pdf_lib.PdfPageFormat.mm,
            297 * pdf_lib.PdfPageFormat.mm,
            marginAll: 10,
          )
        : pdf_lib.PdfPageFormat.a4;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: isThermalRoll ? const pw.EdgeInsets.all(10) : ctx.pageMargins,
        build: (pw.Context context) {
          final hPad = isThermalRoll ? 0.0 : 80.0;

          return [
            // ── Receipt Header ──
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: hPad),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (ctx.config.showLogo && ctx.logoImage != null)
                    pw.Container(
                      height: 32,
                      margin: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Image(ctx.logoImage!),
                    ),
                  pw.Text(
                    ctx.profile.businessName.isNotEmpty ? ctx.profile.businessName.toUpperCase() : 'SALES RECEIPT',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryBlack),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (ctx.config.showContactDetails) ...[
                    if (ctx.profile.taxIdNumber != null && ctx.profile.taxIdNumber!.isNotEmpty)
                      pw.Text('${ctx.taxLabel}: ${ctx.profile.taxIdNumber}', style: const pw.TextStyle(fontSize: 7.5, color: secondaryGrey))
                    else if (ctx.profile.gstNumber != null && ctx.profile.gstNumber!.isNotEmpty)
                      pw.Text('Tax ID: ${ctx.profile.gstNumber}', style: const pw.TextStyle(fontSize: 7.5, color: secondaryGrey)),
                    if (ctx.profile.address.isNotEmpty)
                      pw.Text(ctx.profile.address, style: const pw.TextStyle(fontSize: 7.5, color: secondaryGrey), textAlign: pw.TextAlign.center),
                    pw.Text('Tel: ${ctx.profile.phone}', style: const pw.TextStyle(fontSize: 7.5, color: secondaryGrey)),
                  ],

                  pw.SizedBox(height: 6),
                  _dashedLine(),
                  pw.SizedBox(height: 4),

                  // ── Receipt Meta ──
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('RECEIPT: #${ctx.invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryBlack)),
                      pw.Text(DateFormat('dd/MM/yy HH:mm').format(ctx.invoice.issueDate), style: const pw.TextStyle(fontSize: 7.5, color: secondaryGrey)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('CUSTOMER: ${ctx.invoice.client.name}', style: const pw.TextStyle(fontSize: 7.5, color: secondaryGrey)),
                      pw.Text('STATUS: ${ctx.invoice.status.toUpperCase()}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryBlack)),
                    ],
                  ),

                  pw.SizedBox(height: 4),
                  _dashedLine(),
                  pw.SizedBox(height: 4),
                ],
              ),
            ),

            // ── Flowable Items Table ──
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: hPad),
              child: pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(5.0),
                  1: pw.FlexColumnWidth(1.2),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(2.0),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _th('ITEM'),
                      _th('QTY', align: pw.TextAlign.center),
                      _th('PRICE', align: pw.TextAlign.right),
                      _th('TOTAL', align: pw.TextAlign.right),
                    ],
                  ),
                  ...ctx.invoice.items.map((item) {
                    final itemTotal = item.quantity * item.price;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Text(
                            item.name,
                            style: pw.TextStyle(fontSize: 8, color: primaryBlack, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Text(
                            '${item.quantity}',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 7.5, color: secondaryGrey),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Text(
                            ctx.currencyFormat.format(item.price),
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 7.5, color: secondaryGrey),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Text(
                            ctx.currencyFormat.format(itemTotal),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryBlack),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            // ── Totals & Footer Section ──
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: hPad),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 4),
                  _dashedLine(),
                  pw.SizedBox(height: 4),

                  // ── Subtotal / Tax / Discount ──
                  _summaryRow('SUBTOTAL', ctx.formattedSubtotal),
                  if (ctx.invoice.taxPercentage > 0)
                    _summaryRow(
                      '${ctx.taxLabel} (${ctx.invoice.taxPercentage.toStringAsFixed(0)}%)',
                      ctx.formattedTax,
                    ),
                  if (ctx.invoice.discount > 0)
                    _summaryRow('DISCOUNT', '-${ctx.formattedDiscount}'),

                  pw.SizedBox(height: 3),
                  _dashedLine(),
                  pw.SizedBox(height: 4),

                  // ── Final Total ──
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL DUE:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryBlack)),
                      pw.Text(ctx.formattedTotal, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryBlack)),
                    ],
                  ),

                  pw.SizedBox(height: 6),
                  _dashedLine(),
                  pw.SizedBox(height: 8),

                  // ── QR Code & Footer ──
                  if (ctx.config.showQrCode && ctx.hasUpiPayment) ...[
                    pw.Center(
                      child: PdfSharedComponents.buildUpiQrWidget(ctx, size: 52),
                    ),
                    pw.SizedBox(height: 6),
                  ],

                  if (ctx.config.showBankDetails && ctx.hasBankDetails) ...[
                    PdfSharedComponents.buildBankDetailsWidget(ctx, labelColor: secondaryGrey, valueColor: primaryBlack),
                    pw.SizedBox(height: 6),
                  ],

                  pw.Center(
                    child: pw.Text(
                      '*** THANK YOU FOR VISITING! ***',
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryBlack),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }

  static pw.Widget _dashedLine() {
    return pw.Text(
      '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
      style: const pw.TextStyle(fontSize: 6, color: pdf_lib.PdfColors.grey500),
      maxLines: 1,
      overflow: pw.TextOverflow.clip,
    );
  }

  static pw.Widget _th(String title, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Text(
        title,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: primaryBlack,
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: secondaryGrey)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryBlack)),
        ],
      ),
    );
  }
}
