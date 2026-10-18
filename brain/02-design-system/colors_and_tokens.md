# 02. Design System — Colors & Design Tokens

Inka employs a clean, modern, and high-contrast **Crisp White & Vibrant Inka Orange** visual theme (`#FF5722`), accented with **Vibrant Lime Green** (`#9BD71B`), deep slate charcoal, and subtle container fills.

All color definitions are centralized in `lib/core/constants/colors.dart` under the `AppColors` class.

---

## 🎨 Core Color Palette

| Token Name | Hex Code | Purpose / Usage |
| :--- | :--- | :--- |
| **Primary Orange** | `#FF5722` | Core brand identity, primary CTA buttons, active tabs |
| **Primary Light** | `#FF7A50` | Button gradients, hover highlights |
| **Primary Dark** | `#E64A19` | Pressed button states, high-contrast borders |
| **Accent Orange** | `#FF7A00` | Secondary orange accent, gradient stops |
| **Lime Accent** | `#9BD71B` | Secondary branding, high-visibility badges, KPI cards |
| **Lime Light** | `#A6E22E` | Highlight gradient stop for lime buttons |
| **Lime Background** | `#F3FAD6` | Soft container background for positive KPI metrics |
| **Dark Teal** | `#0D3B3E` | Hero cards, premium feature containers |
| **Dark Teal Light** | `#144D51` | Subtle gradient partner for dark teal surfaces |
| **Charcoal** | `#1E2128` | High-contrast contrast cards and floating nav pill |
| **Scaffold Background** | `#F7F8FA` | Clean, bright, distraction-free screen background |
| **Secondary Background** | `#FFFFFF` | Form surfaces, elevated headers |
| **Card Surface** | `#FFFFFF` | Primary card background, modals, bottom sheets |
| **Card Secondary** | `#F1F5F9` | Text fields, inactive chip fills, inner grouping boxes |
| **Card Border** | `#E2E8F0` | 1px clean card outlines, table rows, dividers |

---

## 🌈 Gradients

```dart
// Hero Gradient (Main creation buttons & headers)
static const List<Color> heroGradient = [
  Color(0xFFFF5722),
  Color(0xFFFFA000),
];

// Primary Gradient (CTA buttons)
static const List<Color> primaryGradient = [
  Color(0xFFFF5722),
  Color(0xFFFF8A50),
];

// Lime Gradient (Revenue & profit KPI cards)
static const List<Color> limeGradient = [
  Color(0xFF9BD71B),
  Color(0xFFA8E82E),
];
```

---

## 🚦 Status Indicators & Semantic Badges

| Semantic Status | Hex Code | Background Tint | Meaning & Placement |
| :--- | :--- | :--- | :--- |
| **Success (Paid / Active)** | `#10B981` | `#ECFDF5` | Paid invoices, positive cashflow margins, active projects |
| **Warning (Pending / Open)** | `#F59E0B` | `#FFFBEB` | Unpaid invoices, awaiting client response, due soon |
| **Error (Overdue / Danger)** | `#EF4444` | `#FEF2F2` | Past due dates, delete actions, cancellation alerts |
| **Draft / Inactive** | `#64748B` | `#F1F5F9` | Draft invoices, archived projects, inactive filters |

---

## 📝 Typography Color Tokens

| Token Name | Hex Code | Purpose / Usage |
| :--- | :--- | :--- |
| **Text Primary** | `#0F172A` | High-contrast slate charcoal for headlines, amounts, titles |
| **Text Secondary** | `#64748B` | Subtitles, date stamps, placeholder text, hints |
| **Text Muted** | `#94A3B8` | Watermarks, subtle helper text, disabled items |
| **Text On Dark** | `#FFFFFF` | Pure white text over dark charcoal cards or orange buttons |
| **Text On Dark Secondary** | `#CBD5E1` | Muted white text over dark charcoal surfaces |

---

## 📐 Elevation & Shadow Tokens

- **Standard Card Shadow**:
  `BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4))`
- **Floating Island Bar Shadow**:
  `BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 4))`
- **Primary CTA Orange Shadow**:
  `BoxShadow(color: Color(0x3DFF5722), blurRadius: 18, offset: Offset(0, 6))`
