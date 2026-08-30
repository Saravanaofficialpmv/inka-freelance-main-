import 'package:flutter/material.dart';

class AppColors {
  // Primary Reference: Orange/Red #FF533D
  static const Color primary = Color(0xFFFF533D);
  
  // Backgrounds: Soft White #F4F4F4
  static const Color background = Color(0xFFF4F4F4);
  static const Color secondaryBackground = Color(0xFFFFFFFF);
  
  // Surfaces: Solid Black/Near Black for main cards
  static const Color darkCard = Color(0xFF141414);
  static const Color card = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF7D7D7D);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkSecondary = Color(0xFFA0A0A0);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB300);
  
  // Border
  static const Color border = Color(0xFFE5E5E5);
  static const Color inactive = Color(0xFFC4C4C4);

  // Compatibility / Opacity Helpers
  static Color get card70 => textSecondary.withOpacity(0.7);
  static Color get card60 => textSecondary.withOpacity(0.6);
  static Color get textPrimary87 => textPrimary.withOpacity(0.87);
  static Color get textPrimary26 => textPrimary.withOpacity(0.26);
  
  static const Color white = Colors.white;
}
