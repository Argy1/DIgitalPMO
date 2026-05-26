// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'side_effect_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SideEffectLogModelAdapter extends TypeAdapter<SideEffectLogModel> {
  @override
  final int typeId = 5;

  @override
  SideEffectLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SideEffectLogModel(
      id: fields[0] as String,
      patientId: fields[1] as String,
      loggedAt: fields[2] as DateTime,
      sideEffects: (fields[3] as List).cast<String>(),
      severity: fields[4] as String,
      aiResponse: fields[5] as String?,
      isEmergency: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SideEffectLogModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.loggedAt)
      ..writeByte(3)
      ..write(obj.sideEffects)
      ..writeByte(4)
      ..write(obj.severity)
      ..writeByte(5)
      ..write(obj.aiResponse)
      ..writeByte(6)
      ..write(obj.isEmergency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SideEffectLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
