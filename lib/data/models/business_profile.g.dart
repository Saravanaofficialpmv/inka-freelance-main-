// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BusinessProfileAdapter extends TypeAdapter<BusinessProfile> {
  @override
  final int typeId = 4;

  @override
  BusinessProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BusinessProfile(
      businessName: fields[0] as String,
      address: fields[1] as String,
      phone: fields[2] as String,
      email: fields[3] as String,
      currency: fields[4] as String,
      logoUrl: fields[5] as String?,
      gstNumber: fields[6] as String?,
      accountHolderName: fields[7] as String?,
      accountNo: fields[8] as String?,
      ifscCode: fields[9] as String?,
      bankName: fields[10] as String?,
      branchName: fields[11] as String?,
      upiId: fields[12] as String?,
      upiNumber: fields[13] as String?,
      signatureUrl: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BusinessProfile obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.businessName)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.logoUrl)
      ..writeByte(6)
      ..write(obj.gstNumber)
      ..writeByte(7)
      ..write(obj.accountHolderName)
      ..writeByte(8)
      ..write(obj.accountNo)
      ..writeByte(9)
      ..write(obj.ifscCode)
      ..writeByte(10)
      ..write(obj.bankName)
      ..writeByte(11)
      ..write(obj.branchName)
      ..writeByte(12)
      ..write(obj.upiId)
      ..writeByte(13)
      ..write(obj.upiNumber)
      ..writeByte(14)
      ..write(obj.signatureUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
