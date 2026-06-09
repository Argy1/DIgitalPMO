// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_schedule_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationScheduleModelAdapter
    extends TypeAdapter<MedicationScheduleModel> {
  @override
  final int typeId = 2;

  @override
  MedicationScheduleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationScheduleModel(
      id: fields[0] as String,
      patientId: fields[1] as String,
      phase: fields[2] as String,
      medications: (fields[3] as List).cast<String>(),
      scheduleTimes: (fields[4] as List).cast<String>(),
      reminderBefore: fields[5] as int,
      medicationType: fields[6] as String?,
      fdcType: fields[7] as String?,
      tabletCount: fields[8] as int?,
      frequencyPerWeek: fields[9] as int,
      scheduleDays: (fields[10] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, MedicationScheduleModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.phase)
      ..writeByte(3)
      ..write(obj.medications)
      ..writeByte(4)
      ..write(obj.scheduleTimes)
      ..writeByte(5)
      ..write(obj.reminderBefore)
      ..writeByte(6)
      ..write(obj.medicationType)
      ..writeByte(7)
      ..write(obj.fdcType)
      ..writeByte(8)
      ..write(obj.tabletCount)
      ..writeByte(9)
      ..write(obj.frequencyPerWeek)
      ..writeByte(10)
      ..write(obj.scheduleDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationScheduleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
