# 05. Backend & Cloud — Firebase Firestore

Cloud Firestore serves as Inka's real-time remote data store and cross-device sync engine (`lib/services/firestore_service.dart`).

---

## 🌳 Firestore Document Hierarchy

All user data is completely sandboxed under the authenticated user's unique ID (`uid`):

```
users/
 └── {userId}/
      ├── profile/
      │    └── business            --> Map<String, dynamic> (BusinessProfile)
      ├── clients/
      │    └── {clientId}         --> Map<String, dynamic> (Client)
      ├── products/
      │    └── {productId}        --> Map<String, dynamic> (Product)
      ├── invoices/
      │    └── {invoiceId}        --> Map<String, dynamic> (Invoice + List<InvoiceItem>)
      ├── expenses/
      │    └── {expenseId}        --> Map<String, dynamic> (Expense)
      ├── projects/
      │    └── {projectId}        --> Map<String, dynamic> (Project)
      └── time_entries/
           └── {entryId}          --> Map<String, dynamic> (TimeEntry)
```

---

## ⚡ Firestore Service API (`FirestoreService`)

| Method | Target Path | Functionality |
| :--- | :--- | :--- |
| `saveBusinessProfile(uid, profile)` | `/users/{uid}/profile/business` | Sets business details using `SetOptions(merge: true)`. |
| `getBusinessProfile(uid)` | `/users/{uid}/profile/business` | Fetches saved profile record. |
| `saveInvoice(uid, invoice)` | `/users/{uid}/invoices/{id}` | Upserts an invoice document. |
| `deleteInvoice(uid, id)` | `/users/{uid}/invoices/{id}` | Deletes an invoice document. |
| `getInvoices(uid)` | `/users/{uid}/invoices` | Retrieves all invoices sorted by `issueDate`. |
| `saveClient(uid, client)` | `/users/{uid}/clients/{id}` | Upserts client document. |
| `deleteClient(uid, id)` | `/users/{uid}/clients/{id}` | Deletes client document. |
| `getClients(uid)` | `/users/{uid}/clients` | Retrieves all clients for user. |
| `saveProduct(uid, product)` | `/users/{uid}/products/{id}` | Upserts product record. |
| `saveExpense(uid, expense)` | `/users/{uid}/expenses/{id}` | Upserts expense record. |
| `saveProject(uid, project)` | `/users/{uid}/projects/{id}` | Upserts project record. |
| `saveTimeEntry(uid, entry)` | `/users/{uid}/time_entries/{id}` | Upserts time entry record. |
