import 'package:hive_flutter/hive_flutter.dart';

part 'patient_profile_model.g.dart';

@HiveType(typeId: 1)
class PatientProfileModel {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final DateTime dateOfBirth;

  @HiveField(2)
  final String gender;

  @HiveField(3)
  final String address;

  @HiveField(4)
  final String faskesName;

  @HiveField(5)
  final String doctorName;

  @HiveField(6)
  final String tbType;

  @HiveField(7)
  final DateTime treatmentStartDate;

  @HiveField(8)
  final String currentPhase;

  @HiveField(9)
  final double weightKg;

  @HiveField(10)
  final bool isTreatmentComplete;

  @HiveField(11)
  final bool isHospitalized;

  @HiveField(12)
  final bool isPregnant;

  PatientProfileModel({
    required this.userId,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.faskesName,
    required this.doctorName,
    required this.tbType,
    required this.treatmentStartDate,
    this.currentPhase = 'intensive',
    required this.weightKg,
    this.isTreatmentComplete = false,
    this.isHospitalized = false,
    this.isPregnant = false,
  });

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    return PatientProfileModel(
      userId: json['userId'] as String,
      dateOfBirth: json['dateOfBirth'] is String
          ? DateTime.parse(json['dateOfBirth'] as String)
          : json['dateOfBirth'] as DateTime,
      gender: json['gender'] as String,
      address: json['address'] as String,
      faskesName: json['faskesName'] as String,
      doctorName: json['doctorName'] as String,
      tbType: json['tbType'] as String,
      treatmentStartDate: json['treatmentStartDate'] is String
          ? DateTime.parse(json['treatmentStartDate'] as String)
          : json['treatmentStartDate'] as DateTime,
      currentPhase: json['currentPhase'] as String? ?? 'intensive',
      weightKg: (json['weightKg'] as num).toDouble(),
      isTreatmentComplete: json['isTreatmentComplete'] as bool? ?? false,
      isHospitalized: json['isHospitalized'] as bool? ?? false,
      isPregnant: json['isPregnant'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'address': address,
      'faskesName': faskesName,
      'doctorName': doctorName,
      'tbType': tbType,
      'treatmentStartDate': treatmentStartDate.toIso8601String(),
      'currentPhase': currentPhase,
      'weightKg': weightKg,
      'isTreatmentComplete': isTreatmentComplete,
      'isHospitalized': isHospitalized,
      'isPregnant': isPregnant,
    };
  }

  PatientProfileModel copyWith({
    String? userId,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? faskesName,
    String? doctorName,
    String? tbType,
    DateTime? treatmentStartDate,
    String? currentPhase,
    double? weightKg,
    bool? isTreatmentComplete,
    bool? isHospitalized,
    bool? isPregnant,
  }) {
    return PatientProfileModel(
      userId: userId ?? this.userId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      faskesName: faskesName ?? this.faskesName,
      doctorName: doctorName ?? this.doctorName,
      tbType: tbType ?? this.tbType,
      treatmentStartDate: treatmentStartDate ?? this.treatmentStartDate,
      currentPhase: currentPhase ?? this.currentPhase,
      weightKg: weightKg ?? this.weightKg,
      isTreatmentComplete: isTreatmentComplete ?? this.isTreatmentComplete,
      isHospitalized: isHospitalized ?? this.isHospitalized,
      isPregnant: isPregnant ?? this.isPregnant,
    );
  }

  @override
  String toString() => 'PatientProfileModel(userId: $userId)';
}
