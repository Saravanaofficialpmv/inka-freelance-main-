// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimeEntryAdapter extends TypeAdapter<TimeEntry> {
  @override
  final int typeId = 7;

  @override
  TimeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeEntry(
      id: fields[0] as String,
      client: fields[1] as Client,
      projectTitle: fields[2] as String,
      hourlyRate: fields[3] as double,
      durationSeconds: fields[4] as int,
      isBilled: fields[5] as bool? ?? false,
      date: fields[6] as DateTime,
      invoiceId: fields[7] as String?,
      notes: fields[8] as String? ?? '',
      projectId: fields[9] as String?,
      startTime: fields[10] as DateTime?,
      endTime: fields[11] as DateTime?,
      isRunning: fields[12] as bool? ?? false,
      createdAt: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TimeEntry obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.client)
      ..writeByte(2)
      ..write(obj.projectTitle)
      ..writeByte(3)
      ..write(obj.hourlyRate)
      ..writeByte(4)
      ..write(obj.durationSeconds)
      ..writeByte(5)
      ..write(obj.isBilled)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.invoiceId)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.projectId)
      ..writeByte(10)
      ..write(obj.startTime)
      ..writeByte(11)
      ..write(obj.endTime)
      ..writeByte(12)
      ..write(obj.isRunning)
      ..writeByte(13)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
