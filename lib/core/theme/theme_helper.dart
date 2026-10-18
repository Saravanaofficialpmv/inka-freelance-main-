import 'package:flutter/material.dart';

extension AppThemeContext on BuildContext {
  /// Dark mode is removed completely; always returns false.
  bool get isDarkMode => false;

  /// Scaffold background color: crisp off-white in light mode.
  Color get scaffoldBg => const Color(0xFFF7F8FA);

  /// Card & container surface color: pure white in light mode.
  Color get cardBg => Colors.white;

  /// Border color for cards, buttons, and dividers.
  Color get cardBorder => const Color(0xFFE2E8F0);

  /// Primary high-contrast text color: deep slate in light mode.
  Color get textPrimary => const Color(0xFF0F172A);

  /// Secondary copy & subtitle text color.
  Color get textSecondary => const Color(0xFF64748B);

  /// Muted / watermark text color.
  Color get textMuted => const Color(0xFF94A3B8);

  /// Search bar container background.
  Color get searchBarBg => Colors.white;

  /// Form input background color.
  Color get inputBg => const Color(0xFFF1F5F9);

  /// Circular header & icon button background.
  Color get circleBtnBg => Colors.white;

  /// Secondary surface highlight background.
  Color get surfaceHighlight => const Color(0xFFF1F5F9);
}
