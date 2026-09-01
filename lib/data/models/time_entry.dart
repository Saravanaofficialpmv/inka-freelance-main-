import 'package:hive/hive.dart';
import 'client.dart';

part 'time_entry.g.dart';

@HiveType(typeId: 7)
class TimeEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final Client client;

  @HiveField(2)
  final String projectTitle;

  @HiveField(3)
  final double hourlyRate;

  @HiveField(4)
  final int durationSeconds;

  @HiveField(5)
  final bool isBilled;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final String? invoiceId;

  @HiveField(8)
  final String notes;

  @HiveField(9)
  final String? projectId;

  @HiveField(10)
  final DateTime startTime;

  @HiveField(11)
  final DateTime? endTime;

  @HiveField(12)
  final bool isRunning;

  @HiveField(13)
  final DateTime createdAt;

  TimeEntry({
    required this.id,
    required this.client,
    required this.projectTitle,
    required this.hourlyRate,
    required this.durationSeconds,
    this.isBilled = false,
    required this.date,
    this.invoiceId,
    this.notes = '',
    this.projectId,
    DateTime? startTime,
    this.endTime,
    this.isRunning = false,
    DateTime? createdAt,
  })  : startTime = startTime ?? date,
        createdAt = createdAt ?? date;

  String get description => notes.isNotEmpty ? notes : projectTitle;
  String get clientId => client.id;
  String get clientName => client.name;

  double get billableHours => durationSeconds / 3600.0;
  double get totalAmount => billableHours * hourlyRate;

  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Calculates actual elapsed seconds if timer is currently running, accounting for app close/reopen
  int get currentElapsedSeconds {
    if (!isRunning) return durationSeconds;
    final liveSeconds = DateTime.now().difference(startTime).inSeconds;
    return (durationSeconds + liveSeconds).clamp(0, 864000);
  }

  TimeEntry copyWith({
    String? id,
    Client? client,
    String? projectTitle,
    double? hourlyRate,
    int? durationSeconds,
    bool? isBilled,
    DateTime? date,
    String? invoiceId,
    String? notes,
    String? projectId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isRunning,
    DateTime? createdAt,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      client: client ?? this.client,
      projectTitle: projectTitle ?? this.projectTitle,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isBilled: isBilled ?? this.isBilled,
      date: date ?? this.date,
      invoiceId: invoiceId ?? this.invoiceId,
      notes: notes ?? this.notes,
      projectId: projectId ?? this.projectId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isRunning: isRunning ?? this.isRunning,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client': client.toMap(),
      'projectTitle': projectTitle,
      'hourlyRate': hourlyRate,
      'durationSeconds': durationSeconds,
      'isBilled': isBilled,
      'date': date.millisecondsSinceEpoch,
      'invoiceId': invoiceId,
      'notes': notes,
      'projectId': projectId,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'isRunning': isRunning,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory TimeEntry.fromMap(Map<String, dynamic> map) {
    return TimeEntry(
      id: map['id'] ?? '',
      client: Client.fromMap(map['client']),
      projectTitle: map['projectTitle'] ?? map['description'] ?? '',
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      isBilled: map['isBilled'] ?? false,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? DateTime.now().millisecondsSinceEpoch),
      invoiceId: map['invoiceId'],
      notes: map['notes'] ?? map['description'] ?? '',
      projectId: map['projectId'],
      startTime: map['startTime'] != null ? DateTime.fromMillisecondsSinceEpoch(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endTime']) : null,
      isRunning: map['isRunning'] ?? false,
      createdAt: map['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) : null,
    );
  }
}
