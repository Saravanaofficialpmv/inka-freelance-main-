# 03. Data Models — Hive TypeId Registry

Inka uses **Hive** for fast binary local storage. Each persistent entity model is mapped to a unique `typeId`.

---

## 📋 Hive TypeId Allocation Table

| TypeId | Entity Class | File Location | Box Name | Adapter Class |
| :---: | :--- | :--- | :--- | :--- |
| **0** | `Client` | `lib/data/models/client.dart` | `clients` | `ClientAdapter` |
| **1** | `Invoice` | `lib/data/models/invoice.dart` | `invoices` | `InvoiceAdapter` |
| **2** | `InvoiceItem` | `lib/data/models/invoice_item.dart` | (Embedded in `Invoice`) | `InvoiceItemAdapter` |
| **3** | *(Reserved)* | — | — | — |
| **4** | `BusinessProfile` | `lib/data/models/business_profile.dart` | `business_profile` | `BusinessProfileAdapter`|
| **5** | `Product` | `lib/data/models/product.dart` | `products` | `ProductAdapter` |
| **6** | `Expense` | `lib/data/models/expense.dart` | `expenses` | `ExpenseAdapter` |
| **7** | `TimeEntry` | `lib/data/models/time_entry.dart` | `time_entries` | `TimeEntryAdapter` |
| **8** | `Project` | `lib/data/models/project.dart` | `projects` | `ProjectAdapter` |

> ⚠️ **Critical Guideline for Future Models**:
> Any new model added to the codebase **MUST** claim `typeId: 9` or higher. Re-using an existing TypeId will corrupt existing local user data.

---

## 🛡️ Safe Registration Protocol

To prevent `HiveError: There is already a TypeAdapter for typeId ...` during hot reloads or test suites, adapters are registered conditionally in `lib/main.dart`:

```dart
if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ClientAdapter());
if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(InvoiceAdapter());
if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InvoiceItemAdapter());
if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(BusinessProfileAdapter());
if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ProductAdapter());
if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(ExpenseAdapter());
if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(TimeEntryAdapter());
if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(ProjectAdapter());
```

---

## 🔄 Generating Hive Adapters

When modifying field annotations (`@HiveField(n)`) on any model:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
