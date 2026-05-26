import 'package:hive_flutter/hive_flutter.dart';

part 'app_state_model.g.dart';

@HiveType(typeId: 8)
class AppStateModel {
  @HiveField(0)
  final String patientId;

  @HiveField(1)
  final List<String> shownDialogIds;

  @HiveField(2)
  final List<int> shownMilestones;

  @HiveField(3)
  final DateTime? lastRiskScoreCalculation;

  AppStateModel({
    required this.patientId,
    this.shownDialogIds = const [],
    this.shownMilestones = const [],
    this.lastRiskScoreCalculation,
  });

  factory AppStateModel.fromJson(Map<String, dynamic> json) {
    return AppStateModel(
      patientId: json['patientId'] as String,
      shownDialogIds: List<String>.from(json['shownDialogIds'] as List? ?? []),
      shownMilestones: List<int>.from(json['shownMilestones'] as List? ?? []),
      lastRiskScoreCalculation: json['lastRiskScoreCalculation'] is String
          ? DateTime.parse(json['lastRiskScoreCalculation'] as String)
          : json['lastRiskScoreCalculation'] as DateTime?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'shownDialogIds': shownDialogIds,
      'shownMilestones': shownMilestones,
      'lastRiskScoreCalculation': lastRiskScoreCalculation?.toIso8601String(),
    };
  }

  AppStateModel copyWith({
    String? patientId,
    List<String>? shownDialogIds,
    List<int>? shownMilestones,
    DateTime? lastRiskScoreCalculation,
  }) {
    return AppStateModel(
      patientId: patientId ?? this.patientId,
      shownDialogIds: shownDialogIds ?? this.shownDialogIds,
      shownMilestones: shownMilestones ?? this.shownMilestones,
      lastRiskScoreCalculation: lastRiskScoreCalculation ?? this.lastRiskScoreCalculation,
    );
  }

  bool hasShownDialog(String dialogId) => shownDialogIds.contains(dialogId);

  AppStateModel markDialogShown(String dialogId) {
    if (hasShownDialog(dialogId)) return this;
    return copyWith(
      shownDialogIds: [...shownDialogIds, dialogId],
    );
  }

  bool hasShownMilestone(int percentage) => shownMilestones.contains(percentage);

  AppStateModel markMilestoneShown(int percentage) {
    if (hasShownMilestone(percentage)) return this;
    return copyWith(
      shownMilestones: [...shownMilestones, percentage],
    );
  }

  @override
  String toString() => 'AppStateModel(patientId: $patientId)';
}
