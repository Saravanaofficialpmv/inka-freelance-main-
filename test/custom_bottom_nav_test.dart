import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inka/presentation/widgets/custom_bottom_nav.dart';
import 'package:inka/presentation/widgets/nav_shell.dart';
import 'package:inka/presentation/screens/products_screen.dart';
import 'package:inka/presentation/providers/product_provider.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/data/models/business_profile.dart';

void main() {
  testWidgets('CustomBottomNav renders all 5 tabs and custom nav_icons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomBottomNav(currentIndex: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 5 tab labels are rendered
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('Clients'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify custom nav_icons asset images are loaded
    final imageWidgets = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(imageWidgets.length, 5);

    final assetPaths = imageWidgets
        .map((img) => (img.image as AssetImage).assetName)
        .toList();

    expect(assetPaths, [
      'assets/icons/nav/home-4.png',
      'assets/icons/nav/bill.png',
      'assets/icons/nav/rating.png',
      'assets/icons/nav/graph.png',
      'assets/icons/nav/settings.png',
    ]);
  });

  testWidgets('NavShell renders CustomBottomNav for /expenses with currentIndex 3 (Stats)', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/expenses',
      routes: [
        ShellRoute(
          builder: (context, state, child) => NavShell(state: state, child: child),
          routes: [
            GoRoute(
              path: '/expenses',
              builder: (context, state) => const Text('Expenses Screen Content'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CustomBottomNav), findsOneWidget);
    final nav = tester.widget<CustomBottomNav>(find.byType(CustomBottomNav));
    expect(nav.currentIndex, 3);
  });

  testWidgets('NavShell renders CustomBottomNav for /clients-tab with currentIndex 2 (Clients)', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/clients-tab',
      routes: [
        ShellRoute(
          builder: (context, state, child) => NavShell(state: state, child: child),
          routes: [
            GoRoute(
              path: '/clients-tab',
              builder: (context, state) => const Text('Clients Tab Content'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CustomBottomNav), findsOneWidget);
    final nav = tester.widget<CustomBottomNav>(find.byType(CustomBottomNav));
    expect(nav.currentIndex, 2);
  });

  testWidgets('NavShell hides CustomBottomNav for detail route /preview', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/preview',
      routes: [
        ShellRoute(
          builder: (context, state, child) => NavShell(state: state, child: child),
          routes: [
            GoRoute(
              path: '/preview',
              builder: (context, state) => const Text('Invoice Preview Screen'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify CustomBottomNav is NOT rendered so buttons underneath are visible
    expect(find.byType(CustomBottomNav), findsNothing);
  });

  testWidgets('NavShell hides CustomBottomNav for sub-routes like /signatures, /company-details, and /bank-details', (WidgetTester tester) async {
    for (final subRoute in ['/signatures', '/company-details', '/bank-details', '/document-settings']) {
      final router = GoRouter(
        initialLocation: subRoute,
        routes: [
          ShellRoute(
            builder: (context, state, child) => NavShell(state: state, child: child),
            routes: [
              GoRoute(
                path: subRoute,
                builder: (context, state) => Text('Content for $subRoute'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure CustomBottomNav is not rendered on mobile sub-pages
      expect(find.byType(CustomBottomNav), findsNothing, reason: 'Expected no CustomBottomNav on $subRoute');
    }
  });

  testWidgets('NavShell hides CustomBottomNav on /dashboard when virtual keyboard is open', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
          builder: (context, state, child) => NavShell(state: state, child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const Text('Dashboard Content'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              viewInsets: EdgeInsets.only(bottom: 300), // Keyboard open!
            ),
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify CustomBottomNav is hidden while typing / keyboard is open
    expect(find.byType(CustomBottomNav), findsNothing);
  });

  testWidgets('NavShell renders CustomBottomNav for /products with currentIndex 4 (Settings)', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/products',
      routes: [
        ShellRoute(
          builder: (context, state, child) => NavShell(state: state, child: child),
          routes: [
            GoRoute(
              path: '/products',
              builder: (context, state) => const Text('Products Catalog Content'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CustomBottomNav), findsOneWidget);
    final nav = tester.widget<CustomBottomNav>(find.byType(CustomBottomNav));
    expect(nav.currentIndex, 4);
  });

  testWidgets('ProductsScreen on mobile shows back button and tapping it navigates to /profile', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/products',
      routes: [
        ShellRoute(
          builder: (context, state, child) => NavShell(state: state, child: child),
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => const NoTransitionPage(child: Text('Profile Screen Target')),
            ),
            GoRoute(
              path: '/products',
              pageBuilder: (context, state) => const NoTransitionPage(child: ProductsScreen()),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredProductsProvider.overrideWithValue([]),
          profileProvider.overrideWith((ref) => _FakeProfileNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify CustomBottomNav is rendered
    expect(find.byType(CustomBottomNav), findsOneWidget);

    // Verify back button is visible
    final backBtn = find.byKey(const ValueKey('products_back_button'));
    expect(backBtn, findsOneWidget);

    // Tap back button
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // Verify navigated to /profile
    expect(find.text('Profile Screen Target'), findsOneWidget);
  });
}

class _FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  _FakeProfileNotifier() : super(BusinessProfile.empty().copyWith(businessName: 'saravana pmv'));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

