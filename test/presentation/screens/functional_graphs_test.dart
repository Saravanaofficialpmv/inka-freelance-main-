import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/data/models/client.dart';
import 'package:inka/data/models/expense.dart';
import 'package:inka/data/models/invoice.dart';
import 'package:inka/data/models/invoice_item.dart';
import 'package:inka/presentation/providers/auth_provider.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/screens/dashboard_screen.dart';
import 'package:inka/presentation/screens/expenses_screen.dart';
import 'package:inka/presentation/providers/client_provider.dart';
import 'package:inka/presentation/viewmodels/expense_viewmodel.dart';
import 'package:inka/presentation/viewmodels/invoice_viewmodel.dart';

class FakeAuthNotifier extends StateNotifier<AsyncValue<User?>> implements AuthNotifier {
  FakeAuthNotifier([User? initialUser]) : super(AsyncValue.data(initialUser));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeClientsNotifier extends StateNotifier<List<Client>> implements ClientsNotifier {
  FakeClientsNotifier([List<Client>? clients]) : super(clients ?? []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
      : super(
          profile ??
              BusinessProfile.empty().copyWith(
                businessName: 'Inka Studio',
                currency: 'INR',
              ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sampleClient = Client(
    id: 'c1',
    name: 'Client Alpha',
    phone: '9876543210',
    email: 'alpha@example.com',
    address: 'Bangalore, India',
  );

  final sampleInvoices = [
    Invoice(
      id: 'inv-1',
      invoiceNumber: 'INV-001',
      client: sampleClient,
      items: [
        InvoiceItem(id: 'item-1', name: 'UI Design Service', price: 2200.0, quantity: 1),
      ],
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 7)),
      taxPercentage: 0.0,
      discount: 0.0,
      status: 'pending',
    ),
  ];

  final sampleExpenses = [
    Expense(
      id: 'exp-1',
      title: 'Figma Subscription',
      amount: 450.0,
      category: 'Software',
      date: DateTime.now(),
      paymentMethod: 'UPI',
    ),
  ];

  group('Expenses Screen - Functional Performance Curve Chart Tests', () {
    testWidgets('renders ExpensesScreen with functional curve chart card and data', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseProvider.overrideWith((ref) => FakeExpenseNotifier(sampleExpenses)),
            invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier(sampleInvoices)),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ExpensesScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Overview section and chart elements
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);

      // Verify Timeframe selector button exists
      expect(find.text('Monthly'), findsWidgets);

      // Verify CustomPaint with chart exists
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('timeframe menu opens and allows switching timeframe to Weekly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseProvider.overrideWith((ref) => FakeExpenseNotifier(sampleExpenses)),
            invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier(sampleInvoices)),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ExpensesScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap timeframe popup button
      final monthlyBtn = find.text('Monthly').first;
      await tester.tap(monthlyBtn);
      await tester.pumpAndSettle();

      // Verify menu options
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);

      // Select 'Weekly'
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      // Verify updated timeframe button
      expect(find.text('Weekly'), findsWidgets);
    });
  });

  group('Dashboard Screen - Functional Mini Graphics Tests', () {
    testWidgets('dashboard displays 7-day revenue bars and dot matrix with real data', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
            clientsProvider.overrideWith((ref) => FakeClientsNotifier([sampleClient])),
            expenseProvider.overrideWith((ref) => FakeExpenseNotifier(sampleExpenses)),
            invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier(sampleInvoices)),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Total Revenue and Pending Payments cards are present
      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('Pending Payments'), findsOneWidget);

      // Verify Today's Insight card is present and functional
      expect(find.text("Today's Insight"), findsOneWidget);
      expect(find.text("View statistics"), findsOneWidget);
      expect(find.text("Create new invoice"), findsOneWidget);

      // Verify Tooltips on interactive elements
      final tooltips = find.byType(Tooltip);
      expect(tooltips, findsWidgets);
    });
  });
}
