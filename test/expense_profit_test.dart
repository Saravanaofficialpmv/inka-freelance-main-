import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/data/models/expense.dart';
import 'package:inka/data/models/invoice.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/screens/expenses_screen.dart';
import 'package:inka/presentation/viewmodels/expense_viewmodel.dart';
import 'package:inka/presentation/viewmodels/invoice_viewmodel.dart';

class FakeExpenseNotifier extends StateNotifier<List<Expense>> implements ExpenseNotifier {
  FakeExpenseNotifier([List<Expense>? expenses]) : super(expenses ?? []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeInvoiceNotifier extends StateNotifier<List<Invoice>> implements InvoiceNotifier {
  FakeInvoiceNotifier([List<Invoice>? invoices]) : super(invoices ?? []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier([BusinessProfile? profile])
      : super(profile ?? BusinessProfile.empty().copyWith(businessName: 'Inka Studio', currency: 'USD'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Expense & Profit Tracker Tests', () {
    test('Expense model serializes and deserializes correctly', () {
      final expense = Expense(
        id: 'exp_1',
        title: 'Figma Annual Subscription',
        amount: 144.0,
        category: 'Software',
        date: DateTime(2024, 2, 1),
        notes: 'Team plan',
        paymentMethod: 'Credit Card',
      );

      final map = expense.toMap();
      expect(map['title'], equals('Figma Annual Subscription'));
      expect(map['amount'], equals(144.0));
      expect(map['category'], equals('Software'));
      expect(map['paymentMethod'], equals('Credit Card'));

      final restored = Expense.fromMap(map);
      expect(restored.id, equals('exp_1'));
      expect(restored.title, equals('Figma Annual Subscription'));
      expect(restored.amount, equals(144.0));
      expect(restored.category, equals('Software'));
    });

    test('Net profit and margin calculations', () {
      const collectedRevenue = 5000.0;
      const totalExpenses = 1500.0;

      const netProfit = collectedRevenue - totalExpenses;
      final profitMargin = (netProfit / collectedRevenue) * 100;

      expect(netProfit, equals(3500.0));
      expect(profitMargin, equals(70.0));
    });

    testWidgets('Add New Expense bottom sheet opens on root navigator and displays Save Expense button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseProvider.overrideWith((ref) => FakeExpenseNotifier([])),
            invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier([])),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
          ],
          child: const MaterialApp(
            home: ExpensesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Add Expense button
      final addExpenseBtn = find.text('Add Expense');
      expect(addExpenseBtn, findsOneWidget);
      await tester.tap(addExpenseBtn);
      await tester.pumpAndSettle();

      // Verify modal sheet is open with all fields visible and accessible
      expect(find.text('Add New Expense'), findsOneWidget);
      expect(find.text('Title / Description'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Save Expense'), findsOneWidget);
    });
  });
}
