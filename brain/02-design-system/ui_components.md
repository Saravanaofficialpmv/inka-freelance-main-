# 02. Design System — UI Components & Widgets

Inka implements a set of specialized, reusable UI components that give the app its distinctive feel.

---

## 🧩 Key Reusable Components

### 1. RoundedCard (`lib/presentation/widgets/rounded_card.dart`)
- **Purpose**: Foundation container for all list items, financial metrics, and form sections.
- **Specifications**:
  - Background: `AppColors.card` (`#FFFFFF`)
  - Border: 1px `AppColors.cardBorder` (`#E2E8F0`)
  - Corner Radius: 16–20px (`BorderRadius.circular(16)`)
  - Shadow: Soft atmospheric drop shadow (`blurRadius: 16, offset: Offset(0, 4)`)

### 2. CustomBottomNav (`lib/presentation/widgets/custom_bottom_nav.dart`)
- **Purpose**: Floating navigation pill anchored at the bottom of mobile screens.
- **Specifications**:
  - Background: Deep Charcoal (`#1E2128`) with backdrop blur.
  - Active Tab: Inka Orange pill background (`#FF5722`) with smooth animated slide transition.
  - Center Action: Elevated "+" button with hero gradient (`#FF5722` to `#FFA000`) for instantaneous invoice creation.

### 3. WebSidebar (`lib/presentation/widgets/web_sidebar.dart`)
- **Purpose**: Fixed-width navigation drawer (260px) for desktop and web browsers (>= 800px viewport).
- **Features**:
  - Embedded Inka logo and version tag.
  - Grouped navigation links: Core (Dashboard, Invoices, Clients), Management (Projects, Time Tracker, Expenses), Settings (Company, Bank, Signatures, Language).
  - User profile badge with quick sign-out action.

### 4. SignaturePad & Modal (`lib/presentation/widgets/signature_pad.dart`)
- **Purpose**: Touch-screen drawing canvas for capturing digital signatures.
- **Features**:
  - `CustomPainter` rendering smooth bezier curves from touch coordinates.
  - Undo, Clear, and Save actions.
  - Exports directly to high-resolution transparent PNG `Uint8List` for persistent storage and PDF printing.

### 5. PaymentQrSheet (`lib/presentation/widgets/payment_qr_sheet.dart`)
- **Purpose**: Instant modal bottom sheet displaying payment QR and account particulars.
- **Features**:
  - Live vector QR code rendered with `qr_flutter`.
  - Copy buttons for UPI ID, Bank Account Number, and IFSC Code with haptic toast feedback.
  - Amount pre-filled in UPI link.

### 6. CurrencyTaxSheet (`lib/presentation/widgets/currency_tax_sheet.dart`)
- **Purpose**: Reusable configuration sheet for toggling invoice currencies, tax percentages (GST/VAT/Sales Tax), and flat discounts.
