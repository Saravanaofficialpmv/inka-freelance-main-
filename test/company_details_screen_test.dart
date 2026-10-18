import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/screens/company_details_screen.dart';

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier() : super(
    BusinessProfile.empty().copyWith(
      businessName: 'Inka Design Studio',
      email: 'hello@inkastudio.com',
      phone: '+1 (555) 019-2834',
      address: '742 Evergreen Terrace',
      gstNumber: 'GSTIN29ABCDE1234F1Z5',
    ),
  );

  @override
  Future<void> updateProfile(BusinessProfile profile) async {
    state = profile;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('CompanyDetailsScreen renders all form fields and saves business details', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeNotifier = FakeProfileNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: CompanyDetailsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar
    expect(find.text('Company Details'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    // Verify Business Logo Card
    expect(find.text('Inka Design Studio'), findsNWidgets(2));
    expect(find.text('Tap to change official business logo'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

    // Verify Form Fields
    expect(find.text('Business Name'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
    expect(find.text('Tax ID / GSTIN'), findsNothing);
    expect(find.text('tax_id'), findsNothing);

    // Verify Save Button
    expect(find.text('Save Changes'), findsOneWidget);

    // Test editing business name and saving
    await tester.enterText(find.widgetWithText(TextField, 'Inka Design Studio'), 'Updated Inka Ltd');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(fakeNotifier.state.businessName, 'Updated Inka Ltd');
  });
}
