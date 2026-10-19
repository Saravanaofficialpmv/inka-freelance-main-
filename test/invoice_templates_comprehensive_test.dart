import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/data/models/client.dart';
import 'package:inka/data/models/invoice.dart';
import 'package:inka/data/models/invoice_item.dart';
import 'package:inka/features/invoices/templates/invoice_template.dart';
import 'package:inka/features/invoices/templates/invoice_template_config.dart';
import 'package:inka/features/invoices/templates/invoice_template_registry.dart';
import 'package:inka/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleClient = Client(
    id: 'cli_001',
    name: 'Acme Global Innovations Pvt Ltd',
    email: 'billing@acmeglobal.com',
    phone: '+91 98765 43210',
    address: 'Suite 404, Tech Park Boulevard, Indiranagar, Bangalore, KA 560038',
  );

  final sampleProfile = BusinessProfile.empty().copyWith(
    businessName: 'Inka Creative & Technology Studio',
    email: 'hello@inkastudio.dev',
    phone: '+91 91234 56789',
    address: '42 Innovation Highway, Cyber City, Hyderabad, TG 500081',
    taxLabel: 'GSTIN',
    gstNumber: '36AAAAA0000A1Z5',
    upiId: 'inkastudio@oksbi',
    bankName: 'HDFC Bank Ltd',
    accountNo: '50100234567890',
    ifscCode: 'HDFC0001234',
    accountHolderName: 'Inka Creative Studio Pvt Ltd',
    currency: 'INR',
    defaultTaxRate: 18.0,
    invoiceTemplate: 'minimal_clean',
  );

  Invoice buildTestInvoice({
    required String id,
    required List<InvoiceItem> items,
    double discount = 0,
    double taxPercentage = 18.0,
  }) {
    return Invoice(
      id: id,
      invoiceNumber: 'INV-2026-0042',
      client: sampleClient,
      items: items,
      issueDate: DateTime(2026, 10, 15),
      dueDate: DateTime(2026, 10, 30),
      discount: discount,
      taxPercentage: taxPercentage,
      status: 'pending',
      notes: 'Thank you for partnering with us. Please make payments before the due date.',
    );
  }

  group('Phase 1 & 2: InvoiceTemplateRegistry & Config Integrity', () {
    test('Registry contains all 10 distinct showcase templates', () {
      final templates = InvoiceTemplateRegistry.allTemplates;
      expect(templates.length, equals(10));

      final expectedIds = [
        'minimal_clean',
        'modern_professional',
        'elegant_premium',
        'creative_modern',
        'professional_classic',
        'dark_theme',
        'retail_shop',
        'service_consultancy',
        'compact_thermal',
        'branded_custom',
      ];

      for (final id in expectedIds) {
        final t = InvoiceTemplateRegistry.getTemplate(id);
        expect(t.id, equals(id));
        expect(t.name.isNotEmpty, isTrue);
        expect(t.description.isNotEmpty, isTrue);
        expect(t.assetPreview.isNotEmpty, isTrue);
      }
    });

    test('Registry falls back gracefully for unknown or legacy template IDs', () {
      expect(InvoiceTemplateRegistry.getTemplate('unknown_id').id, equals('minimal_clean'));
      expect(InvoiceTemplateRegistry.getTemplate('').id, equals('minimal_clean'));
      expect(InvoiceTemplateRegistry.getTemplate('classic').id, equals('professional_classic'));
      expect(InvoiceTemplateRegistry.getTemplate('modern').id, equals('modern_professional'));
      expect(InvoiceTemplateRegistry.getTemplate('vintage').id, equals('professional_classic'));
    });

    test('InvoiceTemplateConfig serialization, copyWith, and equality', () {
      const config = InvoiceTemplateConfig(
        templateId: 'elegant_premium',
        accentColorHex: '#1B365D',
        density: InvoiceDensity.spacious,
        pageFormat: InvoicePageFormatType.a4,
        showLogo: true,
        showSignature: false,
        showQrCode: true,
        showBankDetails: true,
        showContactDetails: false,
        showNotesAndTerms: true,
      );

      final map = config.toMap();
      final restored = InvoiceTemplateConfig.fromMap(map);

      expect(restored.templateId, equals('elegant_premium'));
      expect(restored.accentColorHex, equals('#1B365D'));
      expect(restored.density, equals(InvoiceDensity.spacious));
      expect(restored.pageFormat, equals(InvoicePageFormatType.a4));
      expect(restored.showSignature, isFalse);
      expect(restored.showContactDetails, isFalse);
      expect(restored, equals(config));

      final modified = config.copyWith(density: InvoiceDensity.compact);
      expect(modified.density, equals(InvoiceDensity.compact));
      expect(modified == config, isFalse);
    });
  });

  group('Phase 3 & 4: Multi-Template PDF Rendering & Financial Parity', () {
    final standardItems = [
      InvoiceItem(id: 'i1', name: 'Cloud Architecture & Flutter Engineering', quantity: 40, price: 2500.0),
      InvoiceItem(id: 'i2', name: 'UI/UX Design Systems & Motion Prototypes', quantity: 20, price: 1800.0),
      InvoiceItem(id: 'i3', name: 'Security Audit & Compliance Review', quantity: 1, price: 15000.0),
    ];

    final standardInvoice = buildTestInvoice(
      id: 'inv_std',
      items: standardItems,
      discount: 5000.0,
      taxPercentage: 18.0,
    );

    test('Financial calculations in Invoice model are accurate', () {
      // Subtotal: (40*2500) + (20*1800) + (1*15000) = 100000 + 36000 + 15000 = 151,000
      expect(standardInvoice.subtotal, equals(151000.0));
      // Inka model formula: taxAmount = subtotal * (taxPercentage / 100) = 151000 * 0.18 = 27180.0
      expect(standardInvoice.taxAmount, equals(27180.0));
      // Inka model formula: total = subtotal + taxAmount - discount = 151000 + 27180 - 5000 = 173180.0
      expect(standardInvoice.total, equals(173180.0));
    });

    for (final template in InvoiceTemplateRegistry.allTemplates) {
      test('Template "${template.name}" [${template.id}] renders valid PDF with standard invoice', () async {
        final pdfBytes = await PdfService.generateInvoicePdf(
          standardInvoice,
          sampleProfile,
          templateId: template.id,
        );

        expect(pdfBytes.isNotEmpty, isTrue);
        expect(pdfBytes.length, greaterThan(1000));
        // Check standard PDF file header '%PDF-'
        final header = String.fromCharCodes(pdfBytes.take(5));
        expect(header, equals('%PDF-'));
      });

      test('Template "${template.name}" renders cleanly with empty line items without crash', () async {
        final emptyInvoice = buildTestInvoice(id: 'inv_empty', items: []);
        final pdfBytes = await PdfService.generateInvoicePdf(
          emptyInvoice,
          sampleProfile,
          templateId: template.id,
        );
        expect(pdfBytes.isNotEmpty, isTrue);
      });

      test('Template "${template.name}" handles missing profile information safely', () async {
        final bareProfile = BusinessProfile.empty().copyWith(
          businessName: 'Bare Bones Corp',
          currency: 'USD',
        );

        final pdfBytes = await PdfService.generateInvoicePdf(
          standardInvoice,
          bareProfile,
          templateId: template.id,
        );
        expect(pdfBytes.isNotEmpty, isTrue);
      });
    }

    test('Template 09 (compact_thermal) renders in both A4 and 80mm roll format', () async {
      // A4 format
      final bytesA4 = await PdfService.generateInvoicePdf(
        standardInvoice,
        sampleProfile,
        templateId: 'compact_thermal',
        config: const InvoiceTemplateConfig(
          templateId: 'compact_thermal',
          pageFormat: InvoicePageFormatType.a4,
        ),
      );
      expect(bytesA4.isNotEmpty, isTrue);

      // 80mm roll format
      final bytesRoll = await PdfService.generateInvoicePdf(
        standardInvoice,
        sampleProfile,
        templateId: 'compact_thermal',
        config: const InvoiceTemplateConfig(
          templateId: 'compact_thermal',
          pageFormat: InvoicePageFormatType.thermalRoll,
        ),
      );
      expect(bytesRoll.isNotEmpty, isTrue);
    });

    test('Multi-page invoice (28 items) renders across continuation pages without error', () async {
      final longItems = List.generate(
        28,
        (i) => InvoiceItem(
          id: 'item_$i',
          name: 'Professional Consulting Line Item #${i + 1} with detailed project scope description',
          quantity: i + 1,
          price: 100.0 * (i + 1),
        ),
      );

      final multiPageInvoice = buildTestInvoice(id: 'inv_multipage', items: longItems);

      for (final template in InvoiceTemplateRegistry.allTemplates) {
        final pdfBytes = await PdfService.generateInvoicePdf(
          multiPageInvoice,
          sampleProfile,
          templateId: template.id,
        );
        expect(pdfBytes.isNotEmpty, isTrue);
        expect(pdfBytes.length, greaterThan(2000));
      }
    });

    test('PdfSharedComponents numberToWords helper renders correctly', () {
      expect(PdfSharedComponents.numberToWords(0), equals('Zero'));
      expect(PdfSharedComponents.numberToWords(100), equals('One Hundred'));
      expect(PdfSharedComponents.numberToWords(1500), equals('One Thousand Five Hundred'));
      expect(PdfSharedComponents.numberToWords(100000), equals('One Hundred Thousand'));
    });
  });
}
