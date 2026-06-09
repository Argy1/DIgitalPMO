import 'dart:ui' show Color;

import 'package:hive_flutter/hive_flutter.dart';

part 'pmo_patient_model.g.dart';

@HiveType(typeId: 12)
class PMOPatientModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String pmoUserId;

  @HiveField(2)
  final String patientId;

  @HiveField(3)
  final String linkedVia; // 'qr_code' atau 'phone_request'

  @HiveField(4)
  final DateTime linkedAt;

  @HiveField(5)
  final bool isActive;

  PMOPatientModel({
    required this.id,
    required this.pmoUserId,
    required this.patientId,
    required this.linkedVia,
    required this.linkedAt,
    this.isActive = true,
  });

  factory PMOPatientModel.fromJson(Map<String, dynamic> json) {
    return PMOPatientModel(
      id: json['id'] as String,
      pmoUserId: json['pmoUserId'] as String? ??
          json['pmo_user_id'] as String? ??
          '',
      patientId: json['patientId'] as String? ??
          json['patient_id'] as String? ??
          '',
      linkedVia: json['linkedVia'] as String? ??
          json['linked_via'] as String? ??
          'phone_request',
      linkedAt: json['linkedAt'] is String
          ? DateTime.parse(json['linkedAt'] as String)
          : (json['linked_at'] is String
              ? DateTime.parse(json['linked_at'] as String)
              : json['linkedAt'] as DateTime),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pmoUserId': pmoUserId,
        'patientId': patientId,
        'linkedVia': linkedVia,
        'linkedAt': linkedAt.toIso8601String(),
        'isActive': isActive,
      };
}

// ── PMOPatientSummaryModel ────────────────────────────────────────────────────

@HiveType(typeId: 13)
class PMOPatientSummaryModel {
  @HiveField(0)
  final String patientId;

  @HiveField(1)
  final String patientName;

  @HiveField(2)
  final String tbCategory;

  @HiveField(3)
  final String tbTypeDisplay;

  @HiveField(4)
  final int treatmentDay;

  @HiveField(5)
  final int? treatmentDurationDays;

  @HiveField(6)
  final String? medicationType;

  @HiveField(7)
  final String todayMedicationStatus; // confirmed | pending | missed | no_schedule

  @HiveField(8)
  final double adherenceLast30Days;

  @HiveField(9)
  final int currentStreak;

  @HiveField(10)
  final String riskLevel; // low | medium | high | critical

  @HiveField(11)
  final DateTime? lastConfirmedAt;

  @HiveField(12)
  final DateTime linkedAt;

  PMOPatientSummaryModel({
    required this.patientId,
    required this.patientName,
    required this.tbCategory,
    required this.tbTypeDisplay,
    required this.treatmentDay,
    this.treatmentDurationDays,
    this.medicationType,
    required this.todayMedicationStatus,
    required this.adherenceLast30Days,
    required this.currentStreak,
    required this.riskLevel,
    this.lastConfirmedAt,
    required this.linkedAt,
  });

  factory PMOPatientSummaryModel.fromJson(Map<String, dynamic> json) {
    return PMOPatientSummaryModel(
      patientId: json['patientId'] as String? ??
          json['patient_id'] as String? ??
          '',
      patientName: json['patientName'] as String? ??
          json['patient_name'] as String? ??
          '',
      tbCategory: json['tbCategory'] as String? ??
          json['tb_category'] as String? ??
          'SO',
      tbTypeDisplay: json['tbTypeDisplay'] as String? ??
          json['tb_type_display'] as String? ??
          '',
      treatmentDay: json['treatmentDay'] as int? ??
          json['treatment_day'] as int? ??
          0,
      treatmentDurationDays: json['treatmentDurationDays'] as int? ??
          json['treatment_duration_days'] as int?,
      medicationType: json['medicationType'] as String? ??
          json['medication_type'] as String?,
      todayMedicationStatus: json['todayMedicationStatus'] as String? ??
          json['today_medication_status'] as String? ??
          'no_schedule',
      adherenceLast30Days:
          (json['adherenceLast30Days'] as num? ??
                  json['adherence_last_30_days'] as num? ??
                  0)
              .toDouble(),
      currentStreak: json['currentStreak'] as int? ??
          json['current_streak'] as int? ??
          0,
      riskLevel: json['riskLevel'] as String? ??
          json['risk_level'] as String? ??
          'low',
      lastConfirmedAt: json['lastConfirmedAt'] != null
          ? DateTime.parse(json['lastConfirmedAt'] as String)
          : (json['last_confirmed_at'] != null
              ? DateTime.parse(json['last_confirmed_at'] as String)
              : null),
      linkedAt: json['linkedAt'] is String
          ? DateTime.parse(json['linkedAt'] as String)
          : (json['linked_at'] is String
              ? DateTime.parse(json['linked_at'] as String)
              : DateTime.now()),
    );
  }

  // ── Helper getters ──────────────────────────────────────────────────────

  Color get statusColor {
    switch (todayMedicationStatus) {
      case 'confirmed':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'missed':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String get statusLabel {
    switch (todayMedicationStatus) {
      case 'confirmed':
        return 'Sudah minum';
      case 'pending':
        return 'Belum konfirmasi';
      case 'missed':
        return 'Terlewat';
      default:
        return 'Tidak ada jadwal';
    }
  }

  Color get riskColor {
    switch (riskLevel) {
      case 'low':
        return const Color(0xFF4CAF50);
      case 'medium':
        return const Color(0xFFFF9800);
      case 'high':
        return const Color(0xFFF44336);
      case 'critical':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
