import 'package:hive/hive.dart';

part 'project.g.dart';

@HiveType(typeId: 8)
class Project extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String projectName;

  @HiveField(2)
  final String clientId;

  @HiveField(3)
  final String clientName;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final double budget;

  @HiveField(6)
  final double receivedAmount;

  @HiveField(7)
  final String status; // 'Planning', 'Active', 'Completed', 'On Hold', 'Cancelled'

  @HiveField(8)
  final DateTime startDate;

  @HiveField(9)
  final DateTime deadline;

  @HiveField(10)
  final DateTime createdAt;

  Project({
    required this.id,
    required this.projectName,
    required this.clientId,
    required this.clientName,
    this.description = '',
    required this.budget,
    this.receivedAmount = 0.0,
    this.status = 'Active',
    required this.startDate,
    required this.deadline,
    required this.createdAt,
  });

  double get remainingAmount => (budget - receivedAmount).clamp(0.0, double.infinity);

  double get progressRatio {
    if (budget <= 0) return 0.0;
    return (receivedAmount / budget).clamp(0.0, 1.0);
  }

  int get progressPercentage => (progressRatio * 100).round();

  bool get isOverdue => DateTime.now().isAfter(deadline) && status != 'Completed' && status != 'Cancelled';

  int get daysRemaining => deadline.difference(DateTime.now()).inDays;

  Project copyWith({
    String? id,
    String? projectName,
    String? clientId,
    String? clientName,
    String? description,
    double? budget,
    double? receivedAmount,
    String? status,
    DateTime? startDate,
    DateTime? deadline,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      projectName: projectName ?? this.projectName,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectName': projectName,
      'clientId': clientId,
      'clientName': clientName,
      'description': description,
      'budget': budget,
      'receivedAmount': receivedAmount,
      'status': status,
      'startDate': startDate.millisecondsSinceEpoch,
      'deadline': deadline.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      projectName: map['projectName'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      description: map['description'] ?? '',
      budget: (map['budget'] as num?)?.toDouble() ?? 0.0,
      receivedAmount: (map['receivedAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Active',
      startDate: DateTime.fromMillisecondsSinceEpoch(
        map['startDate'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      deadline: DateTime.fromMillisecondsSinceEpoch(
        map['deadline'] ?? DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
