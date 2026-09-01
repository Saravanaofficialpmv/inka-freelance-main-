import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 6)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final double amount;
  @HiveField(3)
  final String category; // 'Software', 'Contractor', 'Office', 'Marketing', 'Travel', 'Equipment', 'Other'
  @HiveField(4)
  final DateTime date;
  @HiveField(5)
  final String notes;
  @HiveField(6)
  final String paymentMethod; // 'Credit Card', 'Bank Transfer', 'UPI', 'Cash', 'Other'

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes = '',
    this.paymentMethod = 'UPI',
  });

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? notes,
    String? paymentMethod,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'paymentMethod': paymentMethod,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'Other',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? DateTime.now().millisecondsSinceEpoch),
      notes: map['notes'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'UPI',
    );
  }
}
