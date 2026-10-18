import 'package:hive/hive.dart';
import 'client.dart';
import 'invoice_item.dart';
import 'payment_milestone.dart';

part 'invoice.g.dart';

@HiveType(typeId: 1)
class Invoice extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String invoiceNumber;
  @HiveField(2)
  final Client client;
  @HiveField(3)
  final List<InvoiceItem> items;
  @HiveField(4)
  final DateTime issueDate;
  @HiveField(5)
  final DateTime dueDate;
  @HiveField(6)
  final double taxPercentage;
  @HiveField(7)
  final double discount;
  @HiveField(8)
  final String status; // 'pending', 'paid', 'overdue'
  @HiveField(9)
  final String notes;
  @HiveField(10)
  final bool isRecurring;
  @HiveField(11)
  final String recurringInterval; // 'weekly', 'monthly', 'quarterly', 'yearly'
  @HiveField(12)
  final DateTime? nextRecurringDate;
  @HiveField(13)
  final DateTime? clientViewedAt;
  @HiveField(14)
  final int clientViewCount;
  @HiveField(15)
  final String? paymentProofRef;
  @HiveField(16)
  final DateTime? paymentProofDate;
  @HiveField(17)
  final String? paymentProofNote;
  @HiveField(18)
  final String? paymentProofStatus; // 'submitted', 'verified', 'rejected'
  @HiveField(19)
  final String? paymentProofImage;
  @HiveField(20)
  final List<PaymentMilestone> milestones;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.client,
    required this.items,
    required this.issueDate,
    required this.dueDate,
    this.taxPercentage = 0.0,
    this.discount = 0.0,
    this.status = 'pending',
    this.notes = '',
    this.isRecurring = false,
    this.recurringInterval = 'monthly',
    this.nextRecurringDate,
    this.clientViewedAt,
    this.clientViewCount = 0,
    this.paymentProofRef,
    this.paymentProofDate,
    this.paymentProofNote,
    this.paymentProofStatus,
    this.paymentProofImage,
    this.milestones = const [],
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get taxAmount => subtotal * (taxPercentage / 100);
  double get total => subtotal + taxAmount - discount;
  bool get isPaid => status.toLowerCase() == 'paid';

  bool get hasMilestones => milestones.isNotEmpty;
  List<PaymentMilestone> get paidMilestones => milestones.where((m) => m.isPaid).toList();
  PaymentMilestone? get activeMilestone => milestones.isEmpty
      ? null
      : milestones.firstWhere(
          (m) => m.isActive,
          orElse: () => milestones.firstWhere((m) => m.isPending, orElse: () => milestones.last),
        );
  double get milestonesTotalPaid =>
      milestones.where((m) => m.isPaid).fold<double>(0.0, (sum, m) => sum + m.amount);
  double get milestonesRemaining => (total - milestonesTotalPaid).clamp(0.0, double.infinity);
  bool get hasPaymentProof => paymentProofStatus != null && paymentProofStatus != 'rejected';

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    Client? client,
    List<InvoiceItem>? items,
    DateTime? issueDate,
    DateTime? dueDate,
    double? taxPercentage,
    double? discount,
    String? status,
    String? notes,
    bool? isRecurring,
    String? recurringInterval,
    DateTime? nextRecurringDate,
    DateTime? clientViewedAt,
    int? clientViewCount,
    String? paymentProofRef,
    DateTime? paymentProofDate,
    String? paymentProofNote,
    String? paymentProofStatus,
    String? paymentProofImage,
    List<PaymentMilestone>? milestones,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      client: client ?? this.client,
      items: items ?? this.items,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      discount: discount ?? this.discount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      nextRecurringDate: nextRecurringDate ?? this.nextRecurringDate,
      clientViewedAt: clientViewedAt ?? this.clientViewedAt,
      clientViewCount: clientViewCount ?? this.clientViewCount,
      paymentProofRef: paymentProofRef ?? this.paymentProofRef,
      paymentProofDate: paymentProofDate ?? this.paymentProofDate,
      paymentProofNote: paymentProofNote ?? this.paymentProofNote,
      paymentProofStatus: paymentProofStatus ?? this.paymentProofStatus,
      paymentProofImage: paymentProofImage ?? this.paymentProofImage,
      milestones: milestones ?? this.milestones,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'client': client.toMap(),
      'items': items.map((x) => x.toMap()).toList(),
      'issueDate': issueDate.millisecondsSinceEpoch,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'taxPercentage': taxPercentage,
      'discount': discount,
      'status': status,
      'notes': notes,
      'isRecurring': isRecurring,
      'recurringInterval': recurringInterval,
      'nextRecurringDate': nextRecurringDate?.millisecondsSinceEpoch,
      'clientViewedAt': clientViewedAt?.millisecondsSinceEpoch,
      'clientViewCount': clientViewCount,
      'paymentProofRef': paymentProofRef,
      'paymentProofDate': paymentProofDate?.millisecondsSinceEpoch,
      'paymentProofNote': paymentProofNote,
      'paymentProofStatus': paymentProofStatus,
      'paymentProofImage': paymentProofImage,
      'milestones': milestones.map((x) => x.toMap()).toList(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      client: Client.fromMap(map['client']),
      items: List<InvoiceItem>.from(map['items']?.map((x) => InvoiceItem.fromMap(x)) ?? []),
      issueDate: DateTime.fromMillisecondsSinceEpoch(map['issueDate']),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      taxPercentage: map['taxPercentage']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      notes: map['notes'] ?? '',
      isRecurring: map['isRecurring'] ?? false,
      recurringInterval: map['recurringInterval'] ?? 'monthly',
      nextRecurringDate: map['nextRecurringDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextRecurringDate'])
          : null,
      clientViewedAt: map['clientViewedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['clientViewedAt'])
          : null,
      clientViewCount: (map['clientViewCount'] as num?)?.toInt() ?? 0,
      paymentProofRef: map['paymentProofRef'],
      paymentProofDate: map['paymentProofDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['paymentProofDate'])
          : null,
      paymentProofNote: map['paymentProofNote'],
      paymentProofStatus: map['paymentProofStatus'],
      paymentProofImage: map['paymentProofImage'],
      milestones: (map['milestones'] as List?)
              ?.map((x) => PaymentMilestone.fromMap(Map<String, dynamic>.from(x as Map)))
              .toList() ??
          const [],
    );
  }
}
