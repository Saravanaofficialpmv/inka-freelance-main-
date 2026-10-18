import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/invoice.dart';
import '../data/models/business_profile.dart';
import 'package:intl/intl.dart';
import 'currency_tax_service.dart';
import 'payment_qr_service.dart';

class PdfTemplateOption {
  final String id;
  final String name;
  final String subtitle;
  final String tag;
  final String primaryColorHex;
  final String icon;
  final String assetPreview;

  const PdfTemplateOption({
    required this.id,
    required this.name,
    required this.subtitle,
    this.tag = 'Standard',
    required this.primaryColorHex,
    required this.icon,
    required this.assetPreview,
  });
}

class PdfService {
  static const List<PdfTemplateOption> availableTemplates = [
    PdfTemplateOption(
      id: 'modern',
      name: 'Modern',
      subtitle: 'Clean itemized bill with modern accents',
      tag: 'Popular',
      primaryColorHex: '#FF9900',
      icon: '📦',
      assetPreview: 'assets/templates/template_modern.jpg',
    ),
    PdfTemplateOption(
      id: 'professional',
      name: 'Professional',
      subtitle: '3-column corporate format with official seal',
      tag: 'B2B Standard',
      primaryColorHex: '#0284C7',
      icon: '🏢',
      assetPreview: 'assets/templates/template_professional.jpg',
    ),
    PdfTemplateOption(
      id: 'billto_shipto',
      name: 'Bill To - Ship To',
      subtitle: 'Dual logistics & dispatch address layout',
      tag: 'Logistics / E-Com',
      primaryColorHex: '#2563EB',
      icon: '🚚',
      assetPreview: 'assets/templates/template_billto_shipto.jpg',
    ),
    PdfTemplateOption(
      id: 'legend',
      name: 'Legend',
      subtitle: 'e-Invoice layout with IRN QR & tax matrix',
      tag: 'e-Invoice & IRN',
      primaryColorHex: '#0F172A',
      icon: '📑',
      assetPreview: 'assets/templates/template_legend.jpg',
    ),
    PdfTemplateOption(
      id: 'service_2',
      name: 'Service Template 2',
      subtitle: 'IT corporate services & consulting contracts',
      tag: 'IT & Consulting',
      primaryColorHex: '#0D9488',
      icon: '💼',
      assetPreview: 'assets/templates/template_service_2.jpg',
    ),
    PdfTemplateOption(
      id: 'compact',
      name: 'Compact',
      subtitle: 'High-density retail & grocery bill layout',
      tag: 'Retail / Mart',
      primaryColorHex: '#DC2626',
      icon: '🛒',
      assetPreview: 'assets/templates/template_compact.jpg',
    ),
    PdfTemplateOption(
      id: 'evergreen',
      name: 'Evergreen',
      subtitle: 'Traditional bordered box with GST breakdown',
      tag: 'FMCG / Trade',
      primaryColorHex: '#16A34A',
      icon: '🌿',
      assetPreview: 'assets/templates/template_evergreen.jpg',
    ),
    PdfTemplateOption(
      id: 'classic',
      name: 'Classic',
      subtitle: 'Traditional deep navy header with clean grid',
      tag: 'Classic Corporate',
      primaryColorHex: '#1E3A8A',
      icon: '🏛️',
      assetPreview: 'assets/templates/template_classic.jpg',
    ),
    PdfTemplateOption(
      id: 'elegant_images',
      name: 'Elegant with Images',
      subtitle: 'Visual catalog invoice with item photos',
      tag: 'Product Catalog',
      primaryColorHex: '#18181B',
      icon: '📸',
      assetPreview: 'assets/templates/template_elegant_images.jpg',
    ),
    PdfTemplateOption(
      id: 'service',
      name: 'Service Template',
      subtitle: 'Creative freelance & marketing invoice',
      tag: 'Creative & Agency',
      primaryColorHex: '#D946EF',
      icon: '✨',
      assetPreview: 'assets/templates/template_service.jpg',
    ),
    PdfTemplateOption(
      id: 'vintage',
      name: 'Vintage',
      subtitle: 'Industrial boxed layout for automotive & manufacturing',
      tag: 'Manufacturing',
      primaryColorHex: '#1E40AF',
      icon: '⚙️',
      assetPreview: 'assets/templates/template_vintage.jpg',
    ),
    PdfTemplateOption(
      id: 'elegant',
      name: 'Elegant',
      subtitle: 'Minimalist luxury monochrome layout',
      tag: 'Luxury Minimal',
      primaryColorHex: '#111827',
      icon: '✒️',
      assetPreview: 'assets/templates/template_elegant.jpg',
    ),
    PdfTemplateOption(
      id: 'mrp_discount',
      name: 'MRP + Discount',
      subtitle: 'Supermarket bill showing MRP, price & savings',
      tag: 'Supermarket',
      primaryColorHex: '#059669',
      icon: '🏷️',
      assetPreview: 'assets/templates/template_mrp_discount.jpg',
    ),
    PdfTemplateOption(
      id: 'genz',
      name: 'GenZ',
      subtitle: 'Vibrant royal blue tech banner layout',
      tag: 'Modern Tech',
      primaryColorHex: '#2563EB',
      icon: '⚡',
      assetPreview: 'assets/templates/template_genz.jpg',
    ),
  ];

  static Future<Uint8List> generateInvoicePdf(
    Invoice invoice,
    BusinessProfile profile, {
    String? templateId,
  }) async {
    pw.Font? regularFont;
    pw.Font? boldFont;
    try {
      final regData = await rootBundle.load('assets/fonts/Inter/Inter-Regular.ttf');
      regularFont = pw.Font.ttf(regData);
      final boldData = await rootBundle.load('assets/fonts/Inter/Inter-Bold.ttf');
      boldFont = pw.Font.ttf(boldData);
    } catch (e) {
      debugPrint('Font load fallback: $e');
    }

    final pdf = pw.Document(
      theme: regularFont != null && boldFont != null
          ? pw.ThemeData.withFont(
              base: regularFont,
              bold: boldFont,
            )
          : null,
    );
    final effectiveTemplate = templateId ?? (profile.invoiceTemplate.isNotEmpty ? profile.invoiceTemplate : 'modern');

    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 2,
    );

    pw.MemoryImage? logoImage;
    if (!kIsWeb && profile.logoUrl != null && profile.logoUrl!.isNotEmpty) {
      try {
        final file = File(profile.logoUrl!);
        if (file.existsSync()) {
          logoImage = pw.MemoryImage(file.readAsBytesSync());
        }
      } catch (e) {
        debugPrint('Logo load error: $e');
      }
    }

    pw.MemoryImage? signatureImage;
    if (!kIsWeb && profile.signatureUrl != null && profile.signatureUrl!.isNotEmpty) {
      try {
        final file = File(profile.signatureUrl!);
        if (file.existsSync()) {
          signatureImage = pw.MemoryImage(file.readAsBytesSync());
        }
      } catch (e) {
        debugPrint('Signature load error: $e');
      }
    }

