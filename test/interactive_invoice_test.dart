import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/data/models/client.dart';
import 'package:inka/data/models/invoice.dart';
import 'package:inka/data/models/invoice_item.dart';
import 'package:inka/data/models/payment_milestone.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/screens/interactive_web_invoice_screen.dart';
import 'package:inka/presentation/viewmodels/invoice_viewmodel.dart';
import 'package:inka/presentation/widgets/payment_proof_sheet.dart';
import 'package:inka/services/interactive_invoice_service.dart';

class TestInvoiceNotifier extends StateNotifier<List<Invoice>> implements InvoiceNotifier {
  TestInvoiceNotifier(super.state);

  @override
  Future<void> recordClientView(String invoiceId) async {
    state = [
      for (final inv in state)
        if (inv.id == invoiceId)
          inv.copyWith(
            clientViewedAt: DateTime.now(),
            clientViewCount: inv.clientViewCount + 1,
          )
        else
          inv,
    ];
  }

  @override
  Future<void> submitPaymentProof(
    String invoiceId, {
    required String refNumber,
    String? note,
    String? imageBase64,
    String? milestoneId,
  }) async {
    state = [
      for (final inv in state)
        if (inv.id == invoiceId)
          inv.copyWith(
            paymentProofRef: refNumber,
            paymentProofDate: DateTime.now(),
            paymentProofNote: note,
            paymentProofStatus: 'submitted',
            paymentProofImage: imageBase64,
          )
        else
          inv,
    ];
  }

  @override
  Future<void> verifyPaymentProof(String invoiceId, {bool markAsPaid = true}) async {
    state = [
      for (final inv in state)
        if (inv.id == invoiceId)
          inv.copyWith(
            paymentProofStatus: markAsPaid ? 'verified' : 'rejected',
            status: markAsPaid ? 'paid' : inv.status,
          )
        else
          inv,
    ];
  }

  @override
  Future<void> updateMilestones(String invoiceId, List<PaymentMilestone> milestones) async {
    final allPaid = milestones.isNotEmpty && milestones.every((m) => m.isPaid);
    state = [
      for (final inv in state)
        if (inv.id == invoiceId)
          inv.copyWith(
            milestones: milestones,
            status: allPaid ? 'paid' : inv.status,
          )
        else
          inv,
    ];
  }

