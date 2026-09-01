# 📦 PROJECT KNOWLEDGE BASE: INKA INVOICING & BILLING APP

> **Document Purpose**: This comprehensive knowledge base provides complete architectural, functional, structural, and technical context about the **Inka** application. Feed this document to any Large Language Model (LLM) as system instructions or contextual background to generate features, fix bugs, refactor code, or understand the system instantly.

---

## 1. Executive Summary

- **App Name**: **Inka** (`inka`)
- **Tagline**: Create Professional Invoices in Seconds
- **Target Audience**: Freelancers, small business owners, contractors, service providers, and vendors.
- **Core Value Proposition**: An ultra-fast, offline-first mobile and desktop invoicing platform. It features instant tax-compliant A4 PDF generation, dynamic UPI QR code payments, speech-to-text voice dictation, business branding, client and product catalogs, financial analytics, and seamless real-time cloud backup with Firebase.

---

## 2. Technology Stack & Key Dependencies

| Category | Technology / Package | Version / Description |
| :--- | :--- | :--- |
| **Framework** | **Flutter / Dart** | SDK `^3.11.4`, Multiplatform (Android, iOS, macOS, Windows, Web) |
| **State Management** | **Flutter Riverpod** | `flutter_riverpod: ^2.4.0` (StateNotifier, Provider, StateProvider) |
| **Navigation & Routing** | **GoRouter** | `go_router: ^17.2.0` (Declarative routing, ShellRoute for bottom navigation) |
| **Local Storage (Offline-First)** | **Hive & Hive Flutter** | `hive: ^2.2.3`, `hive_flutter: ^1.1.0` (NoSQL key-value database with TypeAdapters) |
| **Cloud Backend & Auth** | **Firebase Suite** | `firebase_core: ^4.6.0`, `firebase_auth: ^6.3.0`, `cloud_firestore: ^6.2.0` |
| **Social / Native Auth** | **Google & Apple Sign-In** | `google_sign_in: ^6.2.2`, `sign_in_with_apple: ^8.1.0`, `crypto: ^3.0.7` |
| **PDF & Printing** | **PDF & Printing** | `pdf: ^3.10.5`, `printing: ^5.11.0` (Vector A4 PDF layout, printing, and sharing) |
| **Voice & Speech-to-Text** | **Speech to Text** | `speech_to_text: ^7.3.0`, `permission_handler: ^12.0.1` |
| **QR Code Engine** | **QR Flutter & Barcode** | `qr_flutter: ^4.1.0` (Dynamic UPI string QR generation) |
| **Internationalization (i18n)** | **Flutter Localization** | Multi-language support: English (`en`), Tamil (`ta`), Hindi (`hi`), Spanish (`es`) |
| **Asset & Image Handling** | **Image Picker & SVG** | `image_picker: ^1.2.1`, `flutter_svg: ^2.0.9` |
| **Typography** | **Google Fonts** | Inter & Poppins (bundled as local assets) |

---

## 3. System Architecture & Design Pattern

Inka follows a **Clean Architecture / Layered Architecture** with an **Offline-First Reactive Data Flow**:

```
 ┌────────────────────────────────────────────────────────┐
 │                     PRESENTATION                       │
 │  Screens (UI) ──► Riverpod Notifiers / StateProviders  │
 └───────────────────────────┬────────────────────────────┘
                             │
                             ▼
 ┌────────────────────────────────────────────────────────┐
 │                      SERVICES                          │
 │  FirestoreService (Cloud Sync) │ PdfService │ Speech    │
 └───────────────────────────┬────────────────────────────┘
                             │
                             ▼
 ┌────────────────────────────────────────────────────────┐
 │                        DATA                            │
 │  Hive Local Boxes (Clients, Invoices, Profile, Products)│
 │  Data Models & TypeAdapters (.g.dart)                  │
 └───────────────────────────┘
```

### Offline-First & Bi-Directional Synchronization Pattern
1. **Immediate Local Mutation**: When a user creates/updates a client, product, business profile, or invoice, it is written immediately into the corresponding local Hive box.
2. **Instant UI Reaction**: StateNotifiers update state from Hive, delivering zero-latency UI updates.
3. **Background Cloud Sync**: The operation triggers `FirestoreService` to mirror the change into Cloud Firestore under the user's sandboxed document hierarchy (`/users/{uid}/...`).
4. **Auth State Sync**: On login/signup or app resume, `authProvider` triggers `_syncAndRefresh(uid)` which fetches remote Firestore data, reconciles it with Hive, and notifies all providers.

