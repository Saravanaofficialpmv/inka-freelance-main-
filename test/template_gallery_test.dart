import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/data/models/client.dart';
import 'package:inka/data/models/invoice.dart';
import 'package:inka/data/models/invoice_item.dart';
import 'package:inka/features/invoices/templates/invoice_template_registry.dart';
import 'package:inka/presentation/widgets/template_generated_preview.dart';
import 'package:inka/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Template Showcase & PDF Service Tests', () {
    test('PdfService contains all 14 reference showcase templates', () {
      expect(PdfService.availableTemplates.length, 14);

      final expectedTemplateIds = [
        'template_billto_shipto',
        'template_classic',
        'template_compact',
        'template_elegant',
        'template_elegant_images',
        'template_evergreen',
        'template_genz',
        'template_legend',
        'template_modern',
        'template_mrp_discount',
        'template_professional',
        'template_service',
        'template_service_2',
        'template_vintage',
      ];

      for (final id in expectedTemplateIds) {
        final match = PdfService.availableTemplates.any((t) => t.id == id);
        expect(
          match,
          isTrue,
          reason: 'Template with id $id should exist in availableTemplates',
        );
      }
    });

    test(
      'All 14 templates have non-empty metadata and valid asset previews',
      () {
        for (final template in PdfService.availableTemplates) {
          expect(template.id, isNotEmpty);
          expect(template.name, isNotEmpty);
          expect(template.tag, isNotEmpty);
          expect(template.primaryColorHex, startsWith('#'));
          expect(template.assetPreview, startsWith('assets/templates/'));

          // Verify file exists on disk
          final file = File(template.assetPreview);
          expect(
            file.existsSync(),
            isTrue,
            reason: 'Asset ${template.assetPreview} must exist on disk',
          );
        }
      },
    );

    test(
      'generateInvoicePdf generates valid PDF bytes for all 14 templates',
      () async {
        final sampleInvoice = Invoice(
          id: 'inv-test-1',
          invoiceNumber: '001',
          client: Client(
            id: 'c-1',
            name: 'Suri Padmanas',
            email: 'suri@test.com',
            phone: '+91 9898765432',
            address: 'Floor 2nd, Santa Street 205, Haryana',
          ),
          items: [
            InvoiceItem(
              id: 'i-1',
              name: 'Pixel Watch 3',
              quantity: 2,
              price: 21016.95,
            ),
            InvoiceItem(
              id: 'i-2',
              name: 'Pixel 9 Pro 256GB',
              quantity: 1,
              price: 97457.63,
            ),
          ],
          issueDate: DateTime(2026, 9, 2),
          dueDate: DateTime(2026, 9, 16),
          taxPercentage: 18.0,
          discount: 500.0,
        );

        final profile = BusinessProfile(
          businessName: 'Alphabet Inc.',
          email: 'help@google.com',
          phone: '+91 9995556661',
          address: 'Google India Pvt. Ltd Tower Z, Gurugram, Haryana',
          currency: 'INR',
          gstNumber: '06CCD3456FFDC22',
          accountNo: '372044759793571',
          bankName: 'ICICI Limited',
          ifscCode: 'ICIC0000168',
          upiId: 'help@icici',
        );

        for (final template in PdfService.availableTemplates) {
          final pdfBytes = await PdfService.generateInvoicePdf(
            sampleInvoice,
            profile,
            templateId: template.id,
          );
          expect(pdfBytes, isNotNull);
          expect(
            pdfBytes.length,
            greaterThan(1000),
            reason:
                'Template ${template.id} should generate a valid PDF byte array',
          );
        }
      },
    );

    test(
      'Legacy template IDs gracefully resolve to valid registered templates',
      () async {
        final legacyIds = [
          'modern',
          'professional',
          'billto_shipto',
          'legend',
          'service_2',
          'compact',
          'evergreen',
          'classic',
          'elegant_images',
          'service',
          'vintage',
          'elegant',
          'mrp_discount',
          'genz',
          'unknown_random_id',
        ];

        for (final id in legacyIds) {
          final template = InvoiceTemplateRegistry.getTemplate(id);
          expect(template, isNotNull);
          expect(template.id, isNotEmpty);
        }
      },
    );

    testWidgets('TemplateGeneratedPreview renders all 14 templates without error', (tester) async {
      for (final template in PdfService.availableTemplates) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TemplateGeneratedPreview(
                templateId: template.id,
                isZoomed: false,
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'Unzoomed template ${template.id} threw an error');

        // Also test zoomed preview state
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TemplateGeneratedPreview(
                templateId: template.id,
                isZoomed: true,
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'Zoomed template ${template.id} threw an error');
      }
    });
  });
}
