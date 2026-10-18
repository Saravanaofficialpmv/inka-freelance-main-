# 04. Features — Invoice Builder & Vector PDF Engine

The invoicing pipeline in Inka is driven by `CreateInvoiceScreen` (`lib/presentation/screens/create_invoice_screen.dart`) and `PdfService` (`lib/services/pdf_service.dart`).

---

## 🏗️ Invoice Creation Flow

```
1. Select Client ──► (Quick-select dropdown, direct entry, or Device Contacts)
2. Add Line Items ──► (Manual entry, Product catalog picker, or Voice Dictation)
3. Taxes & Discount ──► (Configurable GST/VAT/Sales Tax rate & flat discount)
4. Dates & PO Number ──► (Issue Date, Due Date, and optional Client PO reference)
5. Notes & Signatures ──► (Saved default terms & digital touch signature)
6. Preview & Export ──► (Instant vector A4 preview, Print dialog, or PDF Share)
```

---

## 🎨 10+ Vector PDF Templates in `PdfService`

Inka renders true vector PDFs conforming to A4 dimensions (595.28 x 841.89 points, 32pt margins) using `pdf/widgets.dart`. Each layout is tailored for specific commercial industries:

| Template ID | Name | Primary Color | Target Use Case | Key Visual Features |
| :--- | :--- | :--- | :--- | :--- |
| `modern` | **Modern** | `#FF9900` | Freelancers & Startups | Crisp orange header banner, clean item rows, bold total box |
| `professional`| **Professional** | `#0284C7` | Corporate B2B | 3-column header, corporate seal/stamp, formal banking grid |
| `billto_shipto`| **Bill To / Ship To**| `#2563EB` | Logistics & E-Commerce | Dual side-by-side dispatch and billing address cards |
| `legend` | **Legend** | `#0F172A` | Official e-Invoicing | IRN number, e-Invoice QR code, tax breakdown matrix |
| `service_2` | **Service Template 2**| `#0D9488` | IT & Consulting | Milestone and hourly task descriptions with teal accents |
| `compact` | **Compact** | `#DC2626` | Retail & Supermarkets | High-density lines, minimal whitespace, receipt format |
| `evergreen` | **Evergreen** | `#16A34A` | Trade & Manufacturing | Traditional bordered boxes, HSN/SAC codes, CGST/SGST tables |
| `classic` | **Classic** | `#1E3A8A` | Legal & Finance | Deep navy header, serif/sans-serif hybrid typography |
| `elegant_images`| **Elegant with Images**| `#18181B`| Visual Product Catalogs| Embedded product thumbnail photos alongside line items |
| `service` | **Service Template** | `#E11D48` | Creative Agencies | Minimalist header, bold typography, integrated UPI QR card |

---

## ⚙️ Key Technical Features in `PdfService`

1. **Dynamic UPI QR Code Generation**:
   The payment QR code is drawn directly as a vector image on the PDF:
   ```dart
   final upiUrl = PaymentQrService.generateUpiUrl(
     upiId: profile.upiId ?? '',
     payeeName: profile.businessName,
     amount: invoice.total,
     note: 'Invoice ${invoice.invoiceNumber}',
   );
   final qrImage = await PaymentQrService.generateQrImage(upiUrl);
   ```
2. **Number to Words Conversion**:
   Automatically translates numerical totals into words (e.g. `INR One Thousand Five Hundred Only`) to satisfy legal invoice requirements.
3. **Embedded Signatures & Logos**:
   Rasterizes local image files or network URLs into `pw.MemoryImage` and embeds them safely with aspect ratio preservation.
4. **Native Printing & System Sharing**:
   Uses `Printing.layoutPdf` for native OS print dialogs and `Printing.sharePdf` for air-drop, email, and messaging attachments.
