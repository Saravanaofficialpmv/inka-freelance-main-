import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/screens/bank_details_screen.dart';
import 'package:inka/presentation/screens/document_settings_screen.dart';
import 'package:inka/presentation/screens/notes_terms_screen.dart';
import 'package:inka/presentation/screens/language_settings_screen.dart';
import 'package:inka/presentation/screens/currency_settings_screen.dart';
import 'package:inka/presentation/screens/help_support_screen.dart';
import 'package:inka/presentation/screens/privacy_policy_screen.dart';

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier() : super(
    BusinessProfile.empty().copyWith(
      bankName: 'HDFC Bank',
      branchName: 'Koramangala',
      accountNo: '50100234567890',
      ifscCode: 'HDFC0001234',
      upiId: 'freelancer@upi',
      currency: 'INR',
      taxLabel: 'GST',
      defaultTaxRate: 18.0,
      isTaxInclusive: false,
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
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('BankDetailsScreen renders fields and updates profile', (tester) async {
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
          home: BankDetailsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add New bank'), findsOneWidget);
    expect(find.text('Bank details'), findsOneWidget);
    expect(find.text('Account information'), findsOneWidget);
    expect(find.text('UPI details'), findsOneWidget);
    expect(find.text('Additional options'), findsOneWidget);
    expect(find.text('HDFC Bank'), findsOneWidget);
    expect(find.text('Koramangala'), findsOneWidget);
    expect(find.text('50100234567890'), findsWidgets);

    // Update bank name
    await tester.enterText(find.widgetWithText(TextField, 'HDFC Bank'), 'ICICI Bank');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fakeNotifier.state.bankName, 'ICICI Bank');
  });

  testWidgets('BankDetailsScreen saves opening balance, notes, and primary toggle', (tester) async {
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
          home: BankDetailsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify helper caption
    expect(
      find.text('(Swift Code, Beneficiary Name) etc, notes will also be shown along with the bank details'),
      findsOneWidget,
    );

    // Verify Set as Primary Account
    expect(find.text('Set as Primary Account'), findsOneWidget);
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();

    // Toggle switch off
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Verify top play guide icon has been removed
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

    // Tap Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fakeNotifier.state.isPrimaryAccount, false);
  });

  testWidgets('DocumentSettingsScreen renders tax schemes and saves settings', (tester) async {
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
          home: DocumentSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Document Settings'), findsOneWidget);
    expect(find.text('Tax Scheme Presets'), findsOneWidget);
    expect(find.text('GST (18%)'), findsOneWidget);
    expect(find.text('VAT (20%)'), findsOneWidget);
    expect(find.text('Default Currency'), findsOneWidget);
    expect(find.text('INR - Indian Rupee (₹)'), findsOneWidget);
    expect(find.text('Change in Currency Settings page'), findsOneWidget);
    // Currency switching list is removed from this page
    expect(find.text('EUR - Euro (€)'), findsNothing);
    expect(find.text('JPY - Japanese Yen (¥)'), findsNothing);
    expect(find.text('Save Changes'), findsOneWidget);

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(fakeNotifier.state.taxLabel, 'GST');
  });

  testWidgets('NotesTermsScreen renders presets and saves terms', (tester) async {
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
          home: NotesTermsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notes & Terms'), findsOneWidget);
    expect(find.text('Terms & Conditions'), findsOneWidget);
    expect(find.text('Customer Note / Closing Remarks'), findsOneWidget);
    await tester.tap(find.text('Payment is due within 15 days of invoice date.'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Payment is due within 15 days of invoice date.'), findsOneWidget);

    await tester.tap(find.text('Save Changes'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('LanguageSettingsScreen renders supported languages', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LanguageSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Language Settings'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Tamil'), findsOneWidget);
    expect(find.text('Hindi'), findsOneWidget);
    expect(find.text('Spanish'), findsOneWidget);
  });

  testWidgets('CurrencySettingsScreen renders top 10 currencies', (tester) async {
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
          home: CurrencySettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Currency Settings'), findsOneWidget);
    expect(find.text('Top 10 Major Currencies'), findsOneWidget);
    expect(find.text('US Dollar'), findsOneWidget);
    expect(find.text('Euro'), findsOneWidget);
    expect(find.text('British Pound'), findsOneWidget);
    expect(find.text('Indian Rupee'), findsOneWidget);
    expect(find.text('Japanese Yen'), findsOneWidget);
    expect(find.text('Canadian Dollar'), findsOneWidget);
    expect(find.text('Australian Dollar'), findsOneWidget);
    expect(find.text('Swiss Franc'), findsOneWidget);
    expect(find.text('Singapore Dollar'), findsOneWidget);
    expect(find.text('UAE Dirham'), findsOneWidget);
  });

  testWidgets('HelpSupportScreen renders support channels and FAQs', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HelpSupportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('WhatsApp Support'), findsOneWidget);
    expect(find.text('Email Support'), findsOneWidget);
    expect(find.text('Frequently Asked Questions'), findsOneWidget);
  });

  testWidgets('PrivacyPolicyScreen renders data protection policy', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PrivacyPolicyScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Your Data Is Yours'), findsOneWidget);
    expect(find.text('1. Information We Collect'), findsOneWidget);
  });
}
