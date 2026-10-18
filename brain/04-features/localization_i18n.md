# 04. Features — Localization & Internationalization (i18n)

Inka is built to serve a diverse, international user base and provides real-time, dynamic multilingual support without requiring application restarts.

---

## 🌍 Supported Locales

| Locale Code | Language | Native Name | Script / Region |
| :--- | :--- | :--- | :--- |
| **`en`** | English | English | Latin (Global Default) |
| **`ta`** | Tamil | தமிழ் | Tamil (India, Sri Lanka, Singapore) |
| **`hi`** | Hindi | हिन्दी | Devanagari (India) |
| **`es`** | Spanish | Español | Latin (Spain, Latin America) |

---

## 🏗️ Architecture & State Flow

1. **`AppLocalizations` (`lib/core/localization/app_localizations.dart`)**:
   Contains dictionary maps of translation keys across all 4 supported languages.
2. **`localeProvider` (`lib/presentation/providers/locale_provider.dart`)**:
   A Riverpod `StateNotifier<Locale>` that reads and persists the active locale to device `SharedPreferences`.
3. **Reactive Rebuilds**:
   `MaterialApp.router` in `lib/main.dart` watches `localeProvider`. When a user toggles the language from `LanguageSettingsScreen`, the entire widget tree updates instantly with the new locale.
4. **Translated Invoicing Strings**:
   PDF templates and on-screen views translate core invoice headers: "Invoice", "Bill To", "Date", "Due Date", "Description", "Qty", "Rate", "Total", "Tax", "Discount", "Paid", "Pending".
