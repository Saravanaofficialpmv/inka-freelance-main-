# 04. Features — Time Tracker & Billable Hours

Inka includes an integrated time tracking engine (`lib/presentation/viewmodels/time_tracker_viewmodel.dart` and `lib/presentation/screens/time_tracker_screen.dart`) that connects hours worked directly to invoices.

---

## ⏱️ Core Capabilities

### 1. Active Stopwatch Engine
- Users select an existing Client and Project (or create on-the-fly).
- Tapping **Start Timer** begins an active stopwatch session.
- **Crash & Resume Resilience**: Start timestamp (`startTime`) is stored immediately in Hive. Even if the application is closed or restarted, upon re-opening, the stopwatch calculates elapsed time accurately from `DateTime.now().difference(startTime)`.

### 2. Manual Time Logging
- Freelancers who log hours retroactively can enter date, duration (hours and minutes), and task notes manually without running the stopwatch.

### 3. One-Tap Invoicing (`convertEntryToInvoice`)
- When a project milestone or billing cycle ends, selecting billable time entries and tapping **Generate Invoice**:
  1. Computes line item: `name: "$projectTitle - ${durationHours.toStringAsFixed(1)} hrs @ $hourlyRate/hr"`.
  2. Creates an `InvoiceItem` with price and quantity.
  3. Pre-populates a draft `Invoice` with the client's information.
  4. Marks the `TimeEntry` status as `isBilled: true` and links the generated `invoiceId`.
