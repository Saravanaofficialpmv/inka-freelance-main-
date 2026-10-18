import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inka/core/utils/navigation_utils.dart';
import 'package:inka/presentation/screens/bank_details_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/data/models/business_profile.dart';

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier() : super(BusinessProfile.empty().copyWith(businessName: 'Test Business'));

  @override
  Future<void> updateProfile(BusinessProfile profile) async {
    state = profile;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Safe Navigation Tests', () {
    testWidgets('safeNavigateBack pops when Navigator can pop', (tester) async {
      bool popped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (childContext) => Scaffold(
                        body: ElevatedButton(
                          onPressed: () {
                            safeNavigateBack(childContext, fallbackRoute: '/fallback');
                            popped = true;
                          },
                          child: const Text('Go Back'),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Push Route'),
              ),
            ),
          ),
        ),
      );

      // Tap push
      await tester.tap(find.text('Push Route'));
      await tester.pumpAndSettle();

      expect(find.text('Go Back'), findsOneWidget);

      // Tap Go Back
      await tester.tap(find.text('Go Back'));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(find.text('Push Route'), findsOneWidget);
      expect(find.text('Go Back'), findsNothing);
    });

    testWidgets('safeNavigateBack navigates to fallback in GoRouter when cannot pop', (tester) async {
      String currentLocation = '/start';

      final router = GoRouter(
        initialLocation: '/start',
        routes: [
          GoRoute(
            path: '/start',
            builder: (context, state) {
              currentLocation = '/start';
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => safeNavigateBack(context, fallbackRoute: '/profile'),
                  child: const Text('Back At Root'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) {
              currentLocation = '/profile';
              return const Scaffold(body: Text('Profile Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Back At Root'), findsOneWidget);
      expect(currentLocation, '/start');

      // Tap Back At Root - since canPop is false, it goes to /profile
      await tester.tap(find.text('Back At Root'));
      await tester.pumpAndSettle();

      expect(find.text('Profile Screen'), findsOneWidget);
      expect(currentLocation, '/profile');
    });

    testWidgets('BankDetailsScreen back button safely navigates without white screen or crash', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetPhysicalSize);

      String currentPath = '/bank-details';

      final router = GoRouter(
        initialLocation: '/bank-details',
        routes: [
          GoRoute(
            path: '/bank-details',
            builder: (context, state) {
              currentPath = '/bank-details';
              return const BankDetailsScreen();
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) {
              currentPath = '/profile';
              return const Scaffold(body: Text('Profile Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add New bank'), findsOneWidget);
      expect(currentPath, '/bank-details');

      // Click the back arrow
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Screen must safely navigate to /profile instead of becoming blank or popping root navigator
      expect(find.text('Profile Screen'), findsOneWidget);
      expect(currentPath, '/profile');
    });
  });
}
