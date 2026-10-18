import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inka/presentation/widgets/custom_bottom_nav.dart';
import 'package:inka/presentation/widgets/nav_shell.dart';

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
}
