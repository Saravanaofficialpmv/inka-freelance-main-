# 02. Design System — Typography & Asset Guidelines

Inka uses a clear typographic hierarchy and scalable vector iconography to ensure readability across all screen densities.

---

## 🔤 Typography

Inka bundles premium modern sans-serif typography locally within `assets/fonts/` and configures them across `AppTheme`:

### Font Families
1. **Space Grotesk** (`assets/fonts/SpaceGrotesk/`):
   - Used for numbers, currency values, financial KPIs, and technical headers.
   - Characterized by crisp geometry and distinctive high-tech aesthetic.
2. **Inter**:
   - Used for core body copy, labels, table cells, form inputs, and secondary subtitles.
   - Optimized for small text sizes with maximum legibility.
3. **Poppins**:
   - Used for bold marketing headers, onboarding titles, and hero callouts.

### Type Scale Standards

| Style | Font Family | Size | Weight | Line Height | Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Display Large** | Space Grotesk | 32sp | Bold (700) | 1.2 | Total Revenue, Balance figures |
| **Headline Medium** | Poppins / Space Grotesk | 22sp | SemiBold (600) | 1.3 | Screen titles, Section headers |
| **Title Medium** | Inter | 16sp | SemiBold (600) | 1.4 | Card headers, Client names |
| **Body Large** | Inter | 14sp | Regular (400) | 1.5 | Item descriptions, Notes |
| **Body Medium** | Inter | 13sp | Medium (500) | 1.4 | Table rows, Dates, Statuses |
| **Label Small** | Inter | 11sp | SemiBold (600) | 1.2 | Badges, Category tags, Hints |

---

## 🖼️ Assets & Iconography

### 1. Brand Assets (`assets/branding/`)
- `assets/branding/icon_final.png`: App launcher icon and brand symbol.
- `assets/branding/inka.png`: High-resolution mascot and marketing artwork.

### 2. UI Iconography (`assets/icons/`)
- `assets/icons/nav/`: Bottom navigation bar icons (`home-4.png`, `bill.png`, `rating.png`, `graph.png`, `settings.png`).
- `assets/icons/profile/`: Settings menu icons (`building.png`, `bank-2.png`, `digital-signature.png`, `tax-free.png`, etc.).

### 3. Images & Media (`assets/images/`)
- `assets/images/logo.png`: Primary brand logo for invoices and headers.
- `assets/images/google.svg`: Vector Google OAuth provider logo.
- `assets/images/tibsy-dp-2.gif` & `tibsy-dp-3.gif`: Animated mascot avatars.

### 4. PDF Template Previews (`assets/templates/`)
- `template_modern.jpg`: Preview thumbnail for the Modern invoice layout.
- `template_professional.jpg`: Preview thumbnail for the Corporate 3-column layout.
- `template_legend.jpg`: Preview thumbnail for the e-Invoice layout with IRN QR.
- `template_compact.jpg`: Preview thumbnail for high-density retail bills.
- `template_evergreen.jpg`: Preview thumbnail for classic boxed trade bills.

### 5. Design Mockup References (`assets/references/template_mockups/`)
- Visual design mockups and UX references.

### 3. Audio & Voice Assets
- Speech-to-text integration uses system micro-haptics and audio feedback during live dictation.