---

## 4. Data Models & Entity Schemas

### 1. `BusinessProfile` (`lib/data/models/business_profile.dart`, Hive TypeId: 4)
Holds the user's business metadata, bank info, and branding.
- `businessName` (`String`): Company or freelancer trading name.
- `address` (`String`): Full street, city, pin/zip code.
- `phone` (`String`): Contact number.
- `email` (`String`): Business email.
- `currency` (`String`): Currency symbol (e.g., `₹`, `$`, `€`, `£`). Default: `$`.
- `logoUrl` (`String?`): Local file path or cloud URI of business logo.
- `gstNumber` (`String?`): GSTIN or tax registration number.
- `accountHolderName` (`String?`): Bank account payee name.
- `accountNo` (`String?`): Bank account number.
- `ifscCode` (`String?`): IFSC / Routing / SWIFT code.
- `bankName` (`String?`): Bank institution name.
- `branchName` (`String?`): Bank branch name.
- `upiId` (`String?`): Virtual Payment Address for UPI (e.g. `business@okhdfcbank`).
- `upiNumber` (`String?`): Phone/UPI linked number.
- `signatureUrl` (`String?`): File path of uploaded authorized digital signature.

### 2. `Client` (`lib/data/models/client.dart`, Hive TypeId: 0)
- `id` (`String`): Unique identifier (UUID / Timestamp).
- `name` (`String`): Client or company contact name.
- `phone` (`String`): Phone number.
- `email` (`String`): Email address.
- `address` (`String`): Physical billing / shipping address.
- `gstNumber` (`String?`): Optional client GSTIN.

### 3. `Product` (`lib/data/models/product.dart`, Hive TypeId: 5)
- `id` (`String`): Unique product ID.
- `name` (`String`): Product/service title.
- `defaultPrice` (`double`): Standard unit cost.
- `description` (`String?`): Optional item summary.
- `category` (`String?`): Tag/group classification.

### 4. `InvoiceItem` (`lib/data/models/invoice_item.dart`, Hive TypeId: 2)
- `id` (`String`): Item line ID.
- `name` (`String`): Line item title.
- `quantity` (`int`): Quantity ordered.
- `price` (`double`): Price per unit.
- **Computed**: `double get total => quantity * price;`

### 5. `Invoice` (`lib/data/models/invoice.dart`, Hive TypeId: 1)
- `id` (`String`): Unique invoice ID.
- `invoiceNumber` (`String`): Display numbering (e.g., `INV-001`).
- `client` (`Client`): Nested client object.
- `items` (`List<InvoiceItem>`): List of billed line items.
- `issueDate` (`DateTime`): Timestamp of creation.
- `dueDate` (`DateTime`): Payment deadline.
- `taxPercentage` (`double`): Applicable GST/Tax rate (e.g., 18.0).
- `discount` (`double`): Flat discount deduction.
- `status` (`String`): Status enum string (`'pending'`, `'paid'`, `'overdue'`).
- `notes` (`String`): Custom terms, notes, or payment instructions.
- **Computed Properties**:
  - `double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);`
  - `double get taxAmount => subtotal * (taxPercentage / 100);`
  - `double get total => subtotal + taxAmount - discount;`

---

## 5. Cloud Firestore Database Schema & Security

### Security Rules (`firestore.rules`):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Document Tree:
```
users/
 └── {userId}/
      ├── profile/
      │    └── business              --> Map<String, dynamic> (BusinessProfile)
      ├── clients/
      │    └── {clientId}           --> Map<String, dynamic> (Client)
      ├── products/
      │    └── {productId}          --> Map<String, dynamic> (Product)
      └── invoices/
           └── {invoiceId}          --> Map<String, dynamic> (Invoice)
```

---

## 6. Core Features & Screen Flows

