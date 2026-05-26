import 'package:hive_flutter/hive_flutter.dart';

part 'dropout_risk_model.g.dart';

@HiveType(typeId: 7)
class DropoutRiskModel {
  @HiveField(0)
  final String patientId;

  @HiveField(1)
  final DateTime calculatedAt;

  @HiveField(2)
  final double score;

  @HiveField(3)
  final String riskLevel;

  @HiveField(4)
  final Map<String, dynamic> factors;

  @HiveField(5)
  final String? aiRecommendation;

  DropoutRiskModel({
    required this.patientId,
    required this.calculatedAt,
    required this.score,
    this.riskLevel = 'LOW',
    required this.factors,
    this.aiRecommendation,
  });

  factory DropoutRiskModel.fromJson(Map<String, dynamic> json) {
    return DropoutRiskModel(
      patientId: json['patientId'] as String,
      calculatedAt: json['calculatedAt'] is String
          ? DateTime.parse(json['calculatedAt'] as String)
          : json['calculatedAt'] as DateTime,
      score: (json['score'] as num).toDouble(),
      riskLevel: json['riskLevel'] as String? ?? 'LOW',
      factors: Map<String, dynamic>.from(json['factors'] as Map),
      aiRecommendation: json['aiRecommendation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'calculatedAt': calculatedAt.toIso8601String(),
      'score': score,
      'riskLevel': riskLevel,
      'factors': factors,
      'aiRecommendation': aiRecommendation,
    };
  }

  DropoutRiskModel copyWith({
    String? patientId,
    DateTime? calculatedAt,
    double? score,
    String? riskLevel,
    Map<String, dynamic>? factors,
    String? aiRecommendation,
  }) {
    return DropoutRiskModel(
      patientId: patientId ?? this.patientId,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      score: score ?? this.score,
      riskLevel: riskLevel ?? this.riskLevel,
      factors: factors ?? this.factors,
      aiRecommendation: aiRecommendation ?? this.aiRecommendation,
    );
  }

  @override
  String toString() => 'DropoutRiskModel(patientId: $patientId, riskLevel: $riskLevel)';
}
