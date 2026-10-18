# 04. Features — Digital Signatures

Inka allows business owners to authorize invoices using digital signatures, complying with modern billing standards.

---

## ✍️ Signature Architecture

1. **Touch Signature Pad Canvas (`lib/presentation/widgets/signature_pad.dart`)**:
   - Implements a responsive touch drawing canvas with `CustomPainter`.
   - Records points as continuous smoothed bezier paths with anti-aliasing.
   - Supports variable stroke widths for natural penmanship.
   - Includes full Undo, Redo, and Clear controls.

2. **PNG Rasterization & Persistence**:
   - Canvas paths are rendered to an in-memory `ui.Image` and encoded as high-resolution transparent PNG bytes (`Uint8List`).
   - Saved locally to the device file system (`getApplicationDocumentsDirectory()`) and the file path is assigned to `BusinessProfile.signatureUrl`.
   - Optionally synchronized to Firebase Storage or base64 Firestore document for cross-device retrieval.

3. **PDF Document Stamping**:
   - `PdfService` checks `profile.signatureUrl`. If present, the image is loaded into `pw.MemoryImage` and rendered in the designated "Authorized Signatory" footer block of each PDF invoice template.