```
                        ┌──────────────┐
                        │ SplashScreen │
                        └──────┬───────┘
                               │
               ┌───────────────┴───────────────┐
       (Not Authenticated)             (Authenticated)
               ▼                               ▼
       ┌───────────────┐              ┌──────────────────┐
       │Onboarding/Auth│              │ Business Setup?  │
       └───────┬───────┘              └────────┬─────────┘
               │                               │
               └───────────────┬───────────────┘
                               ▼
            ┌──────────────────────────────────────┐
            │       ShellRoute (NavShell)          │
            ├──────────────────────────────────────┤
            │  /dashboard       -> DashboardScreen │
            │  /history         -> InvoicesHistory │
            │  /create-invoice  -> CreateInvoice   │
            │  /profile         -> ProfileScreen   │
            └──────────────────┬───────────────────┘
                               │
            ┌──────────────────┴───────────────────┐
            │ Extra Routes                         │
            ├──────────────────────────────────────┤
            │  /preview         -> InvoicePreview  │
            │  /clients         -> ClientsScreen   │
            │  /products        -> ProductsScreen  │
            └──────────────────────────────────────┘
```

### 1. Splash & Auth Flow
- `SplashScreen`: Verifies Firebase session. If logged in, checks whether a `BusinessProfile` exists locally or in Firestore. If new, directs to `/business-setup`; otherwise opens `/dashboard`.
- `AuthScreen`: Handles Email/Password sign in & registration, Google One-Tap Sign In, and Apple ID sign in (with SHA-256 nonces for iOS integrity).

