// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 8;

  @override
  Project read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Project(
      id: fields[0] as String,
      projectName: fields[1] as String,
      clientId: fields[2] as String,
      clientName: fields[3] as String,
      description: fields[4] as String? ?? '',
      budget: fields[5] as double,
      receivedAmount: fields[6] as double? ?? 0.0,
      status: fields[7] as String? ?? 'Active',
      startDate: fields[8] as DateTime,
      deadline: fields[9] as DateTime,
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectName)
      ..writeByte(2)
      ..write(obj.clientId)
      ..writeByte(3)
      ..write(obj.clientName)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.budget)
      ..writeByte(6)
      ..write(obj.receivedAmount)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.startDate)
      ..writeByte(9)
      ..write(obj.deadline)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
