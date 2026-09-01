import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/data/models/client.dart';
import 'package:inka/data/models/invoice.dart';
import 'package:inka/data/models/invoice_item.dart';
import 'package:inka/services/whatsapp_service.dart';

void main() {
  group('WhatsAppService Tests', () {
    final client = Client(
      id: 'c1',
      name: 'Acme Corp',
      phone: '+1 (555) 123-4567',
      email: 'acme@example.com',
      address: '123 Main St',
    );

    final profile = BusinessProfile(
      businessName: 'Inka Design Studio',
      address: 'San Francisco, CA',
      phone: '+1 (555) 987-6543',
      email: 'hello@inkastudio.com',
      currency: '\$',
      upiId: 'inka@okhdfcbank',
    );

    final invoice = Invoice(
      id: 'inv1',
      invoiceNumber: 'INV-2024-001',
      client: client,
      items: [
        InvoiceItem(id: 'i1', name: 'UI/UX Design', quantity: 2, price: 500.0),
      ],
      issueDate: DateTime(2024, 1, 1),
      dueDate: DateTime(2024, 1, 15),
      taxPercentage: 10.0,
      discount: 50.0,
      status: 'pending',
    );

    test('buildMessage generates New Invoice template correctly', () {
      final msg = WhatsAppService.buildMessage(
        invoice: invoice,
        profile: profile,
        templateType: WhatsAppTemplateType.newInvoice,
      );

      expect(msg, contains('Acme Corp'));
      expect(msg, contains('INV-2024-001'));
      expect(msg, contains('Inka Design Studio'));
      expect(msg, contains('UI/UX Design'));
      expect(msg, contains('inka@okhdfcbank'));
    });

    test('buildMessage generates Overdue Notice template correctly', () {
      final msg = WhatsAppService.buildMessage(
        invoice: invoice,
        profile: profile,
        templateType: WhatsAppTemplateType.overdueNotice,
      );

      expect(msg, contains('Payment Overdue Notice'));
      expect(msg, contains('Acme Corp'));
      expect(msg, contains('INV-2024-001'));
    });

    test('buildMessage generates Payment Receipt template correctly', () {
      final msg = WhatsAppService.buildMessage(
        invoice: invoice,
        profile: profile,
        templateType: WhatsAppTemplateType.paymentReceipt,
      );

      expect(msg, contains('Payment Received - Thank You!'));
      expect(msg, contains('Paid in Full'));
    });
  });
}
