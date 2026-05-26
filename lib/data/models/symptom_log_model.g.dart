// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'symptom_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SymptomLogModelAdapter extends TypeAdapter<SymptomLogModel> {
  @override
  final int typeId = 4;

  @override
  SymptomLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SymptomLogModel(
      id: fields[0] as String,
      patientId: fields[1] as String,
      loggedDate: fields[2] as DateTime,
      coughScale: fields[3] as int,
      fever: fields[4] as bool,
      feverTemperature: fields[5] as double?,
      shortnessOfBreath: fields[6] as bool,
      nightSweats: fields[7] as bool,
      appetiteScale: fields[8] as int,
      energyScale: fields[9] as int,
      weightKg: fields[10] as double,
      additionalNotes: fields[11] as String?,
      aiAssessment: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SymptomLogModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.loggedDate)
      ..writeByte(3)
      ..write(obj.coughScale)
      ..writeByte(4)
      ..write(obj.fever)
      ..writeByte(5)
      ..write(obj.feverTemperature)
      ..writeByte(6)
      ..write(obj.shortnessOfBreath)
      ..writeByte(7)
      ..write(obj.nightSweats)
      ..writeByte(8)
      ..write(obj.appetiteScale)
      ..writeByte(9)
      ..write(obj.energyScale)
      ..writeByte(10)
      ..write(obj.weightKg)
      ..writeByte(11)
      ..write(obj.additionalNotes)
      ..writeByte(12)
      ..write(obj.aiAssessment);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
