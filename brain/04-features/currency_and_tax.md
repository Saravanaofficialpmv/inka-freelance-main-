# 04. Features — Multi-Currency & Tax Engine

Inka supports global invoicing through `CurrencyConversionService` (`lib/services/currency_conversion_service.dart`) and `CurrencyTaxService` (`lib/services/currency_tax_service.dart`).

---

## 💱 Multi-Currency Architecture

Inka natively supports major global currencies:
- Indian Rupee (`INR` / `₹`)
- US Dollar (`USD` / `$`)
- Euro (`EUR` / `€`)
- British Pound (`GBP` / `£`)
- UAE Dirham (`AED` / `AED`)
- Canadian Dollar (`CAD` / `CA$`)
- Australian Dollar (`AUD` / `A$`)
- Singapore Dollar (`SGD` / `SG$`)

### Live Conversion Rates & Caching
`CurrencyConversionService` fetches real-time forex exchange rates:
1. Queries open exchange rate APIs.
2. Caches rates in memory and local storage with a 12-hour TTL.
3. Provides fallback offline base rates if the device is disconnected.
4. Allows converting an invoice total between currencies for international cross-border clients.

---

## 📊 Tax Calculation Engine (`CurrencyTaxService`)

Inka provides flexible tax calculations:
- **Inclusive vs Exclusive Tax**: Calculates tax on top of subtotal or back-calculates tax from gross.
- **Indian GST (CGST + SGST vs IGST)**:
  - Intra-state transaction: Splits GST into equal CGST (e.g. 9%) and SGST (9%).
  - Inter-state transaction: Applies full IGST (18%).
- **International VAT / Sales Tax**: Single-rate percentage calculation added to taxable subtotal.
- **Discount Handling**: Flat amount deductions applied either pre-tax or post-tax based on user preference.
