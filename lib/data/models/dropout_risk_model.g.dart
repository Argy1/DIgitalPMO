// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dropout_risk_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DropoutRiskModelAdapter extends TypeAdapter<DropoutRiskModel> {
  @override
  final int typeId = 7;

  @override
  DropoutRiskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DropoutRiskModel(
      patientId: fields[0] as String,
      calculatedAt: fields[1] as DateTime,
      score: fields[2] as double,
      riskLevel: fields[3] as String,
      factors: (fields[4] as Map).cast<String, dynamic>(),
      aiRecommendation: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DropoutRiskModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.patientId)
      ..writeByte(1)
      ..write(obj.calculatedAt)
      ..writeByte(2)
      ..write(obj.score)
      ..writeByte(3)
      ..write(obj.riskLevel)
      ..writeByte(4)
      ..write(obj.factors)
      ..writeByte(5)
      ..write(obj.aiRecommendation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DropoutRiskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
