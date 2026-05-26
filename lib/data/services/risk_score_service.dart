import 'package:hive_flutter/hive_flutter.dart';
import '../models/dropout_risk_model.dart';
import '../models/medication_log_model.dart';

enum RiskLevel { low, medium, high }

class RiskScoreService {
  static const double _baseScore = 0.0;

  /// Calculate dropout risk score (0-100) based on multiple factors
  /// Called weekly by background job
  static Future<double> calculateWeeklyRisk({
    required String patientId,
    required List<MedicationLogModel> recentLogs,
    required bool hasSideEffects,
    required bool symptomWorsening,
    required double notificationResponseRate,
    required int consecutiveSkips,
  }) async {
    double score = _baseScore;

    // Factor 1: Adherence trend (0-30 points)
    final adherenceScore = _calculateAdherenceScore(recentLogs);
    score += adherenceScore;

    // Factor 2: Side effects penalty (0-20 points)
    if (hasSideEffects) {
      score += 20;
    }

    // Factor 3: Symptom worsening penalty (0-20 points)
    if (symptomWorsening) {
      score += 20;
    }

    // Factor 4: Notification response rate (0-15 points)
    final notifScore = _calculateNotificationScore(notificationResponseRate);
    score += notifScore;

    // Factor 5: Consecutive skips penalty (0-15 points)
    final skipScore = _calculateConsecutiveSkipsScore(consecutiveSkips);
    score += skipScore;

    // Clamp to 0-100 range
    score = score.clamp(0.0, 100.0);

    return score;
  }

  /// Calculate adherence score based on 7-day trend
  /// Returns 0-30 points
  static double _calculateAdherenceScore(List<MedicationLogModel> recentLogs) {
    if (recentLogs.isEmpty) return 30.0; // Max penalty if no data

    final confirmedCount = recentLogs
        .where((log) => log.status == 'confirmed')
        .length;

    final adherenceRate = confirmedCount / recentLogs.length;

    // Map adherence rate to penalty
    if (adherenceRate >= 0.95) return 0.0; // Excellent
    if (adherenceRate >= 0.85) return 5.0; // Good
    if (adherenceRate >= 0.75) return 10.0; // Fair
    if (adherenceRate >= 0.65) return 15.0; // Poor
    return 30.0; // Very poor
  }

  /// Calculate notification response score
  /// Returns 0-15 points (penalty for low response rate)
  static double _calculateNotificationScore(double responseRate) {
    // responseRate is 0.0-1.0
    if (responseRate >= 0.8) return 0.0; // Good response
    if (responseRate >= 0.6) return 5.0;
    if (responseRate >= 0.4) return 10.0;
    return 15.0; // Very poor response
  }

  /// Calculate consecutive skips penalty
  /// Returns 0-15 points
  static double _calculateConsecutiveSkipsScore(int consecutiveSkips) {
    if (consecutiveSkips == 0) return 0.0;
    if (consecutiveSkips == 1) return 3.0;
    if (consecutiveSkips == 2) return 6.0;
    if (consecutiveSkips == 3) return 10.0;
    if (consecutiveSkips >= 4) return 15.0;
    return 0.0;
  }

  /// Determine risk level from score
  static RiskLevel getRiskLevel(double score) {
    if (score < 31) return RiskLevel.low;
    if (score < 61) return RiskLevel.medium;
    return RiskLevel.high;
  }

  /// Get risk level display name
  static String getRiskLevelName(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'RENDAH';
      case RiskLevel.medium:
        return 'SEDANG';
      case RiskLevel.high:
        return 'TINGGI';
    }
  }

  /// Get notification intensity multiplier based on risk level
  /// Used to increase notification frequency for high-risk patients
  static int getNotificationIntensity(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 1; // Normal cadence
      case RiskLevel.medium:
        return 2; // 2x more notifications
      case RiskLevel.high:
        return 3; // 3x more notifications
    }
  }

  /// Save risk score to local storage
  static Future<void> saveRiskScore(DropoutRiskModel riskModel) async {
    final box = await Hive.openBox<DropoutRiskModel>('dropoutRisk');
    await box.put('current_${riskModel.patientId}', riskModel);
  }

  /// Get latest risk score for patient
  static Future<DropoutRiskModel?> getLatestRiskScore(String patientId) async {
    final box = await Hive.openBox<DropoutRiskModel>('dropoutRisk');
    return box.get('current_$patientId');
  }

  /// Batch save historical risk scores (for analytics)
  static Future<void> saveHistoricalRiskScore(DropoutRiskModel riskModel) async {
    final box = await Hive.openBox<DropoutRiskModel>('dropoutRiskHistory');
    final key = '${riskModel.patientId}_${riskModel.calculatedAt.toIso8601String()}';
    await box.put(key, riskModel);
  }

  /// Get risk score trend (last 4 weeks)
  static Future<List<DropoutRiskModel>> getRiskScoreTrend(String patientId) async {
    final box = await Hive.openBox<DropoutRiskModel>('dropoutRiskHistory');
    final trendData = <DropoutRiskModel>[];
    final fourWeeksAgo = DateTime.now().subtract(const Duration(days: 28));

    for (final value in box.values) {
      if (value.patientId == patientId && value.calculatedAt.isAfter(fourWeeksAgo)) {
        trendData.add(value);
      }
    }

    // Sort by date descending
    trendData.sort((a, b) => b.calculatedAt.compareTo(a.calculatedAt));
    return trendData;
  }
}
