import 'package:hive_flutter/hive_flutter.dart';

part 'side_effect_log_model.g.dart';

@HiveType(typeId: 5)
class SideEffectLogModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String patientId;

  @HiveField(2)
  final DateTime loggedAt;

  @HiveField(3)
  final List<String> sideEffects;

  @HiveField(4)
  final String severity;

  @HiveField(5)
  final String? aiResponse;

  @HiveField(6)
  final bool isEmergency;

  SideEffectLogModel({
    required this.id,
    required this.patientId,
    required this.loggedAt,
    required this.sideEffects,
    this.severity = 'MILD',
    this.aiResponse,
    this.isEmergency = false,
  });

  factory SideEffectLogModel.fromJson(Map<String, dynamic> json) {
    return SideEffectLogModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      loggedAt: json['loggedAt'] is String
          ? DateTime.parse(json['loggedAt'] as String)
          : json['loggedAt'] as DateTime,
      sideEffects: List<String>.from(json['sideEffects'] as List),
      severity: json['severity'] as String? ?? 'MILD',
      aiResponse: json['aiResponse'] as String?,
      isEmergency: json['isEmergency'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'loggedAt': loggedAt.toIso8601String(),
      'sideEffects': sideEffects,
      'severity': severity,
      'aiResponse': aiResponse,
      'isEmergency': isEmergency,
    };
  }

  SideEffectLogModel copyWith({
    String? id,
    String? patientId,
    DateTime? loggedAt,
    List<String>? sideEffects,
    String? severity,
    String? aiResponse,
    bool? isEmergency,
  }) {
    return SideEffectLogModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      loggedAt: loggedAt ?? this.loggedAt,
      sideEffects: sideEffects ?? this.sideEffects,
      severity: severity ?? this.severity,
      aiResponse: aiResponse ?? this.aiResponse,
      isEmergency: isEmergency ?? this.isEmergency,
    );
  }

  @override
  String toString() => 'SideEffectLogModel(id: $id, severity: $severity)';
}
