# 03. Data Models — Projects & Time Tracking

Inka includes dedicated models for project lifecycle management, milestones, and billable time tracking.

---

## 🏗️ Project Model (`lib/data/models/project.dart`, TypeId: 8)

```dart
@HiveType(typeId: 8)
class Project extends HiveObject {
  @HiveField(0)  final String id;             // Project UUID
  @HiveField(1)  final String projectName;    // Project title
  @HiveField(2)  final String clientId;       // Associated Client ID
  @HiveField(3)  final String clientName;     // Cached client name for fast rendering
  @HiveField(4)  final String description;    // Project scope & deliverables
  @HiveField(5)  final double budget;         // Total contract budget
  @HiveField(6)  final double receivedAmount; // Cumulative payments collected
  @HiveField(7)  final String status;         // 'Planning', 'Active', 'Completed', 'On Hold', 'Cancelled'
  @HiveField(8)  final DateTime startDate;    // Kickoff date
  @HiveField(9)  final DateTime deadline;     // Delivery due date
  @HiveField(10) final DateTime createdAt;    // Record creation timestamp

  double get remainingAmount => (budget - receivedAmount).clamp(0.0, double.infinity);
  double get progressRatio => budget <= 0 ? 0.0 : (receivedAmount / budget).clamp(0.0, 1.0);
}
```

- **Hive Box**: `projects`
- **Riverpod ViewModel**: `projectViewModelProvider` (`lib/presentation/viewmodels/project_viewmodel.dart`)
- **Firestore Collection**: `/users/{uid}/projects/{projectId}`

---

## ⏱️ TimeEntry Model (`lib/data/models/time_entry.dart`, TypeId: 7)

```dart
@HiveType(typeId: 7)
class TimeEntry extends HiveObject {
  @HiveField(0)  final String id;             // Time entry UUID
  @HiveField(1)  final Client client;         // Associated client
  @HiveField(2)  final String projectTitle;   // Associated project or task title
  @HiveField(3)  final double hourlyRate;     // Hourly billing rate
  @HiveField(4)  final int durationSeconds;   // Logged duration in seconds
  @HiveField(5)  final bool isBilled;         // Whether this entry has been converted to an invoice
  @HiveField(6)  final DateTime date;         // Date of work
  @HiveField(7)  final String? invoiceId;     // Linked invoice ID once billed
  @HiveField(8)  final String notes;          // Work log details
  @HiveField(9)  final String? projectId;     // Optional linked Project ID
  @HiveField(10) final DateTime startTime;    // Session start timestamp
  @HiveField(11) final DateTime? endTime;     // Session stop timestamp
  @HiveField(12) final bool isRunning;        // Live active stopwatch flag
  @HiveField(13) final DateTime createdAt;    // Entry creation timestamp

  double get hours => durationSeconds / 3600.0;
  double get totalAmount => hours * hourlyRate;
}
```

- **Hive Box**: `time_entries`
- **Riverpod ViewModel**: `timeTrackerViewModelProvider` (`lib/presentation/viewmodels/time_tracker_viewmodel.dart`)
- **Firestore Collection**: `/users/{uid}/time_entries/{entryId}`
- **Features**: Live stopwatch persistence across app pauses, manual time logging, and 1-tap conversion to an invoice.
