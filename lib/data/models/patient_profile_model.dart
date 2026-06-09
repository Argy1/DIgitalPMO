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
  final String? address;

  @HiveField(4)
  final String faskesName;

  @HiveField(5)
  final String doctorName;

  // Field 6 (tbType) removed — index kept free for Hive backward compat

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

  @HiveField(13)
  final String tbCategory; // "SO" atau "RO"

  @HiveField(14)
  final String? tbSoType; // null jika RO

  @HiveField(15)
  final String? tbRoType; // "MDR", "XDR", "RR" — null jika SO

  @HiveField(16)
  final int? treatmentDurationDays; // diisi dokter, bisa null

  @HiveField(17)
  final String? medicationType; // "FDC" atau "Kombinasi"

  @HiveField(18)
  final String? fdcType; // "FDC" atau "Kombipak"

  @HiveField(19)
  final List<String>? customMedications; // ["R","H","Z","E"] subset

  PatientProfileModel({
    required this.userId,
    required this.dateOfBirth,
    required this.gender,
    this.address,
    required this.faskesName,
    required this.doctorName,
    required this.treatmentStartDate,
    this.currentPhase = 'intensive',
    this.weightKg = 0.0,
    this.isTreatmentComplete = false,
    this.isHospitalized = false,
    this.isPregnant = false,
    this.tbCategory = 'SO',
    this.tbSoType,
    this.tbRoType,
    this.treatmentDurationDays,
    this.medicationType,
    this.fdcType,
    this.customMedications,
  });

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    return PatientProfileModel(
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] is String
          ? DateTime.parse(json['dateOfBirth'] as String)
          : (json['date_of_birth'] is String
              ? DateTime.parse(json['date_of_birth'] as String)
              : json['dateOfBirth'] as DateTime),
      gender: json['gender'] as String? ?? '',
      address: json['address'] as String?,
      faskesName: json['faskesName'] as String? ??
          json['faskes_name'] as String? ??
          '',
      doctorName: json['doctorName'] as String? ??
          json['doctor_name'] as String? ??
          '',
      treatmentStartDate: json['treatmentStartDate'] is String
          ? DateTime.parse(json['treatmentStartDate'] as String)
          : (json['treatment_start_date'] is String
              ? DateTime.parse(json['treatment_start_date'] as String)
              : json['treatmentStartDate'] as DateTime),
      currentPhase: json['currentPhase'] as String? ??
          json['current_phase'] as String? ??
          'intensive',
      weightKg:
          (json['weightKg'] as num? ?? json['weight_kg'] as num? ?? 0).toDouble(),
      isTreatmentComplete: json['isTreatmentComplete'] as bool? ??
          json['is_treatment_complete'] as bool? ??
          false,
      isHospitalized: json['isHospitalized'] as bool? ??
          json['is_hospitalized'] as bool? ??
          false,
      isPregnant: json['isPregnant'] as bool? ??
          json['is_pregnant'] as bool? ??
          false,
      tbCategory: json['tbCategory'] as String? ??
          json['tb_category'] as String? ??
          'SO',
      tbSoType: json['tbSoType'] as String? ?? json['tb_so_type'] as String?,
      tbRoType: json['tbRoType'] as String? ?? json['tb_ro_type'] as String?,
      treatmentDurationDays: json['treatmentDurationDays'] as int? ??
          json['treatment_duration_days'] as int?,
      medicationType: json['medicationType'] as String? ??
          json['medication_type'] as String?,
      fdcType: json['fdcType'] as String? ?? json['fdc_type'] as String?,
      customMedications: json['customMedications'] != null
          ? List<String>.from(json['customMedications'] as List)
          : (json['custom_medications'] != null
              ? List<String>.from(json['custom_medications'] as List)
              : null),
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
      'treatmentStartDate': treatmentStartDate.toIso8601String(),
      'currentPhase': currentPhase,
      'weightKg': weightKg,
      'isTreatmentComplete': isTreatmentComplete,
      'isHospitalized': isHospitalized,
      'isPregnant': isPregnant,
      'tbCategory': tbCategory,
      'tbSoType': tbSoType,
      'tbRoType': tbRoType,
      'treatmentDurationDays': treatmentDurationDays,
      'medicationType': medicationType,
      'fdcType': fdcType,
      'customMedications': customMedications,
    };
  }

  PatientProfileModel copyWith({
    String? userId,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? faskesName,
    String? doctorName,
    DateTime? treatmentStartDate,
    String? currentPhase,
    double? weightKg,
    bool? isTreatmentComplete,
    bool? isHospitalized,
    bool? isPregnant,
    String? tbCategory,
    String? tbSoType,
    String? tbRoType,
    int? treatmentDurationDays,
    String? medicationType,
    String? fdcType,
    List<String>? customMedications,
  }) {
    return PatientProfileModel(
      userId: userId ?? this.userId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      faskesName: faskesName ?? this.faskesName,
      doctorName: doctorName ?? this.doctorName,
      treatmentStartDate: treatmentStartDate ?? this.treatmentStartDate,
      currentPhase: currentPhase ?? this.currentPhase,
      weightKg: weightKg ?? this.weightKg,
      isTreatmentComplete: isTreatmentComplete ?? this.isTreatmentComplete,
      isHospitalized: isHospitalized ?? this.isHospitalized,
      isPregnant: isPregnant ?? this.isPregnant,
      tbCategory: tbCategory ?? this.tbCategory,
      tbSoType: tbSoType ?? this.tbSoType,
      tbRoType: tbRoType ?? this.tbRoType,
      treatmentDurationDays: treatmentDurationDays ?? this.treatmentDurationDays,
      medicationType: medicationType ?? this.medicationType,
      fdcType: fdcType ?? this.fdcType,
      customMedications: customMedications ?? this.customMedications,
    );
  }

  // ── Helper getters ────────────────────────────────────────────────────────

  /// Display string, contoh: "SO - TB Paru" atau "RO - MDR"
  String get tbTypeDisplay {
    if (tbCategory == 'SO') return 'SO - ${tbSoType ?? "-"}';
    if (tbCategory == 'RO') return 'RO - ${tbRoType ?? "-"}';
    return tbCategory;
  }

  /// Apakah pasien ini TB Resisten Obat?
  bool get isRO => tbCategory == 'RO';

  /// Apakah pakai FDC?
  bool get isFDC => medicationType == 'FDC';

  /// Jumlah tablet FDC berdasarkan berat badan (rekomendasi WHO)
  int get fdcTabletCount {
    if (weightKg < 38) return 2;
    if (weightKg < 55) return 3;
    if (weightKg <= 70) return 4;
    return 5;
  }

  @override
  String toString() => 'PatientProfileModel(userId: $userId, tbCategory: $tbCategory)';
}