    switch (effectiveTemplate) {
      case 'genz':
        _buildGenZTemplate(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
      case 'service':
        _buildServiceTemplate(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
      case 'service_2':
        _buildService2Template(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
      case 'professional':
        _buildProfessionalTemplate(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
      case 'billto_shipto':
        _buildBillToShipToTemplate(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
      case 'legend':
        _buildLegendTemplate(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
      case 'evergreen':
        _buildEvergreenTemplate(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
      case 'compact':
        _buildCompactTemplate(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
      case 'classic':
        _buildClassicTemplate(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
      case 'vintage':
        _buildVintageTemplate(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
      case 'elegant':
      case 'minimal':
        _buildMinimalTemplate(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
      case 'elegant_images':
        _buildElegantImagesTemplate(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
      case 'mrp_discount':
        _buildMrpDiscountTemplate(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
      case 'emerald':
        _buildEmeraldTemplate(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
      case 'modern':
      default:
        _buildModernTemplate(pdf, invoice, profile, currencyFormat, logoImage, signatureImage);
        break;
    }

    return pdf.save();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. MODERN INKA TEMPLATE (Vibrant Orange & Sleek Card Layout)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildModernTemplate(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final primaryColor = pdf_lib.PdfColor.fromHex('#FF5722');
    final darkColor = pdf_lib.PdfColor.fromHex('#0F172A');
    final lightBg = pdf_lib.PdfColor.fromHex('#FFF5F2');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Top Accent Bar & Header
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: primaryColor, width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        profile.businessName.isNotEmpty ? profile.businessName.toUpperCase() : 'INKA INVOICE',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: darkColor),
                      ),
                      if (profile.taxIdNumber != null && profile.taxIdNumber!.isNotEmpty)
                        pw.Text('${profile.taxLabel}: ${profile.taxIdNumber}', style: pw.TextStyle(fontSize: 8, color: primaryColor, fontWeight: pw.FontWeight.bold))
                      else if (profile.gstNumber != null && profile.gstNumber!.isNotEmpty)
                        pw.Text('Tax ID: ${profile.gstNumber}', style: pw.TextStyle(fontSize: 8, color: primaryColor, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(profile.address, style: const pw.TextStyle(fontSize: 8.5, color: pdf_lib.PdfColors.grey700)),
                      pw.Text('Tel: ${profile.phone}  •  Email: ${profile.email}', style: const pw.TextStyle(fontSize: 8.5, color: pdf_lib.PdfColors.grey700)),
                    ],
                  ),
                  if (logoImage != null)
                    pw.Image(logoImage, height: 44)
                  else
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text('INVOICE', style: pw.TextStyle(color: pdf_lib.PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Meta row (Invoice #, Issue, Due)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBadge('INVOICE NUMBER', '#${invoice.invoiceNumber}', primaryColor),
                _buildInfoBadge('DATE OF ISSUE', DateFormat('dd MMM yyyy').format(invoice.issueDate), darkColor),
                _buildInfoBadge('PAYMENT DUE', DateFormat('dd MMM yyyy').format(invoice.dueDate), primaryColor),
              ],
            ),
            pw.SizedBox(height: 16),

            // Billed To & Place of Supply
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: pdf_lib.PdfColor.fromHex('#F8FAFC'),
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: pdf_lib.PdfColor.fromHex('#E2E8F0')),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILLED TO:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                      pw.SizedBox(height: 2),
                      pw.Text(invoice.client.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkColor)),
                      pw.Text(invoice.client.address, style: const pw.TextStyle(fontSize: 8.5, color: pdf_lib.PdfColors.grey700)),
                      pw.Text('Ph: ${invoice.client.phone}  •  ${invoice.client.email}', style: const pw.TextStyle(fontSize: 8.5, color: pdf_lib.PdfColors.grey700)),
                      if (invoice.client.gstNumber != null && invoice.client.gstNumber!.isNotEmpty)
                        pw.Text('Tax ID / GSTIN: ${invoice.client.gstNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('STATUS', style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: invoice.status.toLowerCase() == 'paid' ? pdf_lib.PdfColor.fromHex('#ECFDF5') : lightBg,
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Text(
                          invoice.status.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: invoice.status.toLowerCase() == 'paid' ? pdf_lib.PdfColor.fromHex('#10B981') : primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Items Table
            pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(28),
                1: pw.FlexColumnWidth(4),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FixedColumnWidth(36),
                4: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: darkColor, borderRadius: pw.BorderRadius.circular(6)),
                  children: [
                    _headerCell('#', isWhite: true),
                    _headerCell('ITEM & DESCRIPTION', isWhite: true, align: pw.TextAlign.left),
                    _headerCell('RATE', isWhite: true, align: pw.TextAlign.right),
                    _headerCell('QTY', isWhite: true),
                    _headerCell('AMOUNT', isWhite: true, align: pw.TextAlign.right),
                  ],
                ),
                ...invoice.items.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final item = entry.value;
                  final isEven = entry.key % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? pdf_lib.PdfColor.fromHex('#FAFAFA') : pdf_lib.PdfColors.white),
                    children: [
                      _cell(i.toString()),
                      _cell(item.name, align: pw.TextAlign.left, isBold: true),
                      _cell(currencyFormat.format(item.price), align: pw.TextAlign.right),
                      _cell(item.quantity.toString(), align: pw.TextAlign.center),
                      _cell(currencyFormat.format(item.price * item.quantity), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),

            // Totals & Summary Card
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: _buildUpiAndBankBlock(invoice, profile, primaryColor),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: lightBg,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(color: primaryColor.shade(0.3)),
                    ),
                    child: pw.Column(
                      children: [
                        _summaryRowModern('Subtotal', currencyFormat.format(invoice.subtotal)),
                        if (invoice.discount > 0)
                          _summaryRowModern('Discount', '- ${currencyFormat.format(invoice.discount)}'),
                        if (invoice.taxPercentage > 0)
                          _summaryRowModern('${profile.taxLabel} (${invoice.taxPercentage.toStringAsFixed(1)}%)', currencyFormat.format(invoice.taxAmount)),
                        pw.Divider(color: primaryColor.shade(0.3)),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Due:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkColor)),
                            pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // Notes, Terms & Signature
            _buildFooterSignatory(invoice, profile, signatureImage, primaryColor),
          ];
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. CLASSIC CORPORATE TEMPLATE (Structured Navy Grid & Formal Layout)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildClassicTemplate(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final navyColor = pdf_lib.PdfColor.fromHex('#1E3A8A');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TAX INVOICE', style: pw.TextStyle(color: navyColor, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(profile.businessName.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    if (profile.taxIdNumber != null && profile.taxIdNumber!.isNotEmpty)
                      pw.Text('${profile.taxLabel} ID: ${profile.taxIdNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))
                    else if (profile.gstNumber != null && profile.gstNumber!.isNotEmpty)
                      pw.Text('Tax ID: ${profile.gstNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.SizedBox(height: 2),
                    pw.SizedBox(width: 250, child: pw.Text(profile.address, style: const pw.TextStyle(fontSize: 8.5))),
                    pw.Text('Phone: ${profile.phone}  |  Email: ${profile.email}', style: const pw.TextStyle(fontSize: 8.5)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('ORIGINAL FOR RECIPIENT', style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                    pw.SizedBox(height: 8),
                    if (logoImage != null)
                      pw.Image(logoImage, height: 48)
                    else
                      pw.Container(
                        width: 70,
                        height: 35,
                        color: pdf_lib.PdfColors.grey200,
                        alignment: pw.Alignment.center,
                        child: pw.Text('LOGO', style: const pw.TextStyle(fontSize: 8)),
                      ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Divider(thickness: 1, color: navyColor),

            // Meta row
            pw.Row(
              children: [
                _buildMetaItem('Invoice #:', invoice.invoiceNumber),
                _buildMetaItem('Invoice Date:', DateFormat('dd MMM yyyy').format(invoice.issueDate)),
                _buildMetaItem('Due Date:', DateFormat('dd MMM yyyy').format(invoice.dueDate)),
              ],
            ),
            pw.Divider(thickness: 0.8, color: pdf_lib.PdfColors.grey300),

            // Client Info
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _buildPartySection('Customer / Bill To:', [
                    invoice.client.name,
                    'Ph: ${invoice.client.phone}',
                    invoice.client.address,
                    if (invoice.client.gstNumber != null && invoice.client.gstNumber!.isNotEmpty)
                      'GSTIN / Tax ID: ${invoice.client.gstNumber}',
                  ]),
                ),
                pw.Expanded(
                  child: _buildPartySection('Payment Instructions:', [
                    'Bank: ${profile.bankName ?? "As per profile"}',
                    'A/c: ${profile.accountNo ?? "As per profile"}',
                    'IFSC / Swift: ${profile.ifscCode ?? "As per profile"}',
                    if (profile.upiId != null && profile.upiId!.isNotEmpty) 'UPI ID: ${profile.upiId}',
                  ]),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // Grid Table
            pw.Table(
              border: pw.TableBorder.all(color: pdf_lib.PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(25),
                1: pw.FlexColumnWidth(3.5),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FixedColumnWidth(30),
                4: pw.FlexColumnWidth(1.8),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: pdf_lib.PdfColors.grey100),
                  children: [
                    _tableHeader('#'),
                    _tableHeader('Item Description'),
                    _tableHeader('Rate'),
                    _tableHeader('Qty'),
                    _tableHeader('Total Amount'),
                  ],
                ),
                ...invoice.items.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _tableCell(i.toString(), align: pw.TextAlign.center),
                      _tableCell(item.name),
                      _tableCell(currencyFormat.format(item.price), align: pw.TextAlign.right),
                      _tableCell(item.quantity.toString(), align: pw.TextAlign.center),
                      _tableCell(currencyFormat.format(item.price * item.quantity), align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),

            // Summary
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 8),
                      pw.Text('Total Items: ${invoice.items.length}', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Total in Words: ${CurrencyTaxService.findCurrency(profile.currency).code} ${_numberToWords(invoice.total.toInt())} Only.', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal', currencyFormat.format(invoice.subtotal)),
                      if (invoice.discount > 0)
                        _summaryRow('Discount', '- ${currencyFormat.format(invoice.discount)}'),
                      if (invoice.taxPercentage > 0)
                        _summaryRow('${profile.taxLabel} (${invoice.taxPercentage.toStringAsFixed(1)}%)', currencyFormat.format(invoice.taxAmount)),
                      pw.Container(
                        color: navyColor,
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: pdf_lib.PdfColors.white)),
                            pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: pdf_lib.PdfColors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            _buildFooterSignatory(invoice, profile, signatureImage, navyColor),
          ];
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. EXECUTIVE EMERALD TEMPLATE (Forest Teal & Luxury Mint Theme)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildEmeraldTemplate(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final emeraldColor = pdf_lib.PdfColor.fromHex('#0D3B3E');
    final mintColor = pdf_lib.PdfColor.fromHex('#E6F4F1');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Top Emerald Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: emeraldColor,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('EXECUTIVE STATEMENT', style: pw.TextStyle(color: pdf_lib.PdfColor.fromHex('#A7F3D0'), fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(profile.businessName.isNotEmpty ? profile.businessName : 'CONSULTING SERVICES', style: pw.TextStyle(color: pdf_lib.PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('${profile.email}  •  ${profile.phone}', style: const pw.TextStyle(color: pdf_lib.PdfColors.grey300, fontSize: 8.5)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('#${invoice.invoiceNumber}', style: pw.TextStyle(color: pdf_lib.PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Due: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}', style: const pw.TextStyle(color: pdf_lib.PdfColors.grey300, fontSize: 8.5)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Client Info Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: mintColor,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CLIENT RECIPIENT:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: emeraldColor)),
                      pw.SizedBox(height: 2),
                      pw.Text(invoice.client.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: emeraldColor)),
                      pw.Text(invoice.client.address, style: const pw.TextStyle(fontSize: 8.5, color: pdf_lib.PdfColors.grey700)),
                    ],
                  ),
                  if (logoImage != null) pw.Image(logoImage, height: 36),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Table
            pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(28),
                1: pw.FlexColumnWidth(4),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FixedColumnWidth(32),
                4: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: emeraldColor),
                  children: [
                    _headerCell('#', isWhite: true),
                    _headerCell('DESCRIPTION', isWhite: true, align: pw.TextAlign.left),
                    _headerCell('PRICE', isWhite: true, align: pw.TextAlign.right),
                    _headerCell('QTY', isWhite: true),
                    _headerCell('SUBTOTAL', isWhite: true, align: pw.TextAlign.right),
                  ],
                ),
                ...invoice.items.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey200, width: 0.5)),
                    ),
                    children: [
                      _cell(i.toString()),
                      _cell(item.name, align: pw.TextAlign.left),
                      _cell(currencyFormat.format(item.price), align: pw.TextAlign.right),
                      _cell(item.quantity.toString(), align: pw.TextAlign.center),
                      _cell(currencyFormat.format(item.price * item.quantity), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 14),

            // Totals Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 200,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: mintColor,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal', currencyFormat.format(invoice.subtotal)),
                      if (invoice.discount > 0)
                        _summaryRow('Discount', '- ${currencyFormat.format(invoice.discount)}'),
                      if (invoice.taxPercentage > 0)
                        _summaryRow(profile.taxLabel, currencyFormat.format(invoice.taxAmount)),
                      pw.Divider(color: emeraldColor),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Due:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: emeraldColor)),
                          pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: emeraldColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            _buildFooterSignatory(invoice, profile, signatureImage, emeraldColor),
          ];
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. MINIMAL CHARCOAL TEMPLATE (Clean Monochrome & Modern Agency Style)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildMinimalTemplate(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final charcoal = pdf_lib.PdfColor.fromHex('#0F172A');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('INVOICE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: charcoal, letterSpacing: 1.2)),
                    pw.Text('#${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 10, color: pdf_lib.PdfColors.grey600)),
                  ],
                ),
                if (logoImage != null) pw.Image(logoImage, height: 40),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1.5, color: charcoal),
            pw.SizedBox(height: 12),

            // 3-Column Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ISSUED BY', style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey600)),
                    pw.Text(profile.businessName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(profile.email, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('BILLED TO', style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey600)),
                    pw.Text(invoice.client.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(invoice.client.email, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('DUE DATE', style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey600)),
                    pw.Text(DateFormat('dd MMM yyyy').format(invoice.dueDate), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Minimal Table
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(4),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FixedColumnWidth(35),
                3: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.black, width: 1))),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Text('DESCRIPTION', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Text('RATE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Text('QTY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Text('AMOUNT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  ],
                ),
                ...invoice.items.map((item) => pw.TableRow(
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey200, width: 0.5))),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text(currencyFormat.format(item.price), style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text(item.quantity.toString(), style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text(currencyFormat.format(item.price * item.quantity), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 16),

            // Bottom Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 180,
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal', currencyFormat.format(invoice.subtotal)),
                      if (invoice.discount > 0)
                        _summaryRow('Discount', '- ${currencyFormat.format(invoice.discount)}'),
                      if (invoice.taxPercentage > 0)
                        _summaryRow(profile.taxLabel, currencyFormat.format(invoice.taxAmount)),
                      pw.Divider(thickness: 1, color: charcoal),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: charcoal)),
                          pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: charcoal)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            _buildFooterSignatory(invoice, profile, signatureImage, charcoal),
          ];
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 9. PROFESSIONAL TEMPLATE (Marico 3-Column Corporate Style)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildProfessionalTemplate(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final primaryColor = pdf_lib.PdfColor.fromHex('#0284C7');
    final darkColor = pdf_lib.PdfColor.fromHex('#0F172A');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Row: Logo & Company on Left, Tax Invoice on Right
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(height: 40, child: pw.Image(logoImage))
                    else
                      pw.Text(
                        profile.businessName.isNotEmpty ? profile.businessName : 'Company Name',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      ),
                    pw.SizedBox(height: 4),
                    pw.Text(profile.businessName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkColor)),
                    pw.Text(profile.address, style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                    if (profile.gstNumber != null && profile.gstNumber!.isNotEmpty)
                      pw.Text('GSTIN: ${profile.gstNumber}', style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                    pw.Text('Phone: ${profile.phone}  •  Email: ${profile.email}', style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: darkColor)),
                    pw.Text('ORIGINAL FOR RECIPIENT', style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // 3-Column Info Card: Bill To | Ship To | Details
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: pdf_lib.PdfColor.fromHex('#F8FAFC'),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: pdf_lib.PdfColor.fromHex('#E2E8F0')),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill to', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        pw.SizedBox(height: 2),
                        pw.Text(invoice.client.name, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text(invoice.client.address, style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                        if (invoice.client.phone.isNotEmpty)
                          pw.Text('Ph: ${invoice.client.phone}', style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Ship to', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        pw.SizedBox(height: 2),
                        pw.Text(invoice.client.name, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text(invoice.client.address, style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Details', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        pw.SizedBox(height: 2),
                        pw.Text('Invoice No: #${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Invoice Date: ${DateFormat('dd MMM yyyy').format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                        pw.Text('Due Date: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}', style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                        pw.Text('Place of Supply: ${profile.taxLabel}', style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Table of items
            pw.Table(
              border: const pw.TableBorder(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey300, width: 0.5)),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(5),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
                5: const pw.FlexColumnWidth(2.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey400, width: 1))),
                  children: [
                    _headerCell('#', align: pw.TextAlign.left),
                    _headerCell('Item / Description', align: pw.TextAlign.left),
                    _headerCell('Qty', align: pw.TextAlign.center),
                    _headerCell('Rate', align: pw.TextAlign.right),
                    _headerCell('Tax', align: pw.TextAlign.right),
                    _headerCell('Amount', align: pw.TextAlign.right),
                  ],
                ),
                ...invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey200, width: 0.5))),
                    children: [
                      _cell('$idx', align: pw.TextAlign.left),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: pw.Text(item.name, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      ),
                      _cell('${item.quantity}'),
                      _cell(currencyFormat.format(item.price), align: pw.TextAlign.right),
                      _cell('${invoice.taxPercentage.toStringAsFixed(0)}%', align: pw.TextAlign.right),
                      _cell(currencyFormat.format(item.total), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),

            // Summary & Payment Section
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: _buildUpiAndBankBlock(invoice, profile, primaryColor),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    children: [
                      _summaryRowModern('Subtotal', currencyFormat.format(invoice.subtotal)),
                      if (invoice.discount > 0)
                        _summaryRowModern('Discount', '-${currencyFormat.format(invoice.discount)}'),
                      if (invoice.taxAmount > 0)
                        _summaryRowModern(profile.taxLabel, currencyFormat.format(invoice.taxAmount)),
                      pw.Divider(color: pdf_lib.PdfColors.grey300),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkColor)),
                          pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            _buildFooterSignatory(invoice, profile, signatureImage, primaryColor),
          ];
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 10. BILL TO - SHIP TO TEMPLATE (Flipkart Dual Logistics Style)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildBillToShipToTemplate(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final primaryColor = pdf_lib.PdfColor.fromHex('#2563EB');
    final darkColor = pdf_lib.PdfColor.fromHex('#0F172A');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Top Header: Logo on left, Tax Invoice details on right
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    if (logoImage != null)
                      pw.Container(height: 40, width: 40, child: pw.Image(logoImage))
                    else
                      pw.Container(
                        width: 38,
                        height: 38,
                        decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(6)),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          profile.businessName.isNotEmpty ? profile.businessName[0].toUpperCase() : 'B',
                          style: pw.TextStyle(color: pdf_lib.PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    pw.SizedBox(width: 10),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(profile.businessName.isNotEmpty ? profile.businessName : 'Enterprise', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: darkColor)),
                        if (profile.gstNumber != null && profile.gstNumber!.isNotEmpty)
                          pw.Text('GSTIN ${profile.gstNumber}', style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey700)),
                        pw.Text('Mobile: ${profile.phone}  •  Email: ${profile.email}', style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkColor)),
                    pw.Text('ORIGINAL FOR RECIPIENT', style: const pw.TextStyle(fontSize: 7, color: pdf_lib.PdfColors.grey600)),
                    pw.Text('Invoice #: INV-${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Invoice Date: ${DateFormat('dd MMM yyyy').format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 2 Dual Logistics Address Blocks
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: pdf_lib.PdfColors.grey300, width: 0.8), borderRadius: pw.BorderRadius.circular(4)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill From:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        pw.Text(profile.businessName, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text(profile.address, style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text('Ship From:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        pw.Text(profile.address, style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey700)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: pdf_lib.PdfColors.grey300, width: 0.8), borderRadius: pw.BorderRadius.circular(4)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill To:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        pw.Text(invoice.client.name, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text(invoice.client.address, style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text('Ship to:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        pw.Text(invoice.client.address, style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // Grid Items Table
            pw.Table(
              border: pw.TableBorder.all(color: pdf_lib.PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: pdf_lib.PdfColors.grey100),
                  children: [
                    _headerCell('#', align: pw.TextAlign.center),
                    _headerCell('Item', align: pw.TextAlign.left),
                    _headerCell('Rate/Item', align: pw.TextAlign.right),
                    _headerCell('Qty', align: pw.TextAlign.center),
                    _headerCell('Taxable Value', align: pw.TextAlign.right),
                    _headerCell('Amount', align: pw.TextAlign.right),
                  ],
                ),
                ...invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _cell('$idx', align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(item.name, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      _cell(currencyFormat.format(item.price), align: pw.TextAlign.right),
                      _cell('${item.quantity}'),
                      _cell(currencyFormat.format(item.total), align: pw.TextAlign.right),
                      _cell(currencyFormat.format(item.total), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 10),

            // Bank & Summary
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(flex: 5, child: _buildUpiAndBankBlock(invoice, profile, primaryColor)),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    children: [
                      _summaryRowModern('Taxable Amount', currencyFormat.format(invoice.subtotal)),
                      if (invoice.taxAmount > 0)
                        _summaryRowModern(profile.taxLabel, currencyFormat.format(invoice.taxAmount)),
                      pw.Container(
                        margin: const pw.EdgeInsets.only(top: 4),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: darkColor, width: 1.2)),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            _buildFooterSignatory(invoice, profile, signatureImage, primaryColor),
          ];
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 11. LEGEND TEMPLATE (ITC e-Invoice & IRN Matrix Style)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildLegendTemplate(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final darkColor = pdf_lib.PdfColor.fromHex('#0F172A');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // Top IRN & e-Invoice QR
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null) pw.Container(height: 36, child: pw.Image(logoImage)),
                    pw.Text(profile.businessName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: darkColor)),
                    pw.Text(profile.address, style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey700)),
                    if (profile.gstNumber != null && profile.gstNumber!.isNotEmpty)
                      pw.Text('GSTIN: ${profile.gstNumber}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('IRN: 46257511d851510e07adc2feb9a4def20eaddfd91326f72b20b731857e1fb6c9', style: const pw.TextStyle(fontSize: 6, color: pdf_lib.PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text('ORIGINAL FOR RECIPIENT', style: const pw.TextStyle(fontSize: 6.5, color: pdf_lib.PdfColors.grey600)),
                    pw.SizedBox(height: 4),
                    pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: 'IRN-VALIDATED-${invoice.invoiceNumber}', width: 44, height: 44),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Boxed Grid Matrix
            pw.Table(
              border: pw.TableBorder.all(color: pdf_lib.PdfColors.grey400, width: 0.6),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Customer Details:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                          pw.Text(invoice.client.name, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                          pw.Text(invoice.client.address, style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey700)),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Invoice #: ${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Date: ${DateFormat('dd MMM yyyy').format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 7.5)),
                          pw.Text('Due Date: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}', style: const pw.TextStyle(fontSize: 7.5)),
                          pw.Text('Place of Supply: 27-MAHARASHTRA', style: const pw.TextStyle(fontSize: 7.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),

            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: pdf_lib.PdfColors.grey400, width: 0.6),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: pdf_lib.PdfColors.grey100),
                  children: [
                    _headerCell('#'),
                    _headerCell('Item Description', align: pw.TextAlign.left),
                    _headerCell('Rate/Item', align: pw.TextAlign.right),
                    _headerCell('Qty'),
                    _headerCell('Taxable Value', align: pw.TextAlign.right),
                    _headerCell('Amount', align: pw.TextAlign.right),
                  ],
                ),
                ...invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _cell('$idx'),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(item.name, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      _cell(currencyFormat.format(item.price), align: pw.TextAlign.right),
                      _cell('${item.quantity}'),
                      _cell(currencyFormat.format(item.total), align: pw.TextAlign.right),
                      _cell(currencyFormat.format(item.total), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 8),

            // Bank & Total
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(flex: 5, child: _buildUpiAndBankBlock(invoice, profile, darkColor)),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    children: [
                      _summaryRowModern('Taxable Amount', currencyFormat.format(invoice.subtotal)),
                      if (invoice.taxAmount > 0)
                        _summaryRowModern(profile.taxLabel, currencyFormat.format(invoice.taxAmount)),
                      pw.Divider(color: darkColor, thickness: 1),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            _buildFooterSignatory(invoice, profile, signatureImage, darkColor),
          ];
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 12. SERVICE TEMPLATE 2 (LTIMindtree Corporate Services Style)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildService2Template(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final tealColor = pdf_lib.PdfColor.fromHex('#0D9488');
    final darkColor = pdf_lib.PdfColor.fromHex('#0F172A');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null) pw.Container(height: 38, child: pw.Image(logoImage)),
                    pw.Text(profile.businessName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: tealColor)),
                    pw.Text(profile.address, style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                    pw.Text('Email: ${profile.email}', style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkColor)),
                    pw.Text('Invoice #: INV-${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${DateFormat('dd MMM yyyy').format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: pdf_lib.PdfColor.fromHex('#F0FDFA'), borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: tealColor)),
                      pw.Text(invoice.client.name, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.client.email, style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Due Date: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: tealColor)),
                      pw.Text('Terms: Payable upon receipt', style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Service Items Table
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(6),
                2: const pw.FlexColumnWidth(2.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey400, width: 1))),
                  children: [
                    _headerCell('#', align: pw.TextAlign.left),
                    _headerCell('Service Description', align: pw.TextAlign.left),
                    _headerCell('Rate/Unit', align: pw.TextAlign.right),
                    _headerCell('Qty', align: pw.TextAlign.center),
                    _headerCell('Amount', align: pw.TextAlign.right),
                  ],
                ),
                ...invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey200, width: 0.5))),
                    children: [
                      _cell('$idx', align: pw.TextAlign.left),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                        child: pw.Text(item.name, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      ),
                      _cell(currencyFormat.format(item.price), align: pw.TextAlign.right),
                      _cell('${item.quantity}'),
                      _cell(currencyFormat.format(item.total), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),

            // Totals and Bank
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(flex: 5, child: _buildUpiAndBankBlock(invoice, profile, tealColor)),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    children: [
                      _summaryRowModern('Service Charges', currencyFormat.format(invoice.subtotal)),
                      if (invoice.taxAmount > 0)
                        _summaryRowModern(profile.taxLabel, currencyFormat.format(invoice.taxAmount)),
                      pw.Divider(color: tealColor),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Payable', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: tealColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            _buildFooterSignatory(invoice, profile, signatureImage, tealColor),
          ];
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 13. VINTAGE INDUSTRIAL TEMPLATE (Tata Motors Style)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildVintageTemplate(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final tataBlue = pdf_lib.PdfColor.fromHex('#1E40AF');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(color: tataBlue, width: 1.2)),
              child: pw.Column(
                children: [
                  // Top Banner
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    color: pdf_lib.PdfColors.grey100,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(profile.businessName.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: tataBlue)),
                        pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: tataBlue)),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Billed To: ${invoice.client.name}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                            pw.Text(invoice.client.address, style: const pw.TextStyle(fontSize: 7.5)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Invoice #: INV-${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Date: ${DateFormat('dd MMM yyyy').format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 7.5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: pdf_lib.PdfColors.grey400, width: 0.6),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: tataBlue),
                  children: [
                    _headerCell('#', isWhite: true),
                    _headerCell('Item Description', isWhite: true, align: pw.TextAlign.left),
                    _headerCell('Rate', isWhite: true, align: pw.TextAlign.right),
                    _headerCell('Qty', isWhite: true),
                    _headerCell('Amount', isWhite: true, align: pw.TextAlign.right),
                  ],
                ),
                ...invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _cell('$idx'),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.name, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      _cell(currencyFormat.format(item.price), align: pw.TextAlign.right),
                      _cell('${item.quantity}'),
                      _cell(currencyFormat.format(item.total), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 10),

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(flex: 5, child: _buildUpiAndBankBlock(invoice, profile, tataBlue)),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    children: [
                      _summaryRowModern('Subtotal', currencyFormat.format(invoice.subtotal)),
                      if (invoice.taxAmount > 0)
                        _summaryRowModern(profile.taxLabel, currencyFormat.format(invoice.taxAmount)),
                      pw.Divider(color: tataBlue),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: tataBlue)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            _buildFooterSignatory(invoice, profile, signatureImage, tataBlue),
          ];
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 14. ELEGANT WITH IMAGES TEMPLATE (Nike Visual Product Style)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildElegantImagesTemplate(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final blackColor = pdf_lib.PdfColor.fromHex('#18181B');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (logoImage != null) pw.Container(height: 40, child: pw.Image(logoImage))
                else pw.Text(profile.businessName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: blackColor)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('ORIGINAL FOR RECIPIENT', style: const pw.TextStyle(fontSize: 7, color: pdf_lib.PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Meta Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bill To: ${invoice.client.name}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text(invoice.client.address, style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Invoice #: INV-${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${DateFormat('dd MMM yyyy').format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Table with Black Header
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(6),
                2: const pw.FlexColumnWidth(2.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: blackColor),
                  children: [
                    _headerCell('#', isWhite: true),
                    _headerCell('Item', isWhite: true, align: pw.TextAlign.left),
                    _headerCell('Rate/Item', isWhite: true, align: pw.TextAlign.right),
                    _headerCell('Qty', isWhite: true),
                    _headerCell('Amount', isWhite: true, align: pw.TextAlign.right),
                  ],
                ),
                ...invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey200, width: 0.5))),
                    children: [
                      _cell('$idx'),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(item.name, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      ),
                      _cell(currencyFormat.format(item.price), align: pw.TextAlign.right),
                      _cell('${item.quantity}'),
                      _cell(currencyFormat.format(item.total), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(flex: 5, child: _buildUpiAndBankBlock(invoice, profile, blackColor)),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    children: [
                      _summaryRowModern('Subtotal', currencyFormat.format(invoice.subtotal)),
                      if (invoice.taxAmount > 0)
                        _summaryRowModern(profile.taxLabel, currencyFormat.format(invoice.taxAmount)),
                      pw.Divider(color: blackColor),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: blackColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            _buildFooterSignatory(invoice, profile, signatureImage, blackColor),
          ];
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 15. MRP + DISCOUNT TEMPLATE (DMart Supermarket Style)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildMrpDiscountTemplate(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final dmartGreen = pdf_lib.PdfColor.fromHex('#059669');
    final darkColor = pdf_lib.PdfColor.fromHex('#0F172A');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null) pw.Container(height: 38, child: pw.Image(logoImage)),
                    pw.Text(profile.businessName, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: dmartGreen)),
                    pw.Text(profile.address, style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkColor)),
                    pw.Text('Invoice #: INV-${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${DateFormat('dd MMM yyyy').format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Table with MRP & Selling Price
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(5),
                2: const pw.FlexColumnWidth(2.5),
                3: const pw.FlexColumnWidth(2.5),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey400, width: 1))),
                  children: [
                    _headerCell('#', align: pw.TextAlign.left),
                    _headerCell('Item', align: pw.TextAlign.left),
                    _headerCell('MRP', align: pw.TextAlign.right),
                    _headerCell('Selling Price', align: pw.TextAlign.right),
                    _headerCell('Qty', align: pw.TextAlign.center),
                    _headerCell('Amount', align: pw.TextAlign.right),
                  ],
                ),
                ...invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final mrp = item.price * 1.15; // Estimated MRP
                  return pw.TableRow(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey200, width: 0.5))),
                    children: [
                      _cell('$idx', align: pw.TextAlign.left),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(item.name, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      ),
                      _cell(currencyFormat.format(mrp), align: pw.TextAlign.right),
                      _cell(currencyFormat.format(item.price), align: pw.TextAlign.right),
                      _cell('${item.quantity}'),
                      _cell(currencyFormat.format(item.total), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(flex: 5, child: _buildUpiAndBankBlock(invoice, profile, dmartGreen)),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    children: [
                      _summaryRowModern('Total Items', '${invoice.items.length}'),
                      _summaryRowModern('Subtotal', currencyFormat.format(invoice.subtotal)),
                      if (invoice.taxAmount > 0)
                        _summaryRowModern(profile.taxLabel, currencyFormat.format(invoice.taxAmount)),
                      pw.Divider(color: dmartGreen),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Payable', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: dmartGreen)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            _buildFooterSignatory(invoice, profile, signatureImage, dmartGreen),
          ];
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // REUSABLE HELPER WIDGETS
  // ─────────────────────────────────────────────────────────────────────────────
  static pw.Widget _buildInfoBadge(String label, String value, pdf_lib.PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.Widget _headerCell(String text, {bool isWhite = false, pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: isWhite ? pdf_lib.PdfColors.white : pdf_lib.PdfColors.black),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _cell(String text, {pw.TextAlign align = pw.TextAlign.center, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _summaryRowModern(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: pdf_lib.PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildUpiAndBankBlock(Invoice invoice, BusinessProfile profile, pdf_lib.PdfColor accentColor) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: PaymentQrService.buildUpiUrl(
            upiId: (profile.upiId != null && profile.upiId!.isNotEmpty) ? profile.upiId! : '${profile.email.split("@").first}@okaxis',
            payeeName: profile.businessName.isNotEmpty ? profile.businessName : 'Inka Business',
            amount: invoice.total,
            invoiceNumber: invoice.invoiceNumber,
          ),
          width: 60,
          height: 60,
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Scan to Pay via UPI', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: accentColor)),
              if (profile.upiId != null && profile.upiId!.isNotEmpty)
                pw.Text('UPI: ${profile.upiId}', style: const pw.TextStyle(fontSize: 7.5)),
              if (profile.bankName != null && profile.bankName!.isNotEmpty)
                pw.Text('Bank: ${profile.bankName}  •  A/C: ${profile.accountNo ?? ""}', style: const pw.TextStyle(fontSize: 7.5)),
              if (profile.ifscCode != null && profile.ifscCode!.isNotEmpty)
                pw.Text('IFSC: ${profile.ifscCode}', style: const pw.TextStyle(fontSize: 7.5)),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. GENZ BLUE TEMPLATE (Royal Blue Modern Digital Native Layout)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildGenZTemplate(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final blueColor = pdf_lib.PdfColor.fromHex('#2563EB');
    final darkColor = pdf_lib.PdfColor.fromHex('#0F172A');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: blueColor,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(profile.businessName.isNotEmpty ? profile.businessName : 'GOOGLE INC.', style: pw.TextStyle(color: pdf_lib.PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('TAX INVOICE', style: pw.TextStyle(color: pdf_lib.PdfColor.fromHex('#BFDBFE'), fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      if (profile.address.isNotEmpty) pw.Text(profile.address, style: const pw.TextStyle(color: pdf_lib.PdfColors.white, fontSize: 8)),
                    ],
                  ),
                  if (logoImage != null)
                    pw.Container(
                      width: 50,
                      height: 50,
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(color: pdf_lib.PdfColors.white, borderRadius: pw.BorderRadius.circular(8)),
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('ORIGINAL FOR RECIPIENT', style: const pw.TextStyle(color: pdf_lib.PdfColors.white, fontSize: 8)),
                        if (profile.gstNumber != null && profile.gstNumber!.isNotEmpty)
                          pw.Text('GSTIN: ${profile.gstNumber}', style: const pw.TextStyle(color: pdf_lib.PdfColors.white, fontSize: 8)),
                      ],
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: pdf_lib.PdfColor.fromHex('#F8FAFC'),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: pdf_lib.PdfColor.fromHex('#E2E8F0')),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetaItem('Invoice #:', invoice.invoiceNumber),
                  _buildMetaItem('Invoice Date:', DateFormat('dd MMM yyyy').format(invoice.issueDate)),
                  _buildMetaItem('Due Date:', DateFormat('dd MMM yyyy').format(invoice.dueDate)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: pdf_lib.PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: pdf_lib.PdfColor.fromHex('#E2E8F0')),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Customer Details:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: blueColor)),
                        pw.SizedBox(height: 2),
                        pw.Text(invoice.client.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkColor)),
                        if (invoice.client.phone.isNotEmpty) pw.Text('Ph: ${invoice.client.phone}', style: const pw.TextStyle(fontSize: 8)),
                        if (invoice.client.email.isNotEmpty) pw.Text(invoice.client.email, style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: pdf_lib.PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: pdf_lib.PdfColor.fromHex('#E2E8F0')),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Billing & Shipping Address:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: blueColor)),
                        pw.SizedBox(height: 2),
                        pw.Text(invoice.client.address.isNotEmpty ? invoice.client.address : 'Standard Delivery Address', style: const pw.TextStyle(fontSize: 8.5)),
                        pw.Text('Place of Supply: Inter-State', style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Item Description', 'Rate', 'Qty', 'Amount'],
              data: invoice.items.asMap().entries.map((e) {
                final idx = e.key + 1;
                final item = e.value;
                return [
                  '$idx',
                  item.name,
                  currencyFormat.format(item.price),
                  '${item.quantity}',
                  currencyFormat.format(item.total),
                ];
              }).toList(),
              border: null,
              headerStyle: pw.TextStyle(color: pdf_lib.PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8.5),
              headerDecoration: pw.BoxDecoration(
                color: blueColor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey200, width: 0.8)),
              ),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 14),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: _buildUpiAndBankBlock(invoice, profile, blueColor),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal', currencyFormat.format(invoice.subtotal)),
                      if (invoice.taxAmount > 0)
                        _summaryRow('${profile.taxLabel} (${invoice.taxPercentage.toStringAsFixed(0)}%)', currencyFormat.format(invoice.taxAmount)),
                      if (invoice.discount > 0)
                        _summaryRow('Discount', '-${currencyFormat.format(invoice.discount)}'),
                      pw.Divider(color: blueColor, thickness: 1),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: blueColor,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Amount', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.white)),
                            pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            _buildFooterSignatory(invoice, profile, signatureImage, blueColor),
          ];
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. SERVICE AGENCY TEMPLATE (Rose Magenta Theme)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildServiceTemplate(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final pinkColor = pdf_lib.PdfColor.fromHex('#E11D48');
    final darkColor = pdf_lib.PdfColor.fromHex('#0F172A');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(profile.businessName.isNotEmpty ? profile.businessName : 'CREATIVE AGENCY', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: pinkColor)),
                    pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkColor)),
                    pw.Text('${profile.email}  •  ${profile.phone}', style: const pw.TextStyle(fontSize: 8.5, color: pdf_lib.PdfColors.grey700)),
                  ],
                ),
                if (logoImage != null)
                  pw.Container(width: 50, height: 50, child: pw.Image(logoImage, fit: pw.BoxFit.contain))
                else
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice #: ${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkColor)),
                      pw.Text('Date: ${DateFormat('dd MMM yyyy').format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Container(height: 2, color: pinkColor),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: pdf_lib.PdfColor.fromHex('#FFF1F2'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: pinkColor)),
                      pw.Text(invoice.client.name, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                      if (invoice.client.address.isNotEmpty) pw.Text(invoice.client.address, style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Due Date: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: pinkColor)),
                      if (invoice.client.phone.isNotEmpty) pw.Text('Ph: ${invoice.client.phone}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Service Description', 'Rate', 'Qty', 'Amount'],
              data: invoice.items.asMap().entries.map((e) {
                final idx = e.key + 1;
                final item = e.value;
                return [
                  '$idx',
                  item.name,
                  currencyFormat.format(item.price),
                  '${item.quantity}',
                  currencyFormat.format(item.total),
                ];
              }).toList(),
              border: null,
              headerStyle: pw.TextStyle(color: pdf_lib.PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8.5),
              headerDecoration: pw.BoxDecoration(
                color: pinkColor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: pdf_lib.PdfColors.grey200, width: 0.8)),
              ),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 14),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: _buildUpiAndBankBlock(invoice, profile, pinkColor),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal', currencyFormat.format(invoice.subtotal)),
                      if (invoice.taxAmount > 0)
                        _summaryRow('${profile.taxLabel} (${invoice.taxPercentage.toStringAsFixed(0)}%)', currencyFormat.format(invoice.taxAmount)),
                      pw.Divider(color: pinkColor, thickness: 1),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pinkColor)),
                          pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: pinkColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            _buildFooterSignatory(invoice, profile, signatureImage, pinkColor),
          ];
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. EVERGREEN BOXED GRID TEMPLATE (Structured Full Border Table)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildEvergreenTemplate(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final greenColor = pdf_lib.PdfColor.fromHex('#15803D');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: greenColor, width: 1.2),
              ),
              child: pw.Column(
                children: [
                  pw.Container(
                    color: pdf_lib.PdfColor.fromHex('#F0FDF4'),
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(profile.businessName.isNotEmpty ? profile.businessName : 'HINDUSTAN UNILEVER', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: greenColor)),
                        pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: greenColor)),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Bill To: ${invoice.client.name}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            if (invoice.client.address.isNotEmpty) pw.Text(invoice.client.address, style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Invoice #: ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 8.5)),
                            pw.Text('Date: ${DateFormat('dd MMM yyyy').format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 8.5)),
                            pw.Text('Due: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}', style: const pw.TextStyle(fontSize: 8.5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Item', 'Qty', 'Rate', 'Tax', 'Amount'],
              data: invoice.items.asMap().entries.map((e) {
                final idx = e.key + 1;
                final item = e.value;
                return [
                  '$idx',
                  item.name,
                  '${item.quantity}',
                  currencyFormat.format(item.price),
                  '${invoice.taxPercentage.toStringAsFixed(0)}%',
                  currencyFormat.format(item.total),
                ];
              }).toList(),
              border: pw.TableBorder.all(color: greenColor, width: 0.8),
              headerStyle: pw.TextStyle(color: pdf_lib.PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: pw.BoxDecoration(color: greenColor),
              cellPadding: const pw.EdgeInsets.all(5),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.center,
                5: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: _buildUpiAndBankBlock(invoice, profile, greenColor),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: greenColor, width: 0.8),
                    ),
                    child: pw.Column(
                      children: [
                        _summaryRow('Taxable Total', currencyFormat.format(invoice.subtotal)),
                        if (invoice.taxAmount > 0)
                          _summaryRow(profile.taxLabel, currencyFormat.format(invoice.taxAmount)),
                        pw.Divider(color: greenColor),
                        _summaryRow('Grand Total', currencyFormat.format(invoice.total)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            _buildFooterSignatory(invoice, profile, signatureImage, greenColor),
          ];
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 8. COMPACT B2B TEMPLATE (High-Efficiency Slate Grid)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _buildCompactTemplate(
    pw.Document pdf,
    Invoice invoice,
    BusinessProfile profile,
    dynamic currencyFormat,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
  ) {
    final slateColor = pdf_lib.PdfColor.fromHex('#334155');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(profile.businessName.isNotEmpty ? profile.businessName : 'B2B ENTERPRISES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: slateColor)),
                    pw.Text('TAX INVOICE • ORIGINAL', style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Inv #: ${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Item Details', 'Qty', 'Unit Rate', 'Amount'],
              data: invoice.items.asMap().entries.map((e) {
                final idx = e.key + 1;
                final item = e.value;
                return [
                  '$idx',
                  item.name,
                  '${item.quantity}',
                  currencyFormat.format(item.price),
                  currencyFormat.format(item.total),
                ];
              }).toList(),
              border: pw.TableBorder.all(color: pdf_lib.PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(color: pdf_lib.PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: pw.BoxDecoration(color: slateColor),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: _buildUpiAndBankBlock(invoice, profile, slateColor),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal', currencyFormat.format(invoice.subtotal)),
                      if (invoice.taxAmount > 0)
                        _summaryRow(profile.taxLabel, currencyFormat.format(invoice.taxAmount)),
                      pw.Divider(color: slateColor, thickness: 0.8),
                      _summaryRow('Total Payable', currencyFormat.format(invoice.total)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            _buildFooterSignatory(invoice, profile, signatureImage, slateColor),
          ];
        },
      ),
    );
  }

  static pw.Widget _buildFooterSignatory(Invoice invoice, BusinessProfile profile, pw.MemoryImage? signatureImage, pdf_lib.PdfColor primaryColor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.SizedBox(
          width: 300,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (invoice.notes.isNotEmpty) ...[
                pw.Text('Notes:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text(invoice.notes, style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey700)),
                pw.SizedBox(height: 4),
              ],
              pw.Text('Terms: Payment is requested by the due date. Thank you for your business!', style: const pw.TextStyle(fontSize: 7, color: pdf_lib.PdfColors.grey600)),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (signatureImage != null)
              pw.Image(signatureImage, height: 35)
            else
              pw.Container(
                width: 70,
                height: 25,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: pdf_lib.PdfColors.grey400, width: 0.5, style: pw.BorderStyle.dashed),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text('SIGNATURE', style: const pw.TextStyle(fontSize: 5, color: pdf_lib.PdfColors.grey400)),
              ),
            pw.SizedBox(height: 2),
            pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 7.5, color: pdf_lib.PdfColors.grey700)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMetaItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label ', style: const pw.TextStyle(fontSize: 8.5, color: pdf_lib.PdfColors.grey700)),
            pw.TextSpan(text: value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPartySection(String title, List<String> details) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 8.5, color: pdf_lib.PdfColors.grey700)),
          pw.SizedBox(height: 2),
          ...details.map((d) => pw.Text(d, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: align == pw.TextAlign.right ? pw.Alignment.centerRight : (align == pw.TextAlign.center ? pw.Alignment.center : pw.Alignment.centerLeft),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }

  static pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: pdf_lib.PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static String _numberToWords(int number) {
    if (number == 0) return "Zero";
    if (number < 0) return "Minus ${_numberToWords(-number)}";
    const units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    const tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];
    if (number < 20) return units[number];
    if (number < 100) return tens[number ~/ 10] + (number % 10 != 0 ? " ${units[number % 10]}" : "");
    if (number < 1000) return "${units[number ~/ 100]} Hundred${number % 100 != 0 ? " and ${_numberToWords(number % 100)}" : ""}";
    if (number < 1000000) return "${_numberToWords(number ~/ 1000)} Thousand${number % 1000 != 0 ? " ${_numberToWords(number % 1000)}" : ""}";
    if (number < 1000000000) return "${_numberToWords(number ~/ 1000000)} Million${number % 1000000 != 0 ? " ${_numberToWords(number % 1000000)}" : ""}";
    return number.toString();
  }

  static Future<void> printInvoice(Invoice invoice, BusinessProfile profile, {String? templateId}) async {
    final pdfBytes = await generateInvoicePdf(invoice, profile, templateId: templateId);
    await Printing.layoutPdf(
      onLayout: (pdf_lib.PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  static Future<void> shareInvoice(Invoice invoice, BusinessProfile profile, {String? templateId}) async {
    final pdfBytes = await generateInvoicePdf(invoice, profile, templateId: templateId);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }
}
