// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_state_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppStateModelAdapter extends TypeAdapter<AppStateModel> {
  @override
  final int typeId = 8;

  @override
  AppStateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppStateModel(
      patientId: fields[0] as String,
      shownDialogIds: (fields[1] as List).cast<String>(),
      shownMilestones: (fields[2] as List).cast<int>(),
      lastRiskScoreCalculation: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AppStateModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.patientId)
      ..writeByte(1)
      ..write(obj.shownDialogIds)
      ..writeByte(2)
      ..write(obj.shownMilestones)
      ..writeByte(3)
      ..write(obj.lastRiskScoreCalculation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppStateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
