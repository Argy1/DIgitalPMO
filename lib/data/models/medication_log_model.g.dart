// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationLogModelAdapter extends TypeAdapter<MedicationLogModel> {
  @override
  final int typeId = 3;

  @override
  MedicationLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationLogModel(
      id: fields[0] as String,
      patientId: fields[1] as String,
      scheduleId: fields[2] as String,
      scheduledTime: fields[3] as DateTime,
      confirmedAt: fields[4] as DateTime?,
      status: fields[5] as String,
      photoUrl: fields[6] as String?,
      isPhotoVerified: fields[7] as bool,
      streakCount: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationLogModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.scheduleId)
      ..writeByte(3)
      ..write(obj.scheduledTime)
      ..writeByte(4)
      ..write(obj.confirmedAt)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.photoUrl)
      ..writeByte(7)
      ..write(obj.isPhotoVerified)
      ..writeByte(8)
      ..write(obj.streakCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
