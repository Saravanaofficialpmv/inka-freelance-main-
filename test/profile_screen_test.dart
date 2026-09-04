import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/presentation/providers/auth_provider.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/screens/profile_screen.dart';

class FakeAuthNotifier extends StateNotifier<AsyncValue<User?>> implements AuthNotifier {
  FakeAuthNotifier() : super(const AsyncValue.data(null));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier() : super(BusinessProfile.empty().copyWith(businessName: 'Inka Studio'));

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

    // 1. Verify Header & Profile Completion card
    expect(find.text('Inka Studio'), findsNWidgets(2));
    expect(find.text('Profile Completed'), findsOneWidget);

    // 2. Verify Authentic Section Headers
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Invoice Settings'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Support & Legal'), findsOneWidget);

    // 3. Verify Authentic Feature Tiles
    expect(find.text('Company Details'), findsOneWidget);
    expect(find.text('Bank & UPI Details'), findsOneWidget);
    expect(find.text('Signatures & Stamps'), findsOneWidget);
    expect(find.text('Document Settings'), findsOneWidget);
    expect(find.text('Invoice Templates'), findsOneWidget);
    expect(find.text('Notes & Terms'), findsOneWidget);
    expect(find.text('Product Catalog'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Subscription Plans'), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);

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
}
