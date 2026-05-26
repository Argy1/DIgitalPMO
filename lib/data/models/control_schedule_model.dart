import 'package:hive_flutter/hive_flutter.dart';

part 'control_schedule_model.g.dart';

@HiveType(typeId: 6)
class ControlScheduleModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String patientId;

  @HiveField(2)
  final DateTime scheduledDate;

  @HiveField(3)
  final String controlType;

  @HiveField(4)
  final String faskesName;

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  final bool isCompleted;

  ControlScheduleModel({
    required this.id,
    required this.patientId,
    required this.scheduledDate,
    required this.controlType,
    required this.faskesName,
    this.notes,
    this.isCompleted = false,
  });

  factory ControlScheduleModel.fromJson(Map<String, dynamic> json) {
    return ControlScheduleModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      scheduledDate: json['scheduledDate'] is String
          ? DateTime.parse(json['scheduledDate'] as String)
          : json['scheduledDate'] as DateTime,
      controlType: json['controlType'] as String,
      faskesName: json['faskesName'] as String,
      notes: json['notes'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'scheduledDate': scheduledDate.toIso8601String(),
      'controlType': controlType,
      'faskesName': faskesName,
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }

  ControlScheduleModel copyWith({
    String? id,
    String? patientId,
    DateTime? scheduledDate,
    String? controlType,
    String? faskesName,
    String? notes,
    bool? isCompleted,
  }) {
    return ControlScheduleModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      controlType: controlType ?? this.controlType,
      faskesName: faskesName ?? this.faskesName,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() => 'ControlScheduleModel(id: $id, controlType: $controlType)';
}
