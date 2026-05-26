import 'package:hive_flutter/hive_flutter.dart';

part 'medication_log_model.g.dart';

@HiveType(typeId: 3)
class MedicationLogModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String patientId;

  @HiveField(2)
  final String scheduleId;

  @HiveField(3)
  final DateTime scheduledTime;

  @HiveField(4)
  final DateTime? confirmedAt;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final String? photoUrl;

  @HiveField(7)
  final bool isPhotoVerified;

  @HiveField(8)
  final int streakCount;

  MedicationLogModel({
    required this.id,
    required this.patientId,
    required this.scheduleId,
    required this.scheduledTime,
    this.confirmedAt,
    this.status = 'PENDING',
    this.photoUrl,
    this.isPhotoVerified = false,
    this.streakCount = 0,
  });

  factory MedicationLogModel.fromJson(Map<String, dynamic> json) {
    return MedicationLogModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      scheduleId: json['scheduleId'] as String,
      scheduledTime: json['scheduledTime'] is String
          ? DateTime.parse(json['scheduledTime'] as String)
          : json['scheduledTime'] as DateTime,
      confirmedAt: json['confirmedAt'] != null
          ? (json['confirmedAt'] is String
              ? DateTime.parse(json['confirmedAt'] as String)
              : json['confirmedAt'] as DateTime)
          : null,
      status: json['status'] as String? ?? 'PENDING',
      photoUrl: json['photoUrl'] as String?,
      isPhotoVerified: json['isPhotoVerified'] as bool? ?? false,
      streakCount: json['streakCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'scheduleId': scheduleId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'status': status,
      'photoUrl': photoUrl,
      'isPhotoVerified': isPhotoVerified,
      'streakCount': streakCount,
    };
  }

  MedicationLogModel copyWith({
    String? id,
    String? patientId,
    String? scheduleId,
    DateTime? scheduledTime,
    DateTime? confirmedAt,
    String? status,
    String? photoUrl,
    bool? isPhotoVerified,
    int? streakCount,
  }) {
    return MedicationLogModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      scheduleId: scheduleId ?? this.scheduleId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      isPhotoVerified: isPhotoVerified ?? this.isPhotoVerified,
      streakCount: streakCount ?? this.streakCount,
    );
  }

  @override
  String toString() => 'MedicationLogModel(id: $id, status: $status)';
}
