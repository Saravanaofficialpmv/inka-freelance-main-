import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/data/models/client.dart';
import 'package:inka/data/models/invoice.dart';
import 'package:inka/data/models/invoice_item.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/providers/auth_provider.dart';
import 'package:inka/presentation/providers/client_provider.dart';
import 'package:inka/presentation/viewmodels/invoice_viewmodel.dart';
import 'package:inka/presentation/widgets/nav_shell.dart';
import 'package:inka/presentation/screens/dashboard_screen.dart';

class FakeAuthNotifier extends StateNotifier<AsyncValue<User?>> implements AuthNotifier {
  FakeAuthNotifier() : super(const AsyncValue.data(null));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier() : super(BusinessProfile.empty().copyWith(businessName: 'saravana pmv'));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeInvoiceNotifier extends StateNotifier<List<Invoice>> implements InvoiceNotifier {
  FakeInvoiceNotifier([List<Invoice>? list]) : super(list ?? []);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeClientsNotifier extends StateNotifier<List<Client>> implements ClientsNotifier {
  FakeClientsNotifier() : super([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Fullscreen Desktop Dashboard & NavShell Tests', () {
    testWidgets('Populated invoices on 1920x1080 fullscreen desktop', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          ShellRoute(
            builder: (context, state, child) => NavShell(state: state, child: child),
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
            invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier([
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
            ])),
            clientsProvider.overrideWith((ref) => FakeClientsNotifier()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jump back to recents'), findsOneWidget);
      expect(find.text('#INV-2024-001'), findsOneWidget);
      expect(find.text('ACTIONS'), findsOneWidget);
    });

    testWidgets('Empty invoice state on 1920x1080 fullscreen desktop', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          ShellRoute(
            builder: (context, state, child) => NavShell(state: state, child: child),
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
            invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier([])),
            clientsProvider.overrideWith((ref) => FakeClientsNotifier()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start something new'), findsOneWidget);
      expect(find.text('Blank invoice'), findsOneWidget);
      expect(find.text('No invoices created yet'), findsOneWidget);
    });

    testWidgets('Navigating to root "/" redirects to "/dashboard" smoothly', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          ShellRoute(
            builder: (context, state, child) => NavShell(state: state, child: child),
            routes: [
              GoRoute(
                path: '/',
                redirect: (context, state) => '/dashboard',
              ),
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
            invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier([])),
            clientsProvider.overrideWith((ref) => FakeClientsNotifier()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start something new'), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
    });
  });
}
