# 03. Data Models — Invoice & InvoiceItem

The `Invoice` (`lib/data/models/invoice.dart`, Hive TypeId: 1) and `InvoiceItem` (`lib/data/models/invoice_item.dart`, Hive TypeId: 2) models represent billable transactions.

---

## 📐 InvoiceItem Schema (TypeId: 2)

```dart
@HiveType(typeId: 2)
class InvoiceItem extends HiveObject {
  @HiveField(0) final String id;       // Unique item line ID
  @HiveField(1) final String name;     // Item or service description
  @HiveField(2) final int quantity;    // Billed quantity
  @HiveField(3) final double price;    // Unit price

  double get total => quantity * price;
}
```

---

## 📐 Invoice Schema (TypeId: 1)

```dart
@HiveType(typeId: 1)
class Invoice extends HiveObject {
  @HiveField(0)  final String id;                  // Unique Invoice UUID
  @HiveField(1)  final String invoiceNumber;       // Display reference (e.g. 'INV-001')
  @HiveField(2)  final Client client;              // Billed client entity
  @HiveField(3)  final List<InvoiceItem> items;    // Line items list
  @HiveField(4)  final DateTime issueDate;         // Creation timestamp
  @HiveField(5)  final DateTime dueDate;           // Payment due date
  @HiveField(6)  final double taxPercentage;       // GST / Tax rate (e.g. 18.0)
  @HiveField(7)  final double discount;            // Flat discount deduction
  @HiveField(8)  final String status;              // 'pending', 'paid', 'overdue', 'draft'
  @HiveField(9)  final String notes;               // Terms, conditions, payment instructions
  @HiveField(10) final String templateId;          // Active PDF design template (e.g. 'modern')
  @HiveField(11) final String currency;            // Currency code or symbol
  @HiveField(12) final String? poNumber;           // Client Purchase Order number
  @HiveField(13) final String? projectId;          // Linked project ID (if applicable)

  // Computed Financial Totals
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get taxAmount => subtotal * (taxPercentage / 100);
  double get total => (subtotal + taxAmount - discount).clamp(0.0, double.infinity);
}
```

---

## 🚦 Status Lifecycle

1. **`draft`**: Invoice is being composed and has not yet been delivered to the client.
2. **`pending`**: Invoice has been sent; payment has not yet been recorded.
3. **`overdue`**: Current date > `dueDate` and status is still `pending`.
4. **`paid`**: Client has settled the bill; recorded into revenue metrics.

---

## ⚙️ Persistence & State Management
- **Hive Box**: `invoices`
- **Riverpod ViewModel**: `invoiceViewModelProvider` (`lib/presentation/viewmodels/invoice_viewmodel.dart`)
- **Firestore Collection**: `/users/{uid}/invoices/{invoiceId}`
