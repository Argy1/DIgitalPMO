import 'package:hive_flutter/hive_flutter.dart';

part 'symptom_log_model.g.dart';

@HiveType(typeId: 4)
class SymptomLogModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String patientId;

  @HiveField(2)
  final DateTime loggedDate;

  @HiveField(3)
  final int coughScale;

  @HiveField(4)
  final bool fever;

  @HiveField(5)
  final double? feverTemperature;

  @HiveField(6)
  final bool shortnessOfBreath;

  @HiveField(7)
  final bool nightSweats;

  @HiveField(8)
  final int appetiteScale;

  @HiveField(9)
  final int energyScale;

  @HiveField(10)
  final double weightKg;

  @HiveField(11)
  final String? additionalNotes;

  @HiveField(12)
  final String? aiAssessment;

  SymptomLogModel({
    required this.id,
    required this.patientId,
    required this.loggedDate,
    this.coughScale = 0,
    this.fever = false,
    this.feverTemperature,
    this.shortnessOfBreath = false,
    this.nightSweats = false,
    this.appetiteScale = 5,
    this.energyScale = 5,
    required this.weightKg,
    this.additionalNotes,
    this.aiAssessment,
  });

  factory SymptomLogModel.fromJson(Map<String, dynamic> json) {
    return SymptomLogModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      loggedDate: json['loggedDate'] is String
          ? DateTime.parse(json['loggedDate'] as String)
          : json['loggedDate'] as DateTime,
      coughScale: json['coughScale'] as int? ?? 0,
      fever: json['fever'] as bool? ?? false,
      feverTemperature: (json['feverTemperature'] as num?)?.toDouble(),
      shortnessOfBreath: json['shortnessOfBreath'] as bool? ?? false,
      nightSweats: json['nightSweats'] as bool? ?? false,
      appetiteScale: json['appetiteScale'] as int? ?? 5,
      energyScale: json['energyScale'] as int? ?? 5,
      weightKg: (json['weightKg'] as num).toDouble(),
      additionalNotes: json['additionalNotes'] as String?,
      aiAssessment: json['aiAssessment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'loggedDate': loggedDate.toIso8601String(),
      'coughScale': coughScale,
      'fever': fever,
      'feverTemperature': feverTemperature,
      'shortnessOfBreath': shortnessOfBreath,
      'nightSweats': nightSweats,
      'appetiteScale': appetiteScale,
      'energyScale': energyScale,
      'weightKg': weightKg,
      'additionalNotes': additionalNotes,
      'aiAssessment': aiAssessment,
    };
  }

  SymptomLogModel copyWith({
    String? id,
    String? patientId,
    DateTime? loggedDate,
    int? coughScale,
    bool? fever,
    double? feverTemperature,
    bool? shortnessOfBreath,
    bool? nightSweats,
    int? appetiteScale,
    int? energyScale,
    double? weightKg,
    String? additionalNotes,
    String? aiAssessment,
  }) {
    return SymptomLogModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      loggedDate: loggedDate ?? this.loggedDate,
      coughScale: coughScale ?? this.coughScale,
      fever: fever ?? this.fever,
      feverTemperature: feverTemperature ?? this.feverTemperature,
      shortnessOfBreath: shortnessOfBreath ?? this.shortnessOfBreath,
      nightSweats: nightSweats ?? this.nightSweats,
      appetiteScale: appetiteScale ?? this.appetiteScale,
      energyScale: energyScale ?? this.energyScale,
      weightKg: weightKg ?? this.weightKg,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      aiAssessment: aiAssessment ?? this.aiAssessment,
    );
  }

  @override
  String toString() => 'SymptomLogModel(id: $id, patientId: $patientId)';
}
