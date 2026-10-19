import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/data/models/client.dart';
import 'package:inka/data/models/invoice.dart';
import 'package:inka/data/models/invoice_item.dart';
import 'package:inka/presentation/providers/client_provider.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/screens/create_invoice_screen.dart';
import 'package:inka/presentation/viewmodels/invoice_viewmodel.dart';

class FakeInvoiceNotifier extends StateNotifier<List<Invoice>> implements InvoiceNotifier {
  FakeInvoiceNotifier([List<Invoice>? invoices]) : super(invoices ?? []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier([BusinessProfile? profile])
      : super(profile ?? BusinessProfile.empty().copyWith(businessName: 'Inka Studio'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeClientsNotifier extends StateNotifier<List<Client>> implements ClientsNotifier {
  FakeClientsNotifier([List<Client>? clients]) : super(clients ?? []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sampleClient = Client(
    id: 'c1',
    name: 'Client Alpha',
    phone: '9876543210',
    email: 'alpha@example.com',
    address: 'Bangalore, India',
  );

  group('Invoice Number Starts From 1 Tests', () {
    testWidgets('New user with 0 invoices starts with invoice number 1', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier([])),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
            clientsProvider.overrideWith((ref) => FakeClientsNotifier([sampleClient])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CreateInvoiceScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the invoice starts from 1
      expect(find.text('INV-#1'), findsOneWidget);
    });

    testWidgets('User with existing invoice 1 gets invoice number 2', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      final existingInvoices = [
        Invoice(
          id: 'inv-1',
          invoiceNumber: '1',
          client: sampleClient,
          items: [InvoiceItem(id: 'i1', name: 'Service', price: 100, quantity: 1)],
          issueDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 7)),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier(existingInvoices)),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
            clientsProvider.overrideWith((ref) => FakeClientsNotifier([sampleClient])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CreateInvoiceScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the next invoice number is 2
      expect(find.text('INV-#2'), findsOneWidget);
    });

    testWidgets('User can tap invoice number to edit it', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier([])),
            profileProvider.overrideWith((ref) => FakeProfileNotifier()),
            clientsProvider.overrideWith((ref) => FakeClientsNotifier([sampleClient])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CreateInvoiceScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the invoice number badge
      await tester.tap(find.text('INV-#1'));
      await tester.pumpAndSettle();

      // Verify edit dialog opens
      expect(find.text('Invoice Number'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Change number to 101
      await tester.enterText(find.byType(TextField), '101');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify updated invoice number on screen
      expect(find.text('INV-#101'), findsOneWidget);
    });
  });
}