  @override
  Future<void> markMilestonePaid(String invoiceId, String milestoneId, {String? txRef}) async {
    state = [
      for (final inv in state)
        if (inv.id == invoiceId) ...[
          () {
            bool foundTarget = false;
            final updated = <PaymentMilestone>[];
            for (final m in inv.milestones) {
              if (m.id == milestoneId) {
                foundTarget = true;
                updated.add(m.copyWith(status: 'paid', paidAt: DateTime.now(), transactionRef: txRef));
              } else if (foundTarget && m.isPending) {
                updated.add(m.copyWith(status: 'active'));
                foundTarget = false;
              } else {
                updated.add(m);
              }
            }
            final allPaid = updated.isNotEmpty && updated.every((m) => m.isPaid);
            return inv.copyWith(
              milestones: updated,
              status: allPaid ? 'paid' : inv.status,
            );
          }(),
        ] else
          inv,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier([BusinessProfile? profile])
      : super(
          profile ??
              BusinessProfile.empty().copyWith(
                businessName: 'Apex Studio',
                currency: 'USD',
                email: 'contact@apex.dev',
                phone: '+1 555 123 4567',
                upiId: 'apex@upi',
              ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sampleClient = Client(
    id: 'c_test_1',
    name: 'Sarah Connor',
    phone: '+1 555 019 2831',
    email: 'sarah@cyberdyne.org',
    address: '2400 Mission St, San Francisco, CA',
  );

  final sampleItems = [
    InvoiceItem(id: 'i1', name: 'Mobile App UX Design', price: 2000.0, quantity: 1),
    InvoiceItem(id: 'i2', name: 'Flutter App Development', price: 3000.0, quantity: 1),
  ];

  group('Interactive Invoice & Milestone Logic Tests', () {
    test('PaymentMilestone calculations, status helpers, and JSON roundtrip', () {
      final milestone = PaymentMilestone(
        id: 'm1',
        title: 'Initial Deposit (40%)',
        percentage: 40.0,
        amount: 2000.0,
        status: 'active',
      );

      expect(milestone.isActive, isTrue);
      expect(milestone.isPaid, isFalse);
      expect(milestone.isPending, isFalse);

      final map = milestone.toMap();
      expect(map['title'], equals('Initial Deposit (40%)'));
      expect(map['percentage'], equals(40.0));
      expect(map['amount'], equals(2000.0));
      expect(map['status'], equals('active'));

      final fromMap = PaymentMilestone.fromMap(map);
      expect(fromMap.id, equals('m1'));
      expect(fromMap.percentage, equals(40.0));
      expect(fromMap.amount, equals(2000.0));

      final paidMilestone = milestone.copyWith(
        status: 'paid',
        paidAt: DateTime(2024, 10, 12, 14, 30),
        transactionRef: 'UTR99887766',
      );
      expect(paidMilestone.isPaid, isTrue);
      expect(paidMilestone.isActive, isFalse);
      expect(paidMilestone.transactionRef, equals('UTR99887766'));
    });

    test('InteractiveInvoiceService generates canonical URL and presets', () {
      final url = InteractiveInvoiceService.getInteractiveInvoiceUrl('inv_9988');
      expect(url, equals('https://inka.link/inv/inv_9988'));

      // Test 50/50 preset
      final split50 = InteractiveInvoiceService.generate50_50Split(totalAmount: 5000.0);
      expect(split50.length, equals(2));
      expect(split50[0].percentage, equals(50.0));
      expect(split50[0].amount, equals(2500.0));
      expect(split50[0].isActive, isTrue);
      expect(split50[1].percentage, equals(50.0));
      expect(split50[1].amount, equals(2500.0));
      expect(split50[1].isPending, isTrue);
      expect(split50.fold<double>(0, (sum, m) => sum + m.amount), equals(5000.0));

      // Test 40/30/30 preset
      final split40 = InteractiveInvoiceService.generate40_30_30Split(totalAmount: 10000.0);
      expect(split40.length, equals(3));
      expect(split40[0].amount, equals(4000.0));
      expect(split40[1].amount, equals(3000.0));
      expect(split40[2].amount, equals(3000.0));
      expect(split40.fold<double>(0, (sum, m) => sum + m.percentage), equals(100.0));
    });

    test('Invoice model handles milestones and proof metadata accurately', () {
      final milestones = [
        PaymentMilestone(id: 'm1', title: 'Deposit 40%', percentage: 40, amount: 2000, status: 'paid'),
        PaymentMilestone(id: 'm2', title: 'Mid Review 30%', percentage: 30, amount: 1500, status: 'active'),
        PaymentMilestone(id: 'm3', title: 'Final Handover 30%', percentage: 30, amount: 1500, status: 'pending'),
      ];

      final invoice = Invoice(
        id: 'inv_real_100',
        invoiceNumber: '100456',
        client: sampleClient,
        items: sampleItems,
        issueDate: DateTime(2024, 10, 1),
        dueDate: DateTime(2024, 10, 20),
        status: 'pending',
        milestones: milestones,
        clientViewedAt: DateTime(2024, 10, 11, 15, 45),
        clientViewCount: 4,
        paymentProofRef: 'HDFC99881122',
        paymentProofStatus: 'submitted',
      );

      expect(invoice.hasMilestones, isTrue);
      expect(invoice.paidMilestones.length, equals(1));
      expect(invoice.activeMilestone?.id, equals('m2'));
      expect(invoice.milestonesTotalPaid, equals(2000.0));
      expect(invoice.milestonesRemaining, equals(3000.0));
      expect(invoice.hasPaymentProof, isTrue);
      expect(invoice.clientViewCount, equals(4));

      // Serialization roundtrip
      final map = invoice.toMap();
      expect(map['clientViewCount'], equals(4));
      expect(map['paymentProofRef'], equals('HDFC99881122'));
      expect((map['milestones'] as List).length, equals(3));

      final fromMap = Invoice.fromMap(map);
      expect(fromMap.milestones.length, equals(3));
      expect(fromMap.paidMilestones.length, equals(1));
      expect(fromMap.milestonesRemaining, equals(3000.0));
    });

    test('InvoiceNotifier records client views and advances milestone tranches', () async {
      final milestones = [
        PaymentMilestone(id: 'm1', title: 'Tranche 1', percentage: 50, amount: 2500, status: 'active'),
        PaymentMilestone(id: 'm2', title: 'Tranche 2', percentage: 50, amount: 2500, status: 'pending'),
      ];

      final initialInvoice = Invoice(
        id: 'inv_dyn_1',
        invoiceNumber: '2001',
        client: sampleClient,
        items: sampleItems,
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 14)),
        status: 'pending',
        milestones: milestones,
      );

      final notifier = TestInvoiceNotifier([initialInvoice]);

      // 1. Record Client View
      await notifier.recordClientView('inv_dyn_1');
      expect(notifier.state.first.clientViewCount, equals(1));
      expect(notifier.state.first.clientViewedAt, isNotNull);

      // 2. Client submits proof
      await notifier.submitPaymentProof(
        'inv_dyn_1',
        refNumber: 'UPI_REF_990011',
        note: 'Paid Tranche 1 via GPay',
      );
      expect(notifier.state.first.paymentProofRef, equals('UPI_REF_990011'));
      expect(notifier.state.first.paymentProofStatus, equals('submitted'));

      // 3. Mark milestone 1 paid -> should activate milestone 2
      await notifier.markMilestonePaid('inv_dyn_1', 'm1');
      final updatedM1 = notifier.state.first.milestones[0];
      final updatedM2 = notifier.state.first.milestones[1];
      expect(updatedM1.isPaid, isTrue);
      expect(updatedM2.isActive, isTrue);
      expect(notifier.state.first.status, equals('pending'));

      // 4. Mark milestone 2 paid -> whole invoice should auto-mark as paid
      await notifier.markMilestonePaid('inv_dyn_1', 'm2');
      expect(notifier.state.first.milestones[1].isPaid, isTrue);
      expect(notifier.state.first.status, equals('paid'));
    });
  });

  group('InteractiveWebInvoiceScreen Widget Tests', () {
    testWidgets('InteractiveWebInvoiceScreen renders live read receipts and milestone cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      final milestones = [
        PaymentMilestone(id: 'm1', title: 'Deposit (40%)', percentage: 40, amount: 2000, status: 'paid'),
        PaymentMilestone(id: 'm2', title: 'Mid-Review (30%)', percentage: 30, amount: 1500, status: 'active'),
        PaymentMilestone(id: 'm3', title: 'Final Handover (30%)', percentage: 30, amount: 1500, status: 'pending'),
      ];

      final invoice = Invoice(
        id: 'inv_web_test',
        invoiceNumber: '884920',
        client: sampleClient,
        items: sampleItems,
        issueDate: DateTime(2024, 10, 1),
        dueDate: DateTime(2024, 10, 20),
        status: 'pending',
        milestones: milestones,
        clientViewCount: 2,
        clientViewedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      final notifier = TestInvoiceNotifier([invoice]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoiceProvider.overrideWith((ref) => notifier),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
          ],
          child: const MaterialApp(
            home: InteractiveWebInvoiceScreen(invoiceId: 'inv_web_test'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Read status badge
      expect(find.textContaining('Live Read Receipt Active'), findsOneWidget);

      // Milestone card titles
      expect(find.text('Deposit (40%)'), findsOneWidget);
      expect(find.text('Mid-Review (30%)'), findsOneWidget);
      expect(find.text('Final Handover (30%)'), findsOneWidget);

      // Next payable chunk badge
      expect(find.text('DUE NOW'), findsOneWidget);
      expect(find.text('PAID'), findsOneWidget);

      // "I've Paid • Upload Proof" button
      expect(find.text("I've Paid • Upload Proof"), findsOneWidget);
    });

    testWidgets('PaymentProofSheet allows entering reference number and submitting', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      final invoice = Invoice(
        id: 'inv_proof_test',
        invoiceNumber: '772211',
        client: sampleClient,
        items: sampleItems,
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 10)),
        status: 'pending',
      );

      String? submittedRef;
      String? submittedNote;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentProofSheet(
              invoice: invoice,
              onSubmit: (ref, note, img) {
                submittedRef = ref;
                submittedNote = note;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Submit Proof of Payment'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));

      // Enter UTR reference number
      await tester.enterText(find.byType(TextField).first, 'UPI9988221133');
      await tester.enterText(find.byType(TextField).last, 'Transferred via PhonePe');
      await tester.pumpAndSettle();

      // Tap Submit Payment Confirmation
      await tester.tap(find.text('Submit Payment Confirmation'));
      await tester.pumpAndSettle();

      expect(submittedRef, equals('UPI9988221133'));
      expect(submittedNote, equals('Transferred via PhonePe'));
    });
  });
}
