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

  MedicationScheduleModel({
    required this.id,
    required this.patientId,
    required this.phase,
    required this.medications,
    required this.scheduleTimes,
    this.reminderBefore = 15,
  });

  factory MedicationScheduleModel.fromJson(Map<String, dynamic> json) {
    return MedicationScheduleModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      phase: json['phase'] as String,
      medications: List<String>.from(json['medications'] as List),
      scheduleTimes: List<String>.from(json['scheduleTimes'] as List),
      reminderBefore: json['reminderBefore'] as int? ?? 15,
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
    };
  }

  MedicationScheduleModel copyWith({
    String? id,
    String? patientId,
    String? phase,
    List<String>? medications,
    List<String>? scheduleTimes,
    int? reminderBefore,
  }) {
    return MedicationScheduleModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      phase: phase ?? this.phase,
      medications: medications ?? this.medications,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
      reminderBefore: reminderBefore ?? this.reminderBefore,
    );
  }

  @override
  String toString() => 'MedicationScheduleModel(id: $id, patientId: $patientId)';
}
