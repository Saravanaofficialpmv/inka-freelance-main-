# 03. Data Models — Expenses & Profit Calculation

The `Expense` model (`lib/data/models/expense.dart`, Hive TypeId: 6) allows users to record outgoing expenditures, track cash outflows, and compute real-time net profit margins alongside invoice revenue.

---

## 📐 Entity Schema

```dart
@HiveType(typeId: 6)
class Expense extends HiveObject {
  @HiveField(0) final String id;            // Unique Expense UUID
  @HiveField(1) final String title;         // Expense description (e.g. 'Figma Subscription')
  @HiveField(2) final double amount;        // Outflow amount
  @HiveField(3) final String category;      // 'Software', 'Contractor', 'Office', 'Marketing', 'Travel', 'Equipment', 'Other'
  @HiveField(4) final DateTime date;        // Expense date
  @HiveField(5) final String notes;         // Supplementary notes or receipts info
  @HiveField(6) final String paymentMethod; // 'Credit Card', 'Bank Transfer', 'UPI', 'Cash', 'Other'
}
```

---

## 📈 Net Profit & Margin Computation

In `lib/presentation/viewmodels/expense_viewmodel.dart` and `dashboard_screen.dart`, financial statistics are aggregated:

$$\text{Total Revenue} = \sum \text{Invoice.total} \quad (\text{where status} = \text{'paid'})$$
$$\text{Total Expenses} = \sum \text{Expense.amount}$$
$$\text{Net Profit} = \text{Total Revenue} - \text{Total Expenses}$$
$$\text{Profit Margin} = \left(\frac{\text{Net Profit}}{\text{Total Revenue}}\right) \times 100\%$$

---

## ⚙️ Persistence & State Management
- **Hive Box**: `expenses`
- **Riverpod ViewModel**: `expenseViewModelProvider` (`lib/presentation/viewmodels/expense_viewmodel.dart`)
- **Firestore Collection**: `/users/{uid}/expenses/{expenseId}`
