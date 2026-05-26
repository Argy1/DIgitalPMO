import 'package:hive_flutter/hive_flutter.dart';

part 'sync_queue_item.g.dart';

/// Sync queue item types
class SyncType {
  static const String photo = 'PHOTO';
  static const String symptom = 'SYMPTOM';
  static const String medication = 'MEDICATION';
}

@HiveType(typeId: 10)
class SyncQueueItem extends HiveObject {
  @HiveField(0)
  String id;

  /// 'PHOTO' | 'SYMPTOM' | 'MEDICATION'
  @HiveField(1)
  String type;

  /// JSON-encoded payload map
  @HiveField(2)
  String payload;

  /// Absolute path to local photo file (PHOTO type only)
  @HiveField(3)
  String? localPath;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  int attempts;

  @HiveField(6)
  DateTime? lastAttempt;

  SyncQueueItem({
    required this.id,
    required this.type,
    required this.payload,
    this.localPath,
    required this.createdAt,
    this.attempts = 0,
    this.lastAttempt,
  });

  /// Maximum upload attempts before an item is abandoned
  static const int maxAttempts = 5;

  bool get isAbandoned => attempts >= maxAttempts;

  Map<String, dynamic> get payloadMap {
    try {
      // Avoid dart:convert import here — caller decodes as needed
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  String toString() =>
      'SyncQueueItem(id: $id, type: $type, attempts: $attempts)';
}
