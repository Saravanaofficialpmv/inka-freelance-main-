import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inka/core/theme/app_theme.dart';
import 'package:inka/core/theme/theme_helper.dart';

void main() {
  group('Theme Guarantees (Dark Mode Removed)', () {
    test('AppTheme.lightTheme has light brightness and correct color tokens', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, isNotNull);
    });

    testWidgets('AppThemeContext extension always reports isDarkMode as false', (tester) async {
      late bool isDark;
      late Color scaffoldColor;
      late Color cardColor;
      late Color textPrimaryColor;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              isDark = context.isDarkMode;
              scaffoldColor = context.scaffoldBg;
              cardColor = context.cardBg;
              textPrimaryColor = context.textPrimary;
              return const Scaffold(body: Text('Theme Check'));
            },
          ),
        ),
      );

      expect(isDark, isFalse);
      expect(scaffoldColor, const Color(0xFFF7F8FA));
      expect(cardColor, Colors.white);
      expect(textPrimaryColor, const Color(0xFF0F172A));
    });

    testWidgets('Even if platform brightness is dark, isDarkMode remains false', (tester) async {
      late bool isDark;

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(() {
        tester.platformDispatcher.clearPlatformBrightnessTestValue();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              isDark = context.isDarkMode;
              return const Scaffold(body: Text('Strict Light Mode'));
            },
          ),
        ),
      );

      expect(isDark, isFalse);
    });
  });
}
