import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  static const _key = 'selected_language';

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_key) ?? 'en';
    state = Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    state = locale;
  }
}

class LanguageData {
  final String name;
  final String code;
  final String flag;

  const LanguageData({required this.name, required this.code, required this.flag});
}

final languages = [
  const LanguageData(name: 'English', code: 'en', flag: '🇺🇸'),
  const LanguageData(name: 'Tamil', code: 'ta', flag: '🇮🇳'),
  const LanguageData(name: 'Hindi', code: 'hi', flag: '🇮🇳'),
  const LanguageData(name: 'Spanish', code: 'es', flag: '🇪🇸'),
];
