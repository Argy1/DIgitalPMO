// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'control_schedule_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ControlScheduleModelAdapter extends TypeAdapter<ControlScheduleModel> {
  @override
  final int typeId = 6;

  @override
  ControlScheduleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ControlScheduleModel(
      id: fields[0] as String,
      patientId: fields[1] as String,
      scheduledDate: fields[2] as DateTime,
      controlType: fields[3] as String,
      faskesName: fields[4] as String,
      notes: fields[5] as String?,
      isCompleted: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ControlScheduleModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.scheduledDate)
      ..writeByte(3)
      ..write(obj.controlType)
      ..writeByte(4)
      ..write(obj.faskesName)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ControlScheduleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
