import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/screens/business_setup_screen.dart';

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier() : super(BusinessProfile.empty());

  @override
  Future<void> updateProfile(BusinessProfile profile) async {
    state = profile;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('BusinessSetupScreen renders 3-level wizard and navigates across levels', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeNotifier = FakeProfileNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: BusinessSetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Level 1: Business Identity & Contact
    expect(find.text('Business Setup'), findsOneWidget);
    expect(find.text('LEVEL 1 OF 3: IDENTITY'), findsOneWidget);
    expect(find.text('Business Identity & Contact'), findsOneWidget);
    expect(find.text('BUSINESS / FREELANCER NAME *'), findsOneWidget);
    expect(find.text('PRIMARY BILLING CURRENCY *'), findsOneWidget);
    expect(find.text('OFFICIAL BUSINESS EMAIL *'), findsOneWidget);
    expect(find.text('PHONE / WHATSAPP NUMBER *'), findsOneWidget);
    expect(find.text('REGISTERED BUSINESS ADDRESS *'), findsOneWidget);
    expect(find.text('Next: Tax & Legal Rules →'), findsOneWidget);

    // 2. Try to proceed without entering name -> triggers validation error
    await tester.tap(find.text('Next: Tax & Legal Rules →'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your business or freelancer name'), findsOneWidget);

    // 3. Fill Level 1 fields
    await tester.enterText(find.widgetWithText(TextField, 'e.g. Acme Studio / Sarah Jenkins'), 'Inka Creative Studio');
    await tester.enterText(find.widgetWithText(TextField, 'contact@business.com'), 'hello@inkastudio.com');
    await tester.enterText(find.widgetWithText(TextField, '+1 234 567 890'), '+1 555 123 4567');
    await tester.enterText(find.widgetWithText(TextField, 'Street, City, State/Province, ZIP, Country'), '100 Innovation Way, Suite 400');
    await tester.pumpAndSettle();

    // 4. Advance to Level 2: Tax & Legal
    await tester.tap(find.text('Next: Tax & Legal Rules →'));
    await tester.pumpAndSettle();

    expect(find.text('LEVEL 2 OF 3: TAX & LEGAL'), findsOneWidget);
    expect(find.text('Tax, Registration & Invoicing Defaults'), findsOneWidget);
    expect(find.text('TAX SCHEME / REGION *'), findsOneWidget);
    expect(find.text('GST'), findsOneWidget);
    expect(find.text('VAT'), findsOneWidget);
    expect(find.text('Tax Inclusive Pricing'), findsOneWidget);
    expect(find.text('DEFAULT INVOICE TEMPLATE'), findsOneWidget);
    expect(find.text('Next: Payouts & Banking →'), findsOneWidget);

    // 5. Advance to Level 3: Bank, UPI & Payment Settlement
    await tester.tap(find.text('Next: Payouts & Banking →'));
    await tester.pumpAndSettle();

    expect(find.text('LEVEL 3 OF 3: PAYOUTS'), findsOneWidget);
    expect(find.text('Bank & UPI Payment Settlement'), findsOneWidget);
    expect(find.text('Direct Bank Transfer Coordinates'), findsOneWidget);
    expect(find.text('UPI & Digital Payment QR'), findsOneWidget);
    expect(find.text('Complete Setup & Launch Dashboard 🚀'), findsOneWidget);
    expect(find.text('I\'ll add bank details later'), findsOneWidget);
  });
}
