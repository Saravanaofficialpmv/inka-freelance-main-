# 00. Overview — Technology Stack & Dependencies

Inka is engineered on Flutter and Dart, adhering to modern reactive programming patterns and multiplatform support.

---

## 🛠️ Core Technology Stack

| Layer | Technology | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Framework** | **Flutter** | SDK `^3.11.4` | Cross-platform framework targeting iOS, Android, macOS, Windows, and Web. |
| **Language** | **Dart** | SDK `>=3.0.0 <4.0.0` | Strongly-typed object-oriented language. |
| **State Management** | **Flutter Riverpod** | `^2.4.0` | Dependency injection, reactive state, and ViewModels. |
| **Navigation** | **GoRouter** | `^17.2.0` | Declarative routing with deep linking and ShellRoute support. |
| **Local Storage** | **Hive & Hive Flutter** | `^2.2.3` / `^1.1.0` | High-performance, lightweight key-value NoSQL database. |
| **Code Generation** | **Hive Generator & Build Runner**| `^2.0.1` / `^2.4.6` | Automatic TypeAdapter generation (`.g.dart`). |
| **Cloud Backend** | **Firebase Core** | `^4.6.0` | Cross-platform Firebase engine initialization. |
| **Cloud Database** | **Cloud Firestore** | `^6.2.0` | Real-time multi-device cloud database with offline caching. |
| **Authentication** | **Firebase Auth** | `^6.3.0` | User account management and session persistence. |
| **Social Auth** | **Google Sign-In & Apple** | `^6.2.2` / `^8.1.0` | One-tap authentication with crypto nonces for Apple ID. |
| **Document Engine** | **PDF & Printing** | `^3.10.5` / `^5.11.0` | A4 vector PDF layout, system print dialogs, and sharing. |
| **Payments & Barcode**| **QR Flutter & Barcode** | `^4.1.0` / `^2.2.8` | Dynamic UPI string rendering and vector barcode drawing. |
| **Voice AI** | **Speech to Text** | `^7.3.0` | On-device and cloud speech-to-text dictation. |
| **Device Contacts** | **Flutter Contacts** | `^1.1.9+2` | Permission-based device address book integration. |
| **Localization** | **Flutter Localizations** | SDK built-in | Multilingual translation engine (EN, TA, HI, ES). |
| **Typography** | **Google Fonts** | `^6.2.1` | Space Grotesk, Inter, and Poppins font rendering. |

---

## 📦 Key Runtime Dependencies Breakdown

### 1. State & Reactive Binding
- `flutter_riverpod: ^2.4.0`: Provides `StateNotifierProvider` for collections (Invoices, Expenses, Projects, TimeEntries) and `StateProvider` for reactive filters and active tabs.

### 2. Offline-First Storage
- `hive: ^2.2.3` and `hive_flutter: ^1.1.0`: Stores all user documents locally with near-instant reads and writes. Protected by fault-tolerant auto-recovery routines.

### 3. PDF Generation & Printing
- `pdf: ^3.10.5`: Vector layout engine utilizing `pdf/widgets.dart` for pixel-perfect A4 canvas generation.
- `printing: ^5.11.0`: Native OS bridge providing print preview, hardware printer spooling, and OS share sheet invocation.

### 4. Device Features
- `speech_to_text: ^7.3.0`: Captures voice commands to parse line items and dictations.
- `flutter_contacts: ^1.1.9+2`: Reads device address book for one-tap client contact imports.
- `image_picker: ^1.2.1`: Allows picking company logos and signatures from the gallery or camera.
- `url_launcher: ^6.3.1`: Launches UPI intent apps, WhatsApp direct chats, phone dialers, and email composers.
