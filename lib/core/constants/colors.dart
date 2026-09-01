import 'package:flutter/material.dart';

class AppColors {
  // Primary Accent: Vibrant Lime Green #9BD71B / #84CC16 (from Mockups)
  static const Color lime = Color(0xFF9BD71B);
  static const Color limeLight = Color(0xFFA6E22E);
  static const Color limeDark = Color(0xFF7CB518);
  static const Color limeBg = Color(0xFFF3FAD6);

  // Vibrant Inka Orange #FF5722 / #FF7A00
  static const Color primary = Color(0xFFFF5722);
  static const Color primaryLight = Color(0xFFFF7A50);
  static const Color primaryDark = Color(0xFFE64A19);
  static const Color accentOrange = Color(0xFFFF7A00);

  // Deep Teal & Charcoal (from Mockups)
  static const Color darkTeal = Color(0xFF0D3B3E);
  static const Color darkTealLight = Color(0xFF144D51);
  static const Color charcoal = Color(0xFF1E2128);
  
  // Hero Gradient
  static const List<Color> primaryGradient = [
    Color(0xFFFF5722),
    Color(0xFFFF8A50),
  ];

  static const List<Color> limeGradient = [
    Color(0xFF9BD71B),
    Color(0xFFA8E82E),
  ];

  static const List<Color> heroGradient = [
    Color(0xFFFF5722),
    Color(0xFFFFA000),
  ];

  // Backgrounds: Clean Crisp White & Soft Slate Off-White
  static const Color background = Color(0xFFF7F8FA);
  static const Color secondaryBackground = Color(0xFFFFFFFF);
  
  // Surfaces & Cards
  static const Color card = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFFFFFFFF);
  static const Color cardSecondary = Color(0xFFF1F5F9);
  static const Color cardBorder = Color(0xFFE2E8F0);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkSecondary = Color(0xFFCBD5E1);

  // Status Colors
  static const Color success = Color(0xFF10B981); // Paid / Received
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B); // Unpaid / Pending
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);   // Overdue / Over Budget
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color draft = Color(0xFF64748B);   // Draft
  static const Color draftBg = Color(0xFFF1F5F9);
  
  // Borders & Inputs
  static const Color border = Color(0xFFE2E8F0);
  static const Color inactive = Color(0xFFCBD5E1);
  static const Color searchBar = Color(0xFFF1F5F9);
  static const Color iconBg = Color(0xFFFFF0EB);

  // Compatibility / Opacity Helpers
  static Color get card70 => textSecondary.withValues(alpha: 0.7);
  static Color get card60 => textSecondary.withValues(alpha: 0.6);
  static Color get textPrimary87 => textPrimary.withValues(alpha: 0.87);
  static Color get textPrimary26 => textPrimary.withValues(alpha: 0.26);
  
  static const Color white = Colors.white;
}
