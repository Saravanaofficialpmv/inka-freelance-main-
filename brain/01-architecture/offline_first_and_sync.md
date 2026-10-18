# 01. Architecture — Offline-First & Cloud Synchronization

One of Inka's fundamental architectural pillars is **zero-latency offline capability** combined with **seamless bi-directional cloud synchronization**.

---

## ⚡ The Offline-First Lifecycle

When a user performs any action (creating an invoice, logging an expense, saving a client, updating business profile):

```
User Action in UI
       │
       ▼
Riverpod ViewModel / Notifier
       │
       ├──────────────────────────────┐
       │ (Step 1: Synchronous)        │ (Step 2: Microtask)
       ▼                              ▼
Hive Local Storage             Update Riverpod State
[Instant persistence]          [Instant UI reaction]
       │
       │ (Step 3: Background Asynchronous)
       ▼
FirestoreService.syncX(...)
       │
       ├── Online  ──► Pushed directly to Cloud Firestore (/users/{uid}/...)
       └── Offline ──► Queued by Firestore offline cache, auto-synced on reconnect
```

---

## 🗄️ Local Storage with Hive

### Box Initialization & Safe Recovery
In `lib/main.dart`, all boxes are opened asynchronously with automated recovery logic:

```dart
Future<void> _safeOpenBox<T>(String name) async {
  try {
    await Hive.openBox<T>(name);
  } catch (e) {
    debugPrint('Hive openBox error for $name, attempting auto-recovery: $e');
    try {
      await Hive.deleteBoxFromDisk(name);
      await Hive.openBox<T>(name);
    } catch (e2) {
      debugPrint('Fatal box open failure for $name: $e2');
    }
  }
}
```

This guarantees that even if a local database file is corrupted due to an abrupt OS termination, the app does not crash on launch; it clears the corrupted box and re-syncs from Cloud Firestore upon authentication.

---

## ☁️ Bi-Directional Cloud Synchronization

### 1. Write Synchronization (Local -> Cloud)
Every ViewModel triggers `FirestoreService` immediately after writing to Hive:
- Saving an Invoice: `_firestoreService.saveInvoice(uid, invoice)`
- Deleting an Invoice: `_firestoreService.deleteInvoice(uid, invoiceId)`
- Updating Profile: `_firestoreService.saveBusinessProfile(uid, profile)`
- Saving Expenses: `_firestoreService.saveExpense(uid, expense)`
- Saving Projects: `_firestoreService.saveProject(uid, project)`

### 2. Read Synchronization (Cloud -> Local)
When a user logs in, switches accounts, or launches the app:
1. `authProvider` detects authentication change via `authStateChanges()`.
2. It executes `_syncAndRefresh(uid)`.
3. `FirestoreService` pulls all collections for that specific `uid`:
   - `getInvoices(uid)`
   - `getClients(uid)`
   - `getProducts(uid)`
   - `getExpenses(uid)`
   - `getProjects(uid)`
   - `getBusinessProfile(uid)`
4. Data is reconciled into local Hive boxes:
   - Hive keys are matched by entity `id`.
   - Missing local entries are inserted.
   - Remote updates overwrite outdated local timestamps.
5. All Riverpod providers are notified to reload from Hive, updating the UI instantaneously.

---

## 🔒 Conflict Resolution Strategy

- **Granular Document Isolation**: Every entity (invoice, client, product) exists as an independent document keyed by a unique UUID. This avoids collection-level conflicts.
- **Last Write Wins**: If an entity is modified concurrently across two devices, the document with the later timestamp wins.
- **Tenant Isolation**: Cloud documents are strictly scoped under `/users/{uid}/`, ensuring one user's sync operations can never collide with or overwrite another user's data.
