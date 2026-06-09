// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PatientProfileModelAdapter extends TypeAdapter<PatientProfileModel> {
  @override
  final int typeId = 1;

  @override
  PatientProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatientProfileModel(
      userId: fields[0] as String,
      dateOfBirth: fields[1] as DateTime,
      gender: fields[2] as String,
      address: fields[3] as String?,
      faskesName: fields[4] as String,
      doctorName: fields[5] as String,
      treatmentStartDate: fields[7] as DateTime,
      currentPhase: fields[8] as String,
      weightKg: fields[9] as double,
      isTreatmentComplete: fields[10] as bool,
      isHospitalized: fields[11] as bool,
      isPregnant: fields[12] as bool,
      tbCategory: fields[13] as String,
      tbSoType: fields[14] as String?,
      tbRoType: fields[15] as String?,
      treatmentDurationDays: fields[16] as int?,
      medicationType: fields[17] as String?,
      fdcType: fields[18] as String?,
      customMedications: (fields[19] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PatientProfileModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.dateOfBirth)
      ..writeByte(2)
      ..write(obj.gender)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.faskesName)
      ..writeByte(5)
      ..write(obj.doctorName)
      ..writeByte(7)
      ..write(obj.treatmentStartDate)
      ..writeByte(8)
      ..write(obj.currentPhase)
      ..writeByte(9)
      ..write(obj.weightKg)
      ..writeByte(10)
      ..write(obj.isTreatmentComplete)
      ..writeByte(11)
      ..write(obj.isHospitalized)
      ..writeByte(12)
      ..write(obj.isPregnant)
      ..writeByte(13)
      ..write(obj.tbCategory)
      ..writeByte(14)
      ..write(obj.tbSoType)
      ..writeByte(15)
      ..write(obj.tbRoType)
      ..writeByte(16)
      ..write(obj.treatmentDurationDays)
      ..writeByte(17)
      ..write(obj.medicationType)
      ..writeByte(18)
      ..write(obj.fdcType)
      ..writeByte(19)
      ..write(obj.customMedications);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
