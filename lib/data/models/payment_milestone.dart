class PaymentMilestone {
  final String id;
  final String title;
  final double percentage; // e.g. 40.0
  final double amount;
  final DateTime? dueDate;
  final String status; // 'paid', 'active', 'pending'
  final DateTime? paidAt;
  final String? transactionRef;
  final String? proofAttachment;

  const PaymentMilestone({
    required this.id,
    required this.title,
    required this.percentage,
    required this.amount,
    this.dueDate,
    this.status = 'pending',
    this.paidAt,
    this.transactionRef,
    this.proofAttachment,
  });

  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isActive => status.toLowerCase() == 'active';
  bool get isPending => status.toLowerCase() == 'pending';

  PaymentMilestone copyWith({
    String? id,
    String? title,
    double? percentage,
    double? amount,
    DateTime? dueDate,
    String? status,
    DateTime? paidAt,
    String? transactionRef,
    String? proofAttachment,
  }) {
    return PaymentMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      percentage: percentage ?? this.percentage,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      transactionRef: transactionRef ?? this.transactionRef,
      proofAttachment: proofAttachment ?? this.proofAttachment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'percentage': percentage,
      'amount': amount,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'status': status,
      'paidAt': paidAt?.millisecondsSinceEpoch,
      'transactionRef': transactionRef,
      'proofAttachment': proofAttachment,
    };
  }

  factory PaymentMilestone.fromMap(Map<String, dynamic> map) {
    return PaymentMilestone(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: map['dueDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['dueDate']) : null,
      status: map['status'] ?? 'pending',
      paidAt: map['paidAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['paidAt']) : null,
      transactionRef: map['transactionRef'],
      proofAttachment: map['proofAttachment'],
    );
  }
}
