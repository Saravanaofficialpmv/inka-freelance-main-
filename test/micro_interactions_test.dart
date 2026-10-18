import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inka/presentation/widgets/slide_to_confirm.dart';
import 'package:inka/presentation/widgets/animated_currency_text.dart';
import 'package:inka/presentation/widgets/voice_waveform_indicator.dart';
import 'package:inka/presentation/widgets/status_badge.dart';
import 'package:inka/presentation/widgets/bouncing_button.dart';
import 'package:inka/presentation/widgets/sync_status_badge.dart';
import 'package:inka/presentation/providers/sync_status_provider.dart';

void main() {
  group('SlideToConfirm Widget Tests', () {
    testWidgets('renders initial idle state with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideToConfirm(
              label: 'Slide to Pay',
              onConfirmed: () async {},
            ),
          ),
        ),
      );

      expect(find.text('Slide to Pay'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideToConfirm(
              label: 'Slide to Pay',
              isLoading: true,
              onConfirmed: () async {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows completed icon and label when isCompleted is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideToConfirm(
              label: 'Slide to Pay',
              completedLabel: 'Payment Complete',
              isCompleted: true,
              onConfirmed: () async {},
            ),
          ),
        ),
      );

      expect(find.text('Payment Complete'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('dragging past threshold executes onConfirmed exactly once', (tester) async {
      int confirmedCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: SlideToConfirm(
                label: 'Slide to Confirm',
                onConfirmed: () async {
                  confirmedCount++;
                },
              ),
            ),
          ),
        ),
      );

      // Find thumb and drag to the right
      final thumbFinder = find.byIcon(Icons.arrow_forward_rounded);
      expect(thumbFinder, findsOneWidget);

      await tester.drag(thumbFinder, const Offset(280, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(confirmedCount, equals(1));
    });

    testWidgets('canceling drag before threshold snaps back without executing', (tester) async {
      int confirmedCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: SlideToConfirm(
                label: 'Slide to Confirm',
                onConfirmed: () async {
                  confirmedCount++;
                },
              ),
            ),
          ),
        ),
      );

      final thumbFinder = find.byIcon(Icons.arrow_forward_rounded);
      // Small drag, only 50 pixels (well below 88% threshold)
      await tester.drag(thumbFinder, const Offset(50, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(confirmedCount, equals(0));
    });
  });

  group('AnimatedCurrencyText Widget Tests', () {
    testWidgets('renders initial formatted value immediately', (tester) async {
      final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedCurrencyText(
              value: 150.00,
              formatter: formatter,
            ),
          ),
        ),
      );

      expect(find.text('\$150.00'), findsOneWidget);
    });

    testWidgets('smoothly interpolates value over animation duration', (tester) async {
      final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedCurrencyText(
              value: 100.00,
              formatter: formatter,
              duration: const Duration(milliseconds: 200),
            ),
          ),
        ),
      );

      expect(find.text('\$100.00'), findsOneWidget);

      // Update widget value to 200.00
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedCurrencyText(
              value: 200.00,
              formatter: formatter,
              duration: const Duration(milliseconds: 200),
            ),
          ),
        ),
      );

      // Halfway through animation (~100ms)
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('\$100.00'), findsNothing); // Has interpolated away from 100

      // Finish animation
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('\$200.00'), findsOneWidget);
    });
  });

  group('VoiceWaveformIndicator Widget Tests', () {
    testWidgets('renders idle state with mic icon and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceWaveformIndicator(
              state: VoiceState.idle,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Voice'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });

    testWidgets('renders listening state with listening text and wave animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceWaveformIndicator(
              state: VoiceState.listening,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Listening...'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('renders success state with check icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceWaveformIndicator(
              state: VoiceState.success,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Added!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders error state with retry text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceWaveformIndicator(
              state: VoiceState.error,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });

  group('StatusBadge Widget Tests', () {
    testWidgets('renders paid status with green styling and checkmark', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: 'paid',
            ),
          ),
        ),
      );

      expect(find.text('Paid'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders pending status with clock icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: 'pending',
            ),
          ),
        ),
      );

      expect(find.text('Pending'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('animates transition between statuses without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: 'pending',
            ),
          ),
        ),
      );

      expect(find.text('Pending'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: 'paid',
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Paid'), findsOneWidget);
    });
  });

  group('SyncStatusBadge & syncStatusProvider Tests', () {
    testWidgets('displays correct label and icon for synced state', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SyncStatusBadge(),
            ),
          ),
        ),
      );

      expect(find.text('Synced'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    });

    testWidgets('reacts to state changes in syncStatusProvider', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SyncStatusBadge(),
            ),
          ),
        ),
      );

      container.read(syncStatusProvider.notifier).markSynchronizing();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Syncing...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      container.read(syncStatusProvider.notifier).markOffline();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Offline'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });
  });

  group('BouncingButton Tests', () {
    testWidgets('renders child widget and responds to taps', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BouncingButton(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