### 2. Business Setup & Customization
- Allows uploading business logos and authorized signatures.
- Stores banking particulars (Account #, IFSC, Bank, Branch) and UPI ID.
- Configures default currency symbol and GSTIN.

### 3. Invoice Creation & Voice AI Input (`CreateInvoiceScreen`)
- **Client Selection**: Quick-select modal or navigate to full client directory.
- **Item Entry**: Add manually or pick items from the saved Product catalog.
- **Voice Commands**: Integrated `SpeechToText` voice recognition. Commands like *"Add Laptop for 1500"* auto-parse items and price directly into the invoice.
- **Voice Notes**: Speak notes directly into the footer remarks.
- **Live Calculations**: Subtotal, GST/Tax, flat discount, and final net payable update live.

### 4. PDF Generation & Dynamic UPI Payment Engine (`PdfService`)
- Builds high-resolution A4 Tax Invoices conforming to international / Indian GST invoicing norms.
- Generates **Dynamic UPI QR Code** directly on the PDF:
  `upi://pay?pa={upiId}&pn={businessName}&am={totalAmount}&cu=INR`
- Auto-translates invoice total into capitalized words (e.g. *INR One Thousand Five Hundred Only*).
- Embeds business logo, bank account table, authorized digital signature, terms and conditions.
- Native Print and System Share sheet support via `Printing.layoutPdf` and `Printing.sharePdf`.

### 5. Analytics & Dashboard (`DashboardScreen`)
- Timeframe filter options: `Today`, `Last 7 Days`, `Last 30 Days`, `All Time`.
- Computes Total Revenue, Collected Revenue (Paid), Unpaid Revenue, Overdue count, and percentage growth compared to previous period.
- Recent notifications bottom sheet and quick action buttons.

### 6. Client & Product Directory
- Real-time search filters by name, phone, email, or category.
- Full CRUD support with dual-mode screen support (`isSelectionMode: true` for picking directly into invoice drafts).

### 7. Multi-Language Support (Localization)
- 4 supported locales: English (`en`), Tamil (`ta`), Hindi (`hi`), Spanish (`es`).
- Persisted via `SharedPreferences` and updated in real-time through `localeProvider`.

---

## 7. Project Directory Sitemap

```
lib/
├── main.dart                          # Entrypoint: Hive init, GoRouter config, Riverpod ProviderScope
├── firebase_options.dart              # FlutterFire generated config
├── core/
│   ├── constants/
│   │   └── colors.dart                # AppColors (Primary Coral #FF533D, Dark Card #141414, Soft Grey #F4F4F4)
│   ├── localization/
│   │   └── app_localizations.dart     # Multilingual translation dictionary (EN, TA, HI, ES)
│   ├── theme/
│   │   └── app_theme.dart             # Material 3 light & dark theme definitions
│   └── utils/
│       └── error_handler.dart         # User-friendly Firebase auth error message parser
├── data/
│   └── models/
│       ├── business_profile.dart      # Business profile model & Hive adapter (typeId: 4)
│       ├── client.dart                # Client model & Hive adapter (typeId: 0)
│       ├── invoice.dart               # Invoice model & Hive adapter (typeId: 1)
│       ├── invoice_item.dart          # InvoiceItem model & Hive adapter (typeId: 2)
│       └── product.dart               # Product catalog model & Hive adapter (typeId: 5)
├── domain/                            # Extensible domain layer for future Clean Architecture usecases
├── presentation/
│   ├── providers/
│   │   ├── auth_provider.dart         # FirebaseAuth state, Google/Apple sign in, auto-sync
│   │   ├── client_provider.dart       # Clients list state notifier & search filter provider
│   │   ├── locale_provider.dart       # Language selection & SharedPreferences persistence
│   │   ├── product_provider.dart      # Products catalog state notifier & filter provider
│   │   └── profile_provider.dart      # Business profile state notifier & Hive updater
│   ├── viewmodels/
│   │   └── invoice_viewmodel.dart     # Invoices state notifier, CRUD, dashboard analytics provider
│   ├── screens/
│   │   ├── splash_screen.dart         # App launch & auth state router
│   │   ├── onboarding_screen.dart     # Welcome onboarding slider
│   │   ├── auth_screen.dart           # Login, Register, Google, Apple auth UI
│   │   ├── business_setup_screen.dart # Initial business profile setup screen
│   │   ├── dashboard_screen.dart      # Main dashboard with financial stats & charts
│   │   ├── create_invoice_screen.dart # Invoice builder with voice input & catalog picker
│   │   ├── invoice_preview_screen.dart# Full PDF preview, sharing, printing
│   │   ├── clients_screen.dart        # Client manager & selector modal
│   │   ├── products_screen.dart       # Product catalog manager & selector modal
│   │   └── profile_screen.dart        # Business profile settings, bank info, language switcher
│   └── widgets/
│       ├── custom_bottom_nav.dart     # Floating dark pill navigation bar with active animation
│       ├── nav_shell.dart             # GoRouter ShellRoute scaffold wrapper
│       └── rounded_card.dart          # Custom card wrapper
└── services/
    ├── firestore_service.dart         # Firebase Firestore CRUD & full bidirectional synchronization
    └── pdf_service.dart               # Vector PDF generation, UPI QR generation, Print/Share integration
```

---

## 8. Design System & Style Guide

- **Primary Color**: `#FF533D` (Vibrant Coral/Orange)
- **Background**: `#F4F4F4` (Clean Minimalist Soft Grey)
- **Cards & Surfaces**: `#FFFFFF` (Secondary White) & `#141414` (Neo-Dark Contrast Hero Cards)
- **Success / Status**: `#4CAF50` (Paid/Active), `#E53935` (Overdue/Error), `#FFB300` (Pending/Warning)
- **Typography**: Inter for numbers, body text & labels; Poppins for bold headers.
- **Card Aesthetics**: 20–24px rounded corners (`BorderRadius.circular(24)`), soft elevation shadows (`Offset(0, 8)`, `blurRadius: 15`, `opacity: 0.05`).
- **Navigation**: Floating translucent dark pill (`Color(0xFF1A1A1A).withOpacity(0.95)`) pinned at screen bottom.

---

## 9. Developer & LLM Guidelines for Extending the Codebase

1. **Adding New Models**:
   - Assign a unique `@HiveType(typeId: N)` (Currently 0, 1, 2, 4, 5 are taken; use 6+).
   - Implement `toMap()` and `fromMap(Map<String, dynamic>)` methods for Firestore serialization.
   - Register adapter in `main.dart` with guard `if (!Hive.isAdapterRegistered(N)) Hive.registerAdapter(MyAdapter());`.
2. **State Management Protocol**:
   - Always update local Hive box first, then state, then invoke `firestoreService.saveX()` asynchronously.
   - Use Riverpod `StateNotifierProvider` for collections and `StateProvider` for transient UI states (e.g. search queries, active tabs).
3. **Route Navigation**:
   - Add new top-level screens in `main.dart` `routerProvider`.
   - If screen should have bottom navigation, nest inside `ShellRoute` routes array.
4. **PDF Invoice Modifications**:
   - Edit `lib/services/pdf_service.dart`.
   - Never use standard Flutter widgets inside `pdf_service.dart`; strictly use `pdf/widgets.dart as pw`.
   - Respect printable bounds (A4 format: 595.28 x 841.89 pt with 32pt margins).
5. **Localization**:
   - Add key-value translations to `AppLocalizations._localizedValues` in `lib/core/localization/app_localizations.dart` across all supported languages (`en`, `ta`, `hi`, `es`).
