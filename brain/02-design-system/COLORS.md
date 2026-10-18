# Inka Freelance App — Color Palette & Design Tokens

This document outlines the official design system for the **Inka Freelance & Invoice Generator** application, adopting a clean, modern, and high-contrast **White Background & Vibrant Orange** visual theme.

---

## 🎨 Core Color Tokens

| Token Name | Hex Code | Purpose / Usage |
| :--- | :--- | :--- |
| **Scaffold Background** | `#F8F9FA` | App-wide screen background (clean, bright, distraction-free) |
| **Card & Modal Surface** | `#FFFFFF` | Primary cards, modal bottom sheets, preview sheets, elevated containers |
| **Input Fill / Secondary Card**| `#F1F5F9` | Text fields, inactive chip fills, subtle sub-containers |
| **Borders & Dividers** | `#E2E8F0` | 1px clean card outlines, table rows, section dividers |
| **Primary Brand Orange** | `#FF5722` | Brand identity, primary CTA buttons, active icon highlights |
| **Orange Light** | `#FF7A50` | Button gradient start, active chip text, secondary accents |
| **Orange Gradient** | `[#FF5722, #FFA000]` | Hero CTA buttons, header gradients, floating creation buttons |
| **Orange Soft Tint / Glow** | `#FFF0EB` (`0x1AFF5722`)| Active filter chips, icon background circles, subtle accent containers |
| **Primary Text** | `#0F172A` | High-contrast dark charcoal headlines, amounts, and labels |
| **Secondary Text** | `#64748B` | Subtitles, date stamps, placeholder text, hints |
| **Muted Text** | `#94A3B8` | Watermarks, subtle helper hints |

---

## 🚦 Status Indicators & Semantic Badges

| Semantic Status | Hex Code | Background Tint | Meaning & Placement |
| :--- | :--- | :--- | :--- |
| **Success (Paid / Completed)** | `#10B981` | `#ECFDF5` | Paid invoices, positive cashflow margins, active projects |
| **Warning (Pending / Open)** | `#F59E0B` | `#FFFBEB` | Unpaid invoices, awaiting client response, due soon |
| **Error (Overdue / Danger)** | `#EF4444` | `#FEF2F2` | Past due dates, delete actions, cancellation alerts |
| **Draft / Inactive** | `#64748B` | `#F1F5F9` | Draft state, inactive features |

---

## 📐 Elevation & Shadow Tokens

- **Card Shadow**: `BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4))`
- **Floating Island Bar Shadow**: `BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 4))`
- **Primary CTA Orange Shadow**: `BoxShadow(color: Color(0x3DFF5722), blurRadius: 18, offset: Offset(0, 6))`
