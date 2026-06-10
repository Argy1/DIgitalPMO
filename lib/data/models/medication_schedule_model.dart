import 'package:hive_flutter/hive_flutter.dart';

part 'medication_schedule_model.g.dart';

@HiveType(typeId: 2)
class MedicationScheduleModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String patientId;

  @HiveField(2)
  final String phase;

  @HiveField(3)
  final List<String> medications;

  @HiveField(4)
  final List<String> scheduleTimes;

  @HiveField(5)
  final int reminderBefore;

  @HiveField(6)
  final String? medicationType; // "FDC" atau "Kombinasi"

  @HiveField(7)
  final String? fdcType; // "FDC" atau "Kombipak"

  @HiveField(8)
  final int? tabletCount; // jumlah tablet per dosis (berbasis berat badan)

  @HiveField(9)
  final int frequencyPerWeek; // 7=setiap hari, 3=3x seminggu

  @HiveField(10)
  final List<int>? scheduleDays; // [1,2,3,4,5,6,7] atau [1,3,5]

  MedicationScheduleModel({
    required this.id,
    required this.patientId,
    required this.phase,
    required this.medications,
    required this.scheduleTimes,
    this.reminderBefore = 15,
    this.medicationType,
    this.fdcType,
    this.tabletCount,
    this.frequencyPerWeek = 7,
    this.scheduleDays,
  });

  factory MedicationScheduleModel.fromJson(Map<String, dynamic> json) {
    // medications can be List<String> or List<Map> from backend
    List<String> parseMedications(dynamic raw) {
      if (raw == null) return [];
      final list = raw as List;
      if (list.isEmpty) return [];
      if (list.first is String) return List<String>.from(list);
      // Backend sends [{"code": "R", "name": "Rifampicin"}, ...]
      return list
          .map((e) => (e as Map<String, dynamic>)['code'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return MedicationScheduleModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String? ??
          json['patient_id'] as String? ??
          '',
      phase: json['phase'] as String? ?? 'intensive',
      medications: parseMedications(json['medications']),
      scheduleTimes: json['scheduleTimes'] != null
          ? List<String>.from(json['scheduleTimes'] as List)
          : (json['schedule_times'] != null
              ? List<String>.from(json['schedule_times'] as List)
              : []),
      reminderBefore: (json['reminderBefore'] as num? ??
              json['reminder_before'] as num? ??
              15)
          .toInt(),
      medicationType: json['medicationType'] as String? ??
          json['medication_type'] as String?,
      fdcType: json['fdcType'] as String? ?? json['fdc_type'] as String?,
      tabletCount: (json['tabletCount'] as num? ?? json['tablet_count'] as num?)
          ?.toInt(),
      frequencyPerWeek: (json['frequencyPerWeek'] as num? ??
              json['frequency_per_week'] as num? ??
              7)
          .toInt(),
      scheduleDays: (() {
        final raw = json['scheduleDays'] ?? json['schedule_days'];
        if (raw is List && raw.isNotEmpty) {
          return raw.map((e) => (e as num).toInt()).toList();
        }
        return null;
      })(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'phase': phase,
      'medications': medications,
      'scheduleTimes': scheduleTimes,
      'reminderBefore': reminderBefore,
      'medicationType': medicationType,
      'fdcType': fdcType,
      'tabletCount': tabletCount,
      'frequencyPerWeek': frequencyPerWeek,
      'scheduleDays': scheduleDays,
    };
  }

  MedicationScheduleModel copyWith({
    String? id,
    String? patientId,
    String? phase,
    List<String>? medications,
    List<String>? scheduleTimes,
    int? reminderBefore,
    String? medicationType,
    String? fdcType,
    int? tabletCount,
    int? frequencyPerWeek,
    List<int>? scheduleDays,
  }) {
    return MedicationScheduleModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      phase: phase ?? this.phase,
      medications: medications ?? this.medications,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
      reminderBefore: reminderBefore ?? this.reminderBefore,
      medicationType: medicationType ?? this.medicationType,
      fdcType: fdcType ?? this.fdcType,
      tabletCount: tabletCount ?? this.tabletCount,
      frequencyPerWeek: frequencyPerWeek ?? this.frequencyPerWeek,
      scheduleDays: scheduleDays ?? this.scheduleDays,
    );
  }

  // ── Helper getters ────────────────────────────────────────────────────────

  /// Apakah jadwal ini 3x seminggu? (fase lanjutan FDC)
  bool get isThreeTimesWeekly => frequencyPerWeek == 3;

  /// Display label untuk frekuensi minum obat
  String get frequencyDisplay {
    if (frequencyPerWeek == 7) return 'Setiap hari';
    if (frequencyPerWeek == 3) return '3x seminggu';
    return '$frequencyPerWeek x seminggu';
  }

  /// Display label untuk jenis/jumlah obat
  String get medicationDisplay {
    if (medicationType == 'FDC') {
      return '${tabletCount ?? "?"} tablet ${fdcType ?? "FDC"}';
    }
    return medications.join(' + ');
  }

  @override
  String toString() =>
      'MedicationScheduleModel(id: $id, patientId: $patientId, phase: $phase)';
}
