# 06. Developer Guides — Testing & Quality Assurance

Inka maintains a test suite covering unit calculations, navigation robustness, responsive layouts, and widget state.

---

## 🧪 Test Suite Overview (`test/`)

| Test File | Focus Area | Description |
| :--- | :--- | :--- |
| `test/safe_navigation_test.dart` | Navigation | Verifies route transitions, fallback navigators, and non-blocking redirects. |
| `test/web_desktop_layout_test.dart`| Responsiveness | Verifies sidebar rendering at `>= 800px` and mobile bottom bar rendering at `< 800px`. |
| `test/currency_conversion_test.dart`| Currency Engine | Tests exchange rate conversions, decimal rounding, and fallback rates. |
| `test/expense_profit_test.dart` | Financial KPIs | Tests net profit calculations, expense categorizations, and profit margin percentages. |
| `test/signature_pad_test.dart` | Signatures | Verifies touch point capture, clear canvas, and PNG export integrity. |
| `test/device_contact_service_test.dart`| Contacts | Verifies address book filtering, name extraction, and phone normalization. |
| `test/clients_screen_test.dart` | Clients UI | Tests client creation dialogs, search filter queries, and selection mode. |
| `test/business_setup_screen_test.dart`| Onboarding UI | Tests initial setup form validation, currency dropdown, and bank info inputs. |

---

## 🏃 Running Tests

### Run All Unit & Widget Tests:
```bash
flutter test
```

### Run a Specific Test Suite:
```bash
flutter test test/safe_navigation_test.dart
```

### Static Analysis:
```bash
flutter analyze
```
Ensure zero lint errors or warnings before committing changes.
