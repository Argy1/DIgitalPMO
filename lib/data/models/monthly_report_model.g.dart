// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_report_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonthlyReportModelAdapter extends TypeAdapter<MonthlyReportModel> {
  @override
  final int typeId = 8;

  @override
  MonthlyReportModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthlyReportModel(
      patientId: fields[0] as String,
      reportMonth: fields[1] as String,
      adherencePercentage: fields[2] as double,
      confirmedDoses: fields[3] as int,
      missedDoses: fields[4] as int,
      aiSummary: fields[5] as String?,
      pdfUrl: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MonthlyReportModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.patientId)
      ..writeByte(1)
      ..write(obj.reportMonth)
      ..writeByte(2)
      ..write(obj.adherencePercentage)
      ..writeByte(3)
      ..write(obj.confirmedDoses)
      ..writeByte(4)
      ..write(obj.missedDoses)
      ..writeByte(5)
      ..write(obj.aiSummary)
      ..writeByte(6)
      ..write(obj.pdfUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyReportModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
