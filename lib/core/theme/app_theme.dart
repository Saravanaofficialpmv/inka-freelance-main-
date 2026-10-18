import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';

class AppTheme {
  static const String fontFamily = 'SpaceGrotesk';

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: fontFamily,
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.card,
        onSurface: AppColors.textPrimary,
        secondary: AppColors.primaryLight,
        error: AppColors.error,
        outline: AppColors.border,
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: fontFamily, color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: fontFamily, color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontFamily: fontFamily, color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontFamily: fontFamily, color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontFamily: fontFamily, color: AppColors.textSecondary, fontSize: 14),
        bodySmall: TextStyle(fontFamily: fontFamily, color: AppColors.textMuted, fontSize: 12),
        labelSmall: TextStyle(fontFamily: fontFamily, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(fontFamily: fontFamily, color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSecondary,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
