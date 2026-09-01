import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/client.dart';
import 'package:inka/data/models/invoice.dart';
import 'package:inka/data/models/invoice_item.dart';
import 'package:inka/presentation/viewmodels/invoice_viewmodel.dart';

void main() {
  group('Recurring Invoice & Retainer Tests', () {
    final client = Client(
      id: 'c1',
      name: 'Tech Innovators Inc',
      phone: '+1 555 456 7890',
      email: 'tech@innovators.com',
      address: '742 Evergreen Terrace',
    );

    test('calculateNextRecurringDate calculates weekly, monthly, quarterly, yearly correctly', () {
      final baseDate = DateTime(2024, 1, 15);

      final weeklyDate = InvoiceNotifier.calculateNextRecurringDate(baseDate, 'weekly');
      expect(weeklyDate, equals(DateTime(2024, 1, 22)));

      final monthlyDate = InvoiceNotifier.calculateNextRecurringDate(baseDate, 'monthly');
      expect(monthlyDate, equals(DateTime(2024, 2, 15)));

      final quarterlyDate = InvoiceNotifier.calculateNextRecurringDate(baseDate, 'quarterly');
      expect(quarterlyDate, equals(DateTime(2024, 4, 15)));

      final yearlyDate = InvoiceNotifier.calculateNextRecurringDate(baseDate, 'yearly');
      expect(yearlyDate, equals(DateTime(2025, 1, 15)));
    });

    test('Invoice model serialization preserves recurring parameters', () {
      final invoice = Invoice(
        id: 'inv_rec_1',
        invoiceNumber: 'INV-2024-042',
        client: client,
        items: [
          InvoiceItem(id: 'it1', name: 'Monthly SEO Retainer', quantity: 1, price: 1200.0),
        ],
        issueDate: DateTime(2024, 1, 1),
        dueDate: DateTime(2024, 1, 15),
        isRecurring: true,
        recurringInterval: 'monthly',
        nextRecurringDate: DateTime(2024, 2, 1),
      );

      final map = invoice.toMap();
      expect(map['isRecurring'], isTrue);
      expect(map['recurringInterval'], equals('monthly'));
      expect(map['nextRecurringDate'], equals(DateTime(2024, 2, 1).millisecondsSinceEpoch));

      final deserialized = Invoice.fromMap(map);
      expect(deserialized.isRecurring, isTrue);
      expect(deserialized.recurringInterval, equals('monthly'));
      expect(deserialized.nextRecurringDate, equals(DateTime(2024, 2, 1)));
      expect(deserialized.total, equals(1200.0));
    });
  });
}
