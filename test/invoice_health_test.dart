import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/data/models/client.dart';
import 'package:inka/data/models/invoice.dart';
import 'package:inka/data/models/invoice_item.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/viewmodels/invoice_viewmodel.dart';
import 'package:inka/presentation/screens/invoices_history_screen.dart';

class FakeInvoiceNotifier extends StateNotifier<List<Invoice>> implements InvoiceNotifier {
  FakeInvoiceNotifier([List<Invoice>? list]) : super(list ?? []);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier() : super(BusinessProfile.empty().copyWith(businessName: 'Freelancer Pro', currency: 'USD'));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Invoice _createTestInvoice({
  required String id,
  required String number,
  required String clientName,
  required double total,
  required String status,
  required DateTime dueDate,
}) {
  return Invoice(
    id: id,
    invoiceNumber: number,
    issueDate: DateTime(2026, 1, 1),
    dueDate: dueDate,
    client: Client(
      id: 'c_$id',
      name: clientName,
      email: '$clientName@example.com',
      phone: '+1234567890',
      address: '123 Main St',
    ),
    items: [
      InvoiceItem(
        id: 'item_$id',
        name: 'Design & Code Services',
        quantity: 1,
        price: total,
      ),
    ],
    status: status,
  );
}

void main() {
  group('InvoiceHealthData Calculation Tests', () {
    final now = DateTime(2026, 6, 1);

    test('Empty invoice list defaults to 100 score, Great tier, 8 active pills', () {
      final health = InvoiceHealthData.calculate([], now: now);
      expect(health.score, 100);
      expect(health.tier, 'Great');
      expect(health.numActivePills, 8);
      expect(health.paidAmount, 0.0);
      expect(health.overdueAmount, 0.0);
      expect(health.pendingAmount, 0.0);
    });

    test('All paid invoices results in 100 score, Great tier, 8 active pills', () {
      final invoices = [
        _createTestInvoice(
          id: '1',
          number: '101',
          clientName: 'Alice',
          total: 1000.0,
          status: 'paid',
          dueDate: DateTime(2026, 5, 1),
        ),
        _createTestInvoice(
          id: '2',
          number: '102',
          clientName: 'Bob',
          total: 2000.0,
          status: 'paid',
          dueDate: DateTime(2026, 5, 15),
        ),
      ];

      final health = InvoiceHealthData.calculate(invoices, now: now);
      expect(health.score, 100);
      expect(health.tier, 'Great');
      expect(health.numActivePills, 8);
      expect(health.paidAmount, 3000.0);
      expect(health.overdueAmount, 0.0);
      expect(health.pendingAmount, 0.0);
    });

    test('Pending invoice within due date gives healthy score (85)', () {
      final invoices = [
        _createTestInvoice(
          id: '3',
          number: '103',
          clientName: 'Charlie',
          total: 1500.0,
          status: 'pending',
          dueDate: DateTime(2026, 6, 15), // Future due date
        ),
      ];

      final health = InvoiceHealthData.calculate(invoices, now: now);
      expect(health.score, 85);
      expect(health.tier, 'Great');
      expect(health.numActivePills, 7);
      expect(health.pendingInvoices.length, 1);
      expect(health.overdueInvoices.length, 0);
    });

    test('Overdue invoice heavily penalises health score and drops tier', () {
      final invoices = [
        _createTestInvoice(
          id: '4',
          number: '104',
          clientName: 'Dave',
          total: 2000.0,
          status: 'overdue',
          dueDate: DateTime(2026, 5, 1), // Past due date
        ),
      ];

      final health = InvoiceHealthData.calculate(invoices, now: now);
      expect(health.score, 20);
      expect(health.tier, 'Bad');
      expect(health.numActivePills, 2);
      expect(health.overdueInvoices.length, 1);
      expect(health.overdueAmount, 2000.0);
    });

    test('Mixed portfolio (50% paid, 50% overdue) calculates warning tier', () {
      final invoices = [
        _createTestInvoice(
          id: '5',
          number: '105',
          clientName: 'Eve',
          total: 1000.0,
          status: 'paid',
          dueDate: DateTime(2026, 4, 1),
        ),
        _createTestInvoice(
          id: '6',
          number: '106',
          clientName: 'Frank',
          total: 1000.0,
          status: 'overdue',
          dueDate: DateTime(2026, 5, 1),
        ),
      ];

      final health = InvoiceHealthData.calculate(invoices, now: now);
      // 100 - (0.5 * 60) - (0.5 * 20) = 60
      expect(health.score, 60);
      expect(health.tier, 'Warning');
      expect(health.numActivePills, 5);
      expect(health.paidAmount, 1000.0);
      expect(health.overdueAmount, 1000.0);
    });
  });

  group('InvoicesHistoryScreen UI & Health Sheet Tests', () {
    testWidgets('Renders Invoice Health Card, score, and opens Advice Sheet on tap', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testInvoices = [
        _createTestInvoice(
          id: 'inv_1',
          number: 'INV-001',
          clientName: 'Acme Corp',
          total: 500.0,
          status: 'paid',
          dueDate: DateTime(2026, 5, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier(testInvoices)),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
          ],
          child: const MaterialApp(
            home: InvoicesHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify health card elements
      expect(find.text('Invoice Health'), findsOneWidget);
      expect(find.text('100'), findsAtLeastNWidgets(1));
      expect(find.text('/100'), findsOneWidget);
      expect(find.text('0 Unpaid Invoices'), findsOneWidget);
      expect(find.text('Give me advice'), findsOneWidget);
      expect(find.text('Bad'), findsOneWidget);
      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Great'), findsAtLeastNWidgets(1));

      // Tap 'Give me advice' button
      await tester.tap(find.text('Give me advice'));
      await tester.pumpAndSettle();

      // Verify bottom sheet metrics and advice
      expect(find.text('Paid Revenue'), findsOneWidget);
      expect(find.text('Overdue Dues'), findsOneWidget);
      expect(find.text('Pending Bills'), findsOneWidget);
      expect(find.text('Collection Rate'), findsOneWidget);
      expect(find.text('Include Instant Payment QR'), findsOneWidget);
      expect(find.text('Shorten Payment Terms to 14 Days'), findsOneWidget);
      expect(find.text('Setup QR'), findsOneWidget);
    });

    testWidgets('Shows overdue reminder and actionable tasks when overdue invoices exist', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final overdueInvoice = _createTestInvoice(
        id: 'inv_overdue',
        number: 'INV-999',
        clientName: 'Late Client Ltd',
        total: 1250.0,
        status: 'overdue',
        dueDate: DateTime.now().subtract(const Duration(days: 10)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier([overdueInvoice])),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
          ],
          child: const MaterialApp(
            home: InvoicesHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Card should reflect 1 unpaid invoice
      expect(find.text('1 Unpaid Invoices'), findsOneWidget);

      // Tap anywhere on Invoice Health card
      await tester.tap(find.text('Invoice Health'));
      await tester.pumpAndSettle();

      // Overdue reminder should be displayed with Remind button
      expect(find.text('Remind Late Client Ltd'), findsOneWidget);
      expect(find.text('Remind'), findsOneWidget);
      final filterBtnFinder = find.text('Filter & Review 1 Unpaid Invoices');
      expect(filterBtnFinder, findsOneWidget);

      await tester.ensureVisible(filterBtnFinder);
      await tester.pumpAndSettle();

      // Tapping "Filter & Review 1 Unpaid Invoices" closes sheet and applies filter
      await tester.tap(filterBtnFinder);
      await tester.pumpAndSettle();

      // Bottom sheet is dismissed
      expect(filterBtnFinder, findsNothing);
    });
  });
}
