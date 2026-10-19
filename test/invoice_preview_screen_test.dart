import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/data/models/client.dart';
import 'package:inka/data/models/invoice.dart';
import 'package:inka/data/models/invoice_item.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/screens/invoice_preview_screen.dart';
import 'package:inka/presentation/viewmodels/invoice_viewmodel.dart';

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier()
      : super(BusinessProfile.empty().copyWith(
          businessName: 'Saravana S_2',
          email: 'saravana@gmail.com',
          currency: 'USD',
        ));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeInvoiceNotifier extends StateNotifier<List<Invoice>> implements InvoiceNotifier {
  FakeInvoiceNotifier(Invoice testInvoice) : super([testInvoice]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testInvoice = Invoice(
    id: 'inv_636757',
    invoiceNumber: '636757',
    client: Client(
      id: 'c1',
      name: 'naveen -test',
      email: 'saravana@gmail.com',
      address: 'ghhjj',
      phone: '+1234567890',
    ),
    items: [
      InvoiceItem(id: 'i1', name: 'Software Consulting', quantity: 1, price: 1000.0),
    ],
    issueDate: DateTime(2026, 9, 4),
    dueDate: DateTime(2026, 9, 18), // overdue date
    status: 'overdue',
  );

  testWidgets('InvoicePreviewScreen has no overdue button and no PDF preview tab switcher', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => FakeProfileNotifier()),
          invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier(testInvoice)),
        ],
        child: MaterialApp(
          home: InvoicePreviewScreen(invoice: testInvoice),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify invoice header is rendered cleanly
    expect(find.text('INV-#636757'), findsOneWidget);

    // 2. Verify overdue button is NOT rendered
    expect(find.text('Overdue'), findsNothing);
    expect(find.text('overdue'), findsNothing);

    // 3. Verify PDF preview / tab switcher is removed
    expect(find.text('Summary'), findsNothing);
    expect(find.text('PDF Preview'), findsNothing);

    // 4. Verify duplicate invoice button is removed
    expect(find.text('Duplicate'), findsNothing);

    // 5. Verify bottom action buttons are present and visible
    expect(find.text('Download invoice'), findsOneWidget);
    expect(find.text('Share invoice'), findsOneWidget);

    // 5. Verify other summary elements are rendered cleanly
    expect(find.text('Saravana S_2'), findsOneWidget);
    expect(find.text('naveen -test'), findsOneWidget);
    expect(find.text('Live Web Invoice'), findsOneWidget);

    // 6. Verify per-invoice signing prompts are removed
    expect(find.text('Tap here to draw signature on this bill'), findsNothing);
    expect(find.text('Draw Your Signature'), findsNothing);
    expect(find.text('Configure once in Profile to apply across all invoices'), findsOneWidget);
  });

  testWidgets('InvoicePreviewScreen automatically applies profile signature without signing per invoice', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Profile with configured signature
    final profileWithSignature = BusinessProfile.empty().copyWith(
      businessName: 'Saravana S_2',
      email: 'saravana@gmail.com',
      signatureUrl: '/path/to/signature.png',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => FakeProfileNotifier()..state = profileWithSignature),
          invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier(testInvoice)),
        ],
        child: MaterialApp(
          home: InvoicePreviewScreen(invoice: testInvoice),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify profile signature is automatically displayed without per-invoice signing
    expect(find.text('Profile Signature'), findsOneWidget);
    expect(find.text('Signed by Saravana S_2 • Applied automatically from Profile'), findsOneWidget);
    expect(find.text('Tap here to draw signature on this bill'), findsNothing);
    expect(find.text('Draw Your Signature'), findsNothing);
    // When file does not exist on disk, graceful fallback is shown
    expect(find.text('Signature file missing • Tap to re-draw'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
  });

  testWidgets('InvoicePreviewScreen tapping Sign Now or Change opens DrawSignatureBottomSheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => FakeProfileNotifier()),
          invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier(testInvoice)),
        ],
        child: MaterialApp(
          home: InvoicePreviewScreen(invoice: testInvoice),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Sign Now button is present when no signature is set
    final signNowBtn = find.text('Sign Now');
    expect(signNowBtn, findsOneWidget);

    // Tap Sign Now
    await tester.tap(signNowBtn);
    await tester.pumpAndSettle();

    // Verify DrawSignatureBottomSheet opens with drawing pad and actions
    expect(find.text('Draw Your Signature'), findsOneWidget);
    expect(find.text('Save to Bill'), findsOneWidget);
  });

  testWidgets('InvoicePreviewScreen displays sections in altered order: inv no -> dates -> bill from/to -> bill preview -> slide to paid -> download/share', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => FakeProfileNotifier()),
          invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier(testInvoice)),
        ],
        child: MaterialApp(
          home: InvoicePreviewScreen(invoice: testInvoice),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final invNoY = tester.getTopLeft(find.text('INV-#636757')).dy;
    final issuedOnY = tester.getTopLeft(find.text('Issued on:')).dy;
    final billFromY = tester.getTopLeft(find.text('Bill from')).dy;
    final invoiceDetailsY = tester.getTopLeft(find.text('Invoice details')).dy;
    final slideToPaidY = tester.getTopLeft(find.text('Slide to mark as Paid')).dy;
    final downloadInvoiceY = tester.getTopLeft(find.text('Download invoice')).dy;

    // Verify sequential vertical layout order (top to bottom)
    expect(invNoY < issuedOnY, isTrue, reason: 'inv no should be above issued on');
    expect(issuedOnY < billFromY, isTrue, reason: 'issued on should be above bill from');
    expect(billFromY < invoiceDetailsY, isTrue, reason: 'bill from should be above invoice details (bill preview)');
    expect(invoiceDetailsY < slideToPaidY, isTrue, reason: 'bill preview should be above slide to paid');
    expect(slideToPaidY < downloadInvoiceY, isTrue, reason: 'slide to paid should be above download/share section');
  });
}

