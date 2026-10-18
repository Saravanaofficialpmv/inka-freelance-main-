import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/data/models/client.dart';
import 'package:inka/data/models/invoice.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/providers/auth_provider.dart';
import 'package:inka/presentation/providers/client_provider.dart';
import 'package:inka/presentation/viewmodels/invoice_viewmodel.dart';
import 'package:inka/presentation/widgets/web_sidebar.dart';
import 'package:inka/presentation/widgets/nav_shell.dart';
import 'package:inka/presentation/screens/dashboard_screen.dart';

class FakeAuthNotifier extends StateNotifier<AsyncValue<User?>> implements AuthNotifier {
  FakeAuthNotifier([User? initialUser]) : super(AsyncValue.data(initialUser));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier([BusinessProfile? profile])
      : super(profile ?? BusinessProfile.empty().copyWith(businessName: 'saravana'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeInvoiceNotifier extends StateNotifier<List<Invoice>> implements InvoiceNotifier {
  FakeInvoiceNotifier([List<Invoice>? invoices]) : super(invoices ?? []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeClientsNotifier extends StateNotifier<List<Client>> implements ClientsNotifier {
  FakeClientsNotifier([List<Client>? clients]) : super(clients ?? []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Web Desktop Miro-Inspired Layout Tests', () {
    testWidgets('WebSidebar renders Miro-style elements on desktop', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 562);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
            invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier([])),
            clientsProvider.overrideWith((ref) => FakeClientsNotifier([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WebSidebar(
                currentLocation: '/dashboard',
                currentIndex: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Sidebar team header & user footer
      expect(find.text('saravana'), findsWidgets);

      // 2. Search pill
      expect(find.textContaining('Search'), findsOneWidget);

      // 3. Navigation items
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Starred'), findsOneWidget);
      expect(find.text('Browse'), findsOneWidget);

      // 4. Spaces section
      expect(find.text('Spaces'), findsOneWidget);
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text('Clients'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Expenses & Stats'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('NavShell top canvas bar renders brand, plan pill, CTA and icons', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 562);
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
            clientsProvider.overrideWith((ref) => FakeClientsNotifier([])),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Brand
      expect(find.text('inka'), findsOneWidget);

      // Plan pill
      expect(find.text('Free plan'), findsWidgets);

      // Actions
      expect(find.text('Invite members'), findsOneWidget);
      expect(find.text('Create Invoice'), findsOneWidget);
    });

    testWidgets('DashboardScreen renders Miro editorial greeting, card deck, and recents table on desktop', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 562);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
            invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier([])),
            clientsProvider.overrideWith((ref) => FakeClientsNotifier([])),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Editorial Hero greeting
      expect(find.textContaining('saravana'), findsWidgets);

      // "Start something new" section
      expect(find.text('Start something new'), findsOneWidget);
      expect(find.text('Blank invoice'), findsOneWidget);
      expect(find.text('Consulting Invoice'), findsOneWidget);
      expect(find.text('Design & Creative'), findsOneWidget);
      expect(find.text('Software Dev'), findsOneWidget);

      // "Jump back to recents" section
      expect(find.text('Jump back to recents'), findsOneWidget);
    });
  });
}
