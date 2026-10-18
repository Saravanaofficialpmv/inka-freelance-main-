import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/presentation/providers/auth_provider.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/screens/profile_screen.dart';

class FakeUser implements User {
  @override
  final String? photoURL;
  @override
  final String? email;
  @override
  final String? displayName;

  FakeUser({this.photoURL, this.email = 'bluney61@gmail.com', this.displayName = 'Bluney'});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthNotifier extends StateNotifier<AsyncValue<User?>> implements AuthNotifier {
  bool deleteAccountCalled = false;

  FakeAuthNotifier([User? initialUser]) : super(AsyncValue.data(initialUser));

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalled = true;
    state = const AsyncValue.data(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier([BusinessProfile? profile])
      : super(profile ?? BusinessProfile.empty().copyWith(businessName: 'Inka Studio'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ProfileScreen renders authentic features with Inka branding and excludes mock bloat', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          profileProvider.overrideWith((ref) => FakeProfileNotifier()),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Header: No notification bell or 3-dots popup menu
    expect(find.text('Inka Studio'), findsNWidgets(2));
    expect(find.text('Profile Completed'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);

    // 2. Verify Authentic Section Headers
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Invoice Settings'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Support & Legal'), findsOneWidget);

    // 3. Verify Authentic Feature Tiles including Delete Account
    expect(find.text('Company Details'), findsOneWidget);
    expect(find.text('Bank & UPI Details'), findsOneWidget);
    expect(find.text('Signatures & Stamps'), findsOneWidget);
    expect(find.text('Document Settings'), findsOneWidget);
    expect(find.text('Invoice Templates'), findsOneWidget);
    expect(find.text('Notes & Terms'), findsOneWidget);
    expect(find.text('Product Catalog'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Subscription Plans'), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);

    // 4. Verify Unnecessary Mock Options are completely REMOVED
    expect(find.text('Eway Bills'), findsNothing);
    expect(find.text('E-Invoices'), findsNothing);
    expect(find.text('Refer & Earn ₹2000'), findsNothing);
    expect(find.text('Use Inka On Desktop'), findsNothing);
    expect(find.text('Online Store'), findsNothing);
    expect(find.text('Inka Wallet'), findsNothing);
    expect(find.text('Coupons'), findsNothing);
    expect(find.text('Payment Gateway'), findsNothing);
    expect(find.text('App Lock'), findsNothing);

    // 5. Verify Inka branding footer
    expect(find.text('inka'), findsOneWidget);
    expect(find.text('App Version: 1.0.0'), findsOneWidget);
  });

  testWidgets('Delete account dialog requires business name confirmation before enabling permanent delete', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeAuth = FakeAuthNotifier();
    final fakeProfile = FakeProfileNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => fakeAuth),
          profileProvider.overrideWith((ref) => fakeProfile),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down to reveal Delete Account
    await tester.scrollUntilVisible(
      find.text('Delete Account'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Tap Delete Account tile
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    // Dialog appears with business name requirement
    expect(find.text('Please enter your business name to confirm:'), findsOneWidget);
    expect(find.text('Inka Studio'), findsWidgets);

    final confirmBtnFinder = find.byKey(const ValueKey('delete_account_confirm_btn'));
    expect(confirmBtnFinder, findsOneWidget);

    // Button should initially be disabled
    final ElevatedButton initialBtn = tester.widget(confirmBtnFinder);
    expect(initialBtn.onPressed, isNull);

    // Type incorrect name
    final inputFinder = find.byKey(const ValueKey('delete_account_confirm_field'));
    await tester.enterText(inputFinder, 'Wrong Business');
    await tester.pump();

    final ElevatedButton stillDisabledBtn = tester.widget(confirmBtnFinder);
    expect(stillDisabledBtn.onPressed, isNull);

    // Type correct matching business name (case-insensitive)
    await tester.enterText(inputFinder, 'inka studio');
    await tester.pump();

    final ElevatedButton enabledBtn = tester.widget(confirmBtnFinder);
    expect(enabledBtn.onPressed, isNotNull);

    // Tap Permanently Delete button
    await tester.tap(confirmBtnFinder);
    await tester.pumpAndSettle();

    // Verify deleteAccount was triggered
    expect(fakeAuth.deleteAccountCalled, isTrue);
  });

  testWidgets('Header displays user profile photo when photoURL is present', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeUserWithPhoto = FakeUser(
      photoURL: 'https://lh3.googleusercontent.com/a/sample-photo',
      displayName: 'Bluney',
      email: 'bluney61@gmail.com',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier(fakeUserWithPhoto)),
          profileProvider.overrideWith((ref) => FakeProfileNotifier(BusinessProfile.empty().copyWith(businessName: 'Bluney'))),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pump();

    // Verify Image widget is rendered for the profile picture instead of just text
    expect(find.byType(Image), findsWidgets);
    expect(find.text('Bluney'), findsWidgets);
  });

  testWidgets('Header falls back gracefully to initial letter when no photo is set', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeUserNoPhoto = FakeUser(
      photoURL: null,
      displayName: 'Bluney',
      email: 'bluney61@gmail.com',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier(fakeUserNoPhoto)),
          profileProvider.overrideWith((ref) => FakeProfileNotifier(BusinessProfile.empty().copyWith(businessName: 'Bluney'))),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pump();

    // With no photo, the initial 'B' should be rendered in the avatar
    expect(find.text('B'), findsOneWidget);
    expect(find.text('Bluney'), findsWidgets);
  });
}
