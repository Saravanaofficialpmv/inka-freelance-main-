import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/data/models/client.dart';
import 'package:inka/data/models/invoice.dart';
import 'package:inka/presentation/providers/client_provider.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/screens/clients_screen.dart';
import 'package:inka/presentation/viewmodels/invoice_viewmodel.dart';
import 'package:inka/presentation/widgets/highlighted_text.dart';

class FakeClientsNotifier extends StateNotifier<List<Client>> implements ClientsNotifier {
  FakeClientsNotifier([List<Client>? clients]) : super(clients ?? []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeInvoiceNotifier extends StateNotifier<List<Invoice>> implements InvoiceNotifier {
  FakeInvoiceNotifier([List<Invoice>? invoices]) : super(invoices ?? []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier([BusinessProfile? profile])
      : super(profile ?? BusinessProfile.empty().copyWith(businessName: 'Inka Studio', currency: 'INR'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ClientsScreen renders customer list directly without billing totals or collection rates', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientProvider.overrideWith((ref) => FakeClientsNotifier([])),
          invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier([])),
          profileProvider.overrideWith((ref) => FakeProfileNotifier()),
        ],
        child: const MaterialApp(
          home: ClientsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify billing overview metrics and rates are NOT present
    expect(find.text('TOTAL BILLED'), findsNothing);
    expect(find.textContaining('Collected'), findsNothing);
    expect(find.textContaining('Outstanding'), findsNothing);
    expect(find.text('Received'), findsNothing);
    expect(find.text('Pending'), findsNothing);

    // 2. Verify clean header and empty state
    expect(find.text('My Clients'), findsOneWidget);
    expect(find.text('No clients found'), findsOneWidget);
    expect(find.text('Add Client'), findsOneWidget);
  });

  testWidgets('ClientsScreen lists customers with contact details and supports search filtering', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final clientA = Client(
      id: 'c1',
      name: 'Acme Corporation',
      email: 'contact@acme.com',
      phone: '+1 234 567 8900',
      address: '123 Main St',
    );

    final clientB = Client(
      id: 'c2',
      name: 'Globex Ltd',
      email: 'info@globex.com',
      phone: '+1 987 654 3210',
      address: '456 Market St',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientProvider.overrideWith((ref) => FakeClientsNotifier([clientA, clientB])),
          invoiceProvider.overrideWith((ref) => FakeInvoiceNotifier([])),
          profileProvider.overrideWith((ref) => FakeProfileNotifier()),
        ],
        child: const MaterialApp(
          home: ClientsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify billing totals are NOT displayed
    expect(find.text('TOTAL BILLED'), findsNothing);
    expect(find.textContaining('Collected'), findsNothing);
    expect(find.textContaining('Outstanding'), findsNothing);

    // 2. Clients list directly renders customers with their contact info
    expect(find.text('Acme Corporation'), findsOneWidget);
    expect(find.text('Globex Ltd'), findsOneWidget);
    expect(find.text('+1 234 567 8900'), findsOneWidget);
    expect(find.text('+1 987 654 3210'), findsOneWidget);
    expect(find.text('contact@acme.com'), findsOneWidget);
    expect(find.text('info@globex.com'), findsOneWidget);

    // 3. Search filtering
    await tester.enterText(find.byType(TextField).first, 'Acme');
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) => w is HighlightedText && w.text == 'Acme Corporation'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((w) => w is HighlightedText && w.text == 'Globex Ltd'),
      findsNothing,
    );
  });
}
