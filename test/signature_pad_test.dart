import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/business_profile.dart';
import 'package:inka/presentation/providers/profile_provider.dart';
import 'package:inka/presentation/screens/signature_settings_screen.dart';
import 'package:inka/presentation/widgets/signature_pad.dart';

class FakeProfileNotifier extends StateNotifier<BusinessProfile> implements ProfileNotifier {
  FakeProfileNotifier()
      : super(
          BusinessProfile.empty().copyWith(
            businessName: 'Apex Studio',
            currency: 'USD',
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

  group('SignaturePadController Tests', () {
    test('Initial controller is empty', () {
      final controller = SignaturePadController();
      expect(controller.isEmpty, isTrue);
      expect(controller.isNotEmpty, isFalse);
      expect(controller.strokes, isEmpty);
    });

    test('Adding points creates strokes', () {
      final controller = SignaturePadController();
      controller.startStroke(const Offset(10, 10));
      controller.addPointToCurrentStroke(const Offset(20, 20));
      controller.endStroke();

      expect(controller.isEmpty, isFalse);
      expect(controller.strokes.length, 1);
      expect(controller.strokes.first.points.length, 2);
    });

    test('Undo removes last stroke', () {
      final controller = SignaturePadController();
      controller.startStroke(const Offset(10, 10));
      controller.endStroke();
      controller.startStroke(const Offset(30, 30));
      controller.endStroke();

      expect(controller.strokes.length, 2);
      controller.undo();
      expect(controller.strokes.length, 1);
    });

    test('Clear removes all strokes', () {
      final controller = SignaturePadController();
      controller.startStroke(const Offset(10, 10));
      controller.endStroke();
      controller.clear();
      expect(controller.isEmpty, isTrue);
    });

    test('Changing color and thickness updates active stroke style', () {
      final controller = SignaturePadController();
      controller.setColor(const Color(0xFF1E3A8A));
      controller.setWidth(5.0);

      expect(controller.activeColor, const Color(0xFF1E3A8A));
      expect(controller.activeWidth, 5.0);

      controller.startStroke(const Offset(5, 5));
      controller.endStroke();

      expect(controller.strokes.first.color, const Color(0xFF1E3A8A));
      expect(controller.strokes.first.width, 5.0);
    });

    test('exportPngBytes generates valid non-empty PNG byte stream', () async {
      final controller = SignaturePadController();
      controller.startStroke(const Offset(10, 10));
      controller.addPointToCurrentStroke(const Offset(50, 50));
      controller.addPointToCurrentStroke(const Offset(100, 30));
      controller.endStroke();

      final bytes = await controller.exportPngBytes(canvasSize: const Size(200, 100));
      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);
      // PNG magic header bytes: 0x89, 0x50, 0x4E, 0x47 ('.PNG')
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x4E);
      expect(bytes[3], 0x47);
    });
  });

  group('Signature Widget & Screen Tests', () {
    testWidgets('SignaturePad widget renders and records gesture strokes', (tester) async {
      final controller = SignaturePadController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignaturePad(controller: controller),
          ),
        ),
      );

      expect(find.text('Draw your signature here'), findsOneWidget);
      expect(find.byType(SignaturePad), findsOneWidget);

      // Perform a drag gesture on the canvas
      await tester.drag(
        find.byKey(const ValueKey('signature_drawing_canvas')),
        const Offset(50, 50),
      );
      await tester.pump();

      expect(controller.isNotEmpty, isTrue);
      expect(find.text('Draw your signature here'), findsNothing);
    });

    testWidgets('SignatureSettingsScreen renders draw mode and save button', (tester) async {
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
            home: SignatureSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Signatures & Stamps'), findsOneWidget);
      expect(find.text('Draw on Screen'), findsOneWidget);
      expect(find.text('Upload Image'), findsOneWidget);
      expect(find.text('Save Signature to Bills'), findsOneWidget);
      expect(find.byType(SignaturePad), findsOneWidget);
    });

    testWidgets('SignaturePad toolbar renders cleanly without overflow on narrow screens', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = SignaturePadController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SignaturePad(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ink:'), findsOneWidget);
      expect(find.text('Fine'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Bold'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
