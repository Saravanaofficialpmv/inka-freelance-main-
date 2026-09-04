import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inka/presentation/widgets/custom_bottom_nav.dart';

void main() {
  testWidgets('CustomBottomNav renders all 5 tabs and custom nav_icons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomBottomNav(currentIndex: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 5 tab labels are rendered
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('Clients'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify custom nav_icons asset images are loaded
    final imageWidgets = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(imageWidgets.length, 5);

    final assetPaths = imageWidgets
        .map((img) => (img.image as AssetImage).assetName)
        .toList();

    expect(assetPaths, [
      'nav_icons/home-4.png',
      'nav_icons/bill.png',
      'nav_icons/rating.png',
      'nav_icons/graph.png',
      'nav_icons/settings.png',
    ]);
  });
}
