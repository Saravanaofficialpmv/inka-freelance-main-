// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceAdapter extends TypeAdapter<Invoice> {
  @override
  final int typeId = 1;

  @override
  Invoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Invoice(
      id: fields[0] as String,
      invoiceNumber: fields[1] as String,
      client: fields[2] as Client,
      items: (fields[3] as List).cast<InvoiceItem>(),
      issueDate: fields[4] as DateTime,
      dueDate: fields[5] as DateTime,
      taxPercentage: fields[6] as double,
      discount: fields[7] as double,
      status: fields[8] as String,
      notes: fields[9] as String,
      isRecurring: fields[10] as bool? ?? false,
      recurringInterval: fields[11] as String? ?? 'monthly',
      nextRecurringDate: fields[12] as DateTime?,
      clientViewedAt: fields[13] as DateTime?,
      clientViewCount: fields[14] as int? ?? 0,
      paymentProofRef: fields[15] as String?,
      paymentProofDate: fields[16] as DateTime?,
      paymentProofNote: fields[17] as String?,
      paymentProofStatus: fields[18] as String?,
      paymentProofImage: fields[19] as String?,
      milestones: (fields[20] as List?)
              ?.map((m) => m is Map
                  ? PaymentMilestone.fromMap(Map<String, dynamic>.from(m))
                  : (m is PaymentMilestone ? m : PaymentMilestone.fromMap(Map<String, dynamic>.from(m as Map))))
              .toList() ??
          const [],
    );
  }

  @override
  void write(BinaryWriter writer, Invoice obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.invoiceNumber)
      ..writeByte(2)
      ..write(obj.client)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.issueDate)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.taxPercentage)
      ..writeByte(7)
      ..write(obj.discount)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.isRecurring)
      ..writeByte(11)
      ..write(obj.recurringInterval)
      ..writeByte(12)
      ..write(obj.nextRecurringDate)
      ..writeByte(13)
      ..write(obj.clientViewedAt)
      ..writeByte(14)
      ..write(obj.clientViewCount)
      ..writeByte(15)
      ..write(obj.paymentProofRef)
      ..writeByte(16)
      ..write(obj.paymentProofDate)
      ..writeByte(17)
      ..write(obj.paymentProofNote)
      ..writeByte(18)
      ..write(obj.paymentProofStatus)
      ..writeByte(19)
      ..write(obj.paymentProofImage)
      ..writeByte(20)
      ..write(obj.milestones.map((m) => m.toMap()).toList());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
