// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pmo_patient_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PMOPatientModelAdapter extends TypeAdapter<PMOPatientModel> {
  @override
  final int typeId = 12;

  @override
  PMOPatientModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PMOPatientModel(
      id: fields[0] as String,
      pmoUserId: fields[1] as String,
      patientId: fields[2] as String,
      linkedVia: fields[3] as String,
      linkedAt: fields[4] as DateTime,
      isActive: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PMOPatientModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.pmoUserId)
      ..writeByte(2)
      ..write(obj.patientId)
      ..writeByte(3)
      ..write(obj.linkedVia)
      ..writeByte(4)
      ..write(obj.linkedAt)
      ..writeByte(5)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PMOPatientModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PMOPatientSummaryModelAdapter
    extends TypeAdapter<PMOPatientSummaryModel> {
  @override
  final int typeId = 13;

  @override
  PMOPatientSummaryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PMOPatientSummaryModel(
      patientId: fields[0] as String,
      patientName: fields[1] as String,
      tbCategory: fields[2] as String,
      tbTypeDisplay: fields[3] as String,
      treatmentDay: fields[4] as int,
      treatmentDurationDays: fields[5] as int?,
      medicationType: fields[6] as String?,
      todayMedicationStatus: fields[7] as String,
      adherenceLast30Days: fields[8] as double,
      currentStreak: fields[9] as int,
      riskLevel: fields[10] as String,
      lastConfirmedAt: fields[11] as DateTime?,
      linkedAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PMOPatientSummaryModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.patientId)
      ..writeByte(1)
      ..write(obj.patientName)
      ..writeByte(2)
      ..write(obj.tbCategory)
      ..writeByte(3)
      ..write(obj.tbTypeDisplay)
      ..writeByte(4)
      ..write(obj.treatmentDay)
      ..writeByte(5)
      ..write(obj.treatmentDurationDays)
      ..writeByte(6)
      ..write(obj.medicationType)
      ..writeByte(7)
      ..write(obj.todayMedicationStatus)
      ..writeByte(8)
      ..write(obj.adherenceLast30Days)
      ..writeByte(9)
      ..write(obj.currentStreak)
      ..writeByte(10)
      ..write(obj.riskLevel)
      ..writeByte(11)
      ..write(obj.lastConfirmedAt)
      ..writeByte(12)
      ..write(obj.linkedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PMOPatientSummaryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
