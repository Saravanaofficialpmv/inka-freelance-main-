import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inka/presentation/screens/onboarding_screen.dart';
import 'package:inka/presentation/screens/auth_screen.dart';

void main() {
  testWidgets('OnboardingScreen renders all 3 slides properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Slide 1
    expect(find.textContaining('The simple, fast and smart way'), findsOneWidget);

    // Slide 2
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('Works Offline'), findsOneWidget);

    // Slide 3
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('Everything You Need'), findsOneWidget);
  });

  testWidgets('AuthScreen renders Welcome Back and Demo Access CTA', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Demo Access Login'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Fill Demo'), findsOneWidget);
  });
}
