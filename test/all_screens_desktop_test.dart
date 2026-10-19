import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:go_router/go_router.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/data/models/client.dart';
import 'package:inka/data/models/invoice.dart';
import 'package:inka/data/models/invoice_item.dart';
import 'package:inka/data/models/product.dart';
import 'package:inka/data/models/expense.dart';
import 'package:inka/data/models/project.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/providers/auth_provider.dart';
import 'package:inka/presentation/providers/client_provider.dart';
import 'package:inka/presentation/providers/product_provider.dart';
import 'package:inka/presentation/viewmodels/invoice_viewmodel.dart';
import 'package:inka/presentation/viewmodels/expense_viewmodel.dart';
import 'package:inka/presentation/viewmodels/project_viewmodel.dart';
import 'package:inka/presentation/screens/dashboard_screen.dart';
import 'package:inka/presentation/screens/profile_screen.dart';
import 'package:inka/presentation/screens/clients_screen.dart';
import 'package:inka/presentation/screens/invoices_history_screen.dart';
import 'package:inka/presentation/screens/expenses_screen.dart';
import 'package:inka/presentation/screens/products_screen.dart';
import 'package:inka/presentation/screens/subscription_screen.dart';
import 'package:inka/presentation/widgets/nav_shell.dart';

class FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final String? photoURL;

  FakeUser({
    this.uid = 'u123',
    this.email = 'saravanapmofficial@gmail.com',
    this.displayName = 'Saravana Pmv',
    this.photoURL,
  });
}

class FakeAuthNotifier extends StateNotifier<AsyncValue<User?>> implements AuthNotifier {
  FakeAuthNotifier([User? user]) : super(AsyncValue.data(user));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier() : super(BusinessProfile.empty().copyWith(businessName: 'saravana pmv'));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeInvoiceNotifier extends StateNotifier<List<Invoice>> implements InvoiceNotifier {
  FakeInvoiceNotifier() : super([
    Invoice(
      id: 'inv1',
      invoiceNumber: 'INV-2024-001',
      client: Client(id: 'c1', name: 'Google LLC', email: 'billing@google.com', address: 'Mountain View', phone: '+1234567890'),
      items: [
        InvoiceItem(id: 'i1', name: 'UI/UX Design', quantity: 2, price: 500.0),
      ],
      issueDate: DateTime.now().subtract(const Duration(days: 2)),
      dueDate: DateTime.now().add(const Duration(days: 10)),
      taxPercentage: 10.0,
      discount: 50.0,
      status: 'pending',
    ),
  ]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeClientsNotifier extends StateNotifier<List<Client>> implements ClientsNotifier {
  FakeClientsNotifier() : super([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProductsNotifier extends StateNotifier<List<Product>> implements ProductsNotifier {
  FakeProductsNotifier() : super([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeExpenseNotifier extends StateNotifier<List<Expense>> implements ExpenseNotifier {
  FakeExpenseNotifier() : super([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProjectNotifier extends StateNotifier<List<Project>> implements ProjectNotifier {
  FakeProjectNotifier() : super([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final user = FakeUser();
  final overrides = [
    authProvider.overrideWith((ref) => FakeAuthNotifier(user)),
    profileProvider.overrideWith((ref) => FakeProfileNotifier()),
    invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier()),
    clientsProvider.overrideWith((ref) => FakeClientsNotifier()),
    productsProvider.overrideWith((ref) => FakeProductsNotifier()),
    expenseProvider.overrideWith((ref) => FakeExpenseNotifier()),
    projectProvider.overrideWith((ref) => FakeProjectNotifier()),
  ];

  GoRouter createTestRouter(String initialLocation) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        ShellRoute(
          builder: (context, state, child) => NavShell(state: state, child: child),
          routes: [
            GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
            GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
            GoRoute(path: '/settings', redirect: (c, s) => '/profile'),
            GoRoute(path: '/clients', builder: (c, s) => const ClientsScreen()),
            GoRoute(path: '/history', builder: (c, s) => const InvoicesHistoryScreen()),
            GoRoute(path: '/expenses', builder: (c, s) => const ExpensesScreen()),
            GoRoute(path: '/products', builder: (c, s) => const ProductsScreen()),
            GoRoute(path: '/subscription', builder: (c, s) => const SubscriptionScreen()),
          ],
        ),
      ],
    );
  }

  group('All Desktop Screens In NavShell Test with Logged In User', () {
    for (final route in ['/dashboard', '/settings', '/clients', '/history', '/expenses', '/products', '/subscription']) {
      testWidgets('Screen for route "$route" renders cleanly without error in NavShell', (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final router = createTestRouter(route);
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Something went wrong'), findsNothing);

        if (route == '/settings') {
          expect(find.text('Profile Completed'), findsOneWidget);
          expect(find.text('Company Details'), findsOneWidget);
          expect(find.text('Document Settings'), findsOneWidget);
          expect(find.text('Currency'), findsOneWidget);
        } else if (route == '/dashboard') {
          expect(find.text('Total Revenue'), findsOneWidget);
          expect(find.text('Pending Payments'), findsOneWidget);
          expect(find.text('Start something new'), findsOneWidget);
          expect(find.text('Blank invoice'), findsOneWidget);
        }
      });
    }
  });
}
