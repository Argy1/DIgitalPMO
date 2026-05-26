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
    );
  }

  @override
  void write(BinaryWriter writer, MedicationScheduleModel obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.reminderBefore);
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
