# 04. Features — Dynamic UPI Payments

Inka features a comprehensive **Unified Payments Interface (UPI)** engine (`lib/services/payment_qr_service.dart`) designed for instant, frictionless payment collection.

---

## ⚡ UPI URI Specification

Inka formats UPI links compliant with the National Payments Corporation of India (NPCI) specification:

```
upi://pay?pa={upiId}&pn={businessName}&am={amount}&cu=INR&tn={transactionNote}
```

- `pa`: Payee VPA (Virtual Payment Address, e.g. `business@okhdfcbank`)
- `pn`: Payee business/legal name
- `am`: Exact outstanding bill amount (formatted to 2 decimal places)
- `cu`: Currency code (default: `INR`)
- `tn`: Transaction note (e.g. `Payment for INV-0042`)

---

## 📲 Payment QR Sheet & In-App UI

When a client or business owner previews an invoice, tapping **Pay via UPI** opens `PaymentQrSheet`:

1. **Live High-Res QR Code**:
   Rendered with `qr_flutter` using error correction level `QrErrorCorrectLevel.M`.
2. **App Launcher Buttons**:
   Direct intent triggers to open popular installed UPI applications (Google Pay, PhonePe, Paytm, CRED).
3. **One-Tap Clipboard Copying**:
   Quick-copy buttons for UPI ID, Bank Account Number, and IFSC Code with haptic toast confirmation.
4. **PDF Embedding**:
   In addition to on-screen presentation, the exact same QR code is generated as a vector image and stamped on the printed/shared PDF invoice.
