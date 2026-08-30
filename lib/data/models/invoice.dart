import 'package:hive/hive.dart';
import 'client.dart';
import 'invoice_item.dart';

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
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get taxAmount => subtotal * (taxPercentage / 100);
  double get total => subtotal + taxAmount - discount;

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
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      client: Client.fromMap(map['client']),
      items: List<InvoiceItem>.from(map['items']?.map((x) => InvoiceItem.fromMap(x))),
      issueDate: DateTime.fromMillisecondsSinceEpoch(map['issueDate']),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      taxPercentage: map['taxPercentage']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      notes: map['notes'] ?? '',
    );
  }
}
