import 'package:hive_flutter/hive_flutter.dart';

part 'monthly_report_model.g.dart';

@HiveType(typeId: 8)
class MonthlyReportModel {
  @HiveField(0)
  final String patientId;

  @HiveField(1)
  final String reportMonth;

  @HiveField(2)
  final double adherencePercentage;

  @HiveField(3)
  final int confirmedDoses;

  @HiveField(4)
  final int missedDoses;

  @HiveField(5)
  final String? aiSummary;

  @HiveField(6)
  final String? pdfUrl;

  MonthlyReportModel({
    required this.patientId,
    required this.reportMonth,
    required this.adherencePercentage,
    required this.confirmedDoses,
    required this.missedDoses,
    this.aiSummary,
    this.pdfUrl,
  });

  factory MonthlyReportModel.fromJson(Map<String, dynamic> json) {
    return MonthlyReportModel(
      patientId: json['patientId'] as String,
      reportMonth: json['reportMonth'] as String,
      adherencePercentage: (json['adherencePercentage'] as num).toDouble(),
      confirmedDoses: json['confirmedDoses'] as int,
      missedDoses: json['missedDoses'] as int,
      aiSummary: json['aiSummary'] as String?,
      pdfUrl: json['pdfUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'reportMonth': reportMonth,
      'adherencePercentage': adherencePercentage,
      'confirmedDoses': confirmedDoses,
      'missedDoses': missedDoses,
      'aiSummary': aiSummary,
      'pdfUrl': pdfUrl,
    };
  }

  MonthlyReportModel copyWith({
    String? patientId,
    String? reportMonth,
    double? adherencePercentage,
    int? confirmedDoses,
    int? missedDoses,
    String? aiSummary,
    String? pdfUrl,
  }) {
    return MonthlyReportModel(
      patientId: patientId ?? this.patientId,
      reportMonth: reportMonth ?? this.reportMonth,
      adherencePercentage: adherencePercentage ?? this.adherencePercentage,
      confirmedDoses: confirmedDoses ?? this.confirmedDoses,
      missedDoses: missedDoses ?? this.missedDoses,
      aiSummary: aiSummary ?? this.aiSummary,
      pdfUrl: pdfUrl ?? this.pdfUrl,
    );
  }

  @override
  String toString() => 'MonthlyReportModel(patientId: $patientId, reportMonth: $reportMonth)';
}
