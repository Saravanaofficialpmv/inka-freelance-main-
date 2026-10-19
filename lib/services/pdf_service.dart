import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/business_profile.dart';
import '../data/models/invoice.dart';
import '../features/invoices/templates/invoice_template.dart';
import '../features/invoices/templates/invoice_template_config.dart';
import '../features/invoices/templates/invoice_template_registry.dart';
import 'currency_tax_service.dart';

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
      id: 'template_billto_shipto',
      name: 'Logistics 4-Party',
      subtitle: 'Separate Bill From, Bill To, Ship From & Ship To',
      tag: 'Logistics',
      primaryColorHex: '#1E40AF',
      icon: '🚚',
      assetPreview: 'assets/templates/template_billto_shipto.jpg',
    ),
    PdfTemplateOption(
      id: 'template_classic',
      name: 'Classic Corporate',
      subtitle: 'Structured navy table with circular seal stamp',
      tag: 'Executive',
      primaryColorHex: '#003399',
      icon: '🏛️',
      assetPreview: 'assets/templates/template_classic.jpg',
    ),
    PdfTemplateOption(
      id: 'template_compact',
      name: 'Compact Retail',
      subtitle: 'Dense receipt-inspired grid with HSN tax summary',
      tag: 'Retail',
      primaryColorHex: '#18181B',
      icon: '🧾',
      assetPreview: 'assets/templates/template_compact.jpg',
    ),
    PdfTemplateOption(
      id: 'template_elegant',
      name: 'Elegant Minimalist',
      subtitle: 'Solid jet-black header with stacked parties',
      tag: 'Minimal',
      primaryColorHex: '#111827',
      icon: '📄',
      assetPreview: 'assets/templates/template_elegant.jpg',
    ),
    PdfTemplateOption(
      id: 'template_elegant_images',
      name: 'Elegant Product Visual',
      subtitle: 'Clean monochrome table with item image thumbnails',
      tag: 'Products',
      primaryColorHex: '#1F2937',
      icon: '🖼️',
      assetPreview: 'assets/templates/template_elegant_images.jpg',
    ),
    PdfTemplateOption(
      id: 'template_evergreen',
      name: 'Evergreen Corporate',
      subtitle: 'Forest green header with 8-column GST tax breakdown',
      tag: 'Corporate',
      primaryColorHex: '#0D5C3A',
      icon: '🌲',
      assetPreview: 'assets/templates/template_evergreen.jpg',
    ),
    PdfTemplateOption(
      id: 'template_genz',
      name: 'Gen-Z Modern',
      subtitle: 'Vibrant royal blue banner with product gallery cards',
      tag: 'Modern',
      primaryColorHex: '#1A73E8',
      icon: '⚡',
      assetPreview: 'assets/templates/template_genz.jpg',
    ),
    PdfTemplateOption(
      id: 'template_legend',
      name: 'Legend B2B e-Invoice',
      subtitle: 'B2B e-Invoice with IRN, Ack No & dual QR codes',
      tag: 'e-Invoice',
      primaryColorHex: '#0F2C59',
      icon: '📋',
      assetPreview: 'assets/templates/template_legend.jpg',
    ),
    PdfTemplateOption(
      id: 'template_modern',
      name: 'Modern Document',
      subtitle: 'Clean 7-column layout with right-aligned seller info',
      tag: 'Popular',
      primaryColorHex: '#131921',
      icon: '💎',
      assetPreview: 'assets/templates/template_modern.jpg',
    ),
    PdfTemplateOption(
      id: 'template_mrp_discount',
      name: 'Retail MRP & Discount',
      subtitle: 'Supermarket POS with MRP, Rate & Total Savings banner',
      tag: 'POS & Mart',
      primaryColorHex: '#15803D',
      icon: '🛒',
      assetPreview: 'assets/templates/template_mrp_discount.jpg',
    ),
    PdfTemplateOption(
      id: 'template_professional',
      name: 'Professional 3-Column',
      subtitle: 'Supplier, buyer, and dispatch header with dual signatures',
      tag: 'Traditional',
      primaryColorHex: '#1E3A8A',
      icon: '📜',
      assetPreview: 'assets/templates/template_professional.jpg',
    ),
    PdfTemplateOption(
      id: 'template_service',
      name: 'Creative Agency Service',
      subtitle: 'Hot magenta consulting layout for deliverables & SAC',
      tag: 'Creative',
      primaryColorHex: '#E1306C',
      icon: '🎨',
      assetPreview: 'assets/templates/template_service.jpg',
    ),
    PdfTemplateOption(
      id: 'template_service_2',
      name: 'IT Consulting & Tech',
      subtitle: 'Enterprise IT consulting with hourly rates & client sign',
      tag: 'Consulting',
      primaryColorHex: '#004B6E',
      icon: '💼',
      assetPreview: 'assets/templates/template_service_2.jpg',
    ),
    PdfTemplateOption(
      id: 'template_vintage',
      name: 'Vintage Industrial',
      subtitle:
          'Industrial boxed grid with Tata blue header and full tax table',
      tag: 'Industrial',
      primaryColorHex: '#005A9C',
      icon: '🏭',
      assetPreview: 'assets/templates/template_vintage.jpg',
    ),
  ];

  /// Resolves the user's saved template preference or falls back safely.
  static InvoiceTemplateConfig _loadSavedConfig(
    BusinessProfile profile,
    String? explicitTemplateId,
  ) {
    try {
      if (Hive.isBoxOpen('template_config')) {
        final box = Hive.box('template_config');
        final raw = box.get('current');
        if (raw is Map) {
          final loaded = InvoiceTemplateConfig.fromMap(
            Map<String, dynamic>.from(raw),
          );
          if (explicitTemplateId != null && explicitTemplateId.isNotEmpty) {
            return loaded.copyWith(templateId: explicitTemplateId);
          }
          return loaded;
        }
      }
    } catch (e) {
      debugPrint('PdfService config load fallback: $e');
    }

    final id =
        explicitTemplateId ??
        (profile.invoiceTemplate.isNotEmpty
            ? profile.invoiceTemplate
            : 'minimal_clean');
    return InvoiceTemplateConfig(templateId: id);
  }

  /// Central rendering flow:
  /// Resolves template from registry, loads offline font and image assets,
  /// applies saved appearance configuration, and generates the PDF document.
  static Future<Uint8List> generateInvoicePdf(
    Invoice invoice,
    BusinessProfile profile, {
    String? templateId,
    InvoiceTemplateConfig? config,
  }) async {
    // 1. Resolve configuration
    InvoiceTemplateConfig effectiveConfig =
        config ?? _loadSavedConfig(profile, templateId);
    if (templateId != null && templateId.isNotEmpty) {
      effectiveConfig = effectiveConfig.copyWith(templateId: templateId);
    }

    // 2. Resolve template from registry (with backward compatibility fallback)
    final template = InvoiceTemplateRegistry.getTemplate(
      effectiveConfig.templateId,
    );

    // 3. Load bundled font assets for offline rendering
    pw.Font? regularFont;
    pw.Font? boldFont;
    try {
      final regData = await rootBundle.load(
        'assets/fonts/Inter/Inter-Regular.ttf',
      );
      regularFont = pw.Font.ttf(regData);
      final boldData = await rootBundle.load(
        'assets/fonts/Inter/Inter-Bold.ttf',
      );
      boldFont = pw.Font.ttf(boldData);
    } catch (e) {
      debugPrint('Font load fallback: $e');
    }

    final pdf = pw.Document(
      theme: regularFont != null && boldFont != null
          ? pw.ThemeData.withFont(base: regularFont, bold: boldFont)
          : null,
    );

    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 2,
    );

    // 4. Load offline logo safely
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

    // 5. Load offline signature safely
    pw.MemoryImage? signatureImage;
    if (!kIsWeb &&
        profile.signatureUrl != null &&
        profile.signatureUrl!.isNotEmpty) {
      try {
        final file = File(profile.signatureUrl!);
        if (file.existsSync()) {
          signatureImage = pw.MemoryImage(file.readAsBytesSync());
        }
      } catch (e) {
        debugPrint('Signature load error: $e');
      }
    }

    // 6. Build Render Context
    final renderContext = TemplateRenderContext(
      invoice: invoice,
      profile: profile,
      config: effectiveConfig,
      regularFont: regularFont,
      boldFont: boldFont,
      logoImage: logoImage,
      signatureImage: signatureImage,
      currencyFormat: currencyFormat,
    );

    // 7. Render Template Page
    template.buildPage(pdf, renderContext);

    return pdf.save();
  }

  /// Prints an invoice using the saved profile template.
  static Future<void> printInvoice(
    Invoice invoice,
    BusinessProfile profile, {
    String? templateId,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      invoice,
      profile,
      templateId: templateId,
    );
    await Printing.layoutPdf(
      onLayout: (pdf_lib.PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  /// Shares an invoice using the saved profile template.
  static Future<void> shareInvoice(
    Invoice invoice,
    BusinessProfile profile, {
    String? templateId,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      invoice,
      profile,
      templateId: templateId,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }
}
