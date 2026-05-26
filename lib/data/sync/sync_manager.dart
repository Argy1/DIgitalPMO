import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/services/api_service.dart';
import '../../core/utils/connectivity_manager.dart';
import '../models/medication_schedule_model.dart';
import '../models/patient_profile_model.dart';
import '../models/sync_queue_item.dart';

/// Box name constants shared across the app.
class HiveBoxes {
  static const String user = 'userBox';
  static const String patientProfile = 'patientProfileBox';
  static const String medicationSchedule = 'medicationScheduleBox';
  static const String medicationLog = 'medicationLogBox';
  static const String symptomLog = 'symptomLogBox';
  static const String education = 'educationBox';
  static const String chatHistory = 'chatHistoryBox';
  static const String settings = 'settingsBox';
  static const String syncQueue = 'syncQueueBox';
}

class SyncManager {
  SyncManager._();
  static final SyncManager instance = SyncManager._();

  bool _syncing = false;

  Box<SyncQueueItem> get _queue => Hive.box<SyncQueueItem>(HiveBoxes.syncQueue);

  // ── Public entry point ────────────────────────────────────────────────────

  Future<void> syncAll() async {
    if (_syncing) return;
    if (!await ConnectivityManager.instance.isOnline()) return;

    _syncing = true;
    try {
      await uploadPendingPhotos();
      await syncPendingLogs();
      await refreshLocalCache();
    } finally {
      _syncing = false;
    }
  }

  // ── Upload pending photos ─────────────────────────────────────────────────

  Future<void> uploadPendingPhotos() async {
    final items = _queue.values
        .where((i) => i.type == SyncType.photo && !i.isAbandoned)
        .toList();

    for (final item in items) {
      try {
        final file = File(item.localPath!);
        if (!file.existsSync()) {
          await item.delete();
          continue;
        }

        final bytes = await file.readAsBytes();
        final base64Photo = base64Encode(bytes);
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;

        await ApiService.instance.confirmMedication(
          scheduleId: payload['schedule_id'] as String,
          photoBase64: base64Photo,
          deviceId: payload['device_id'] as String?,
          photoTakenAt: item.createdAt,
        );

        // Successfully synced — remove from queue and delete local file
        await item.delete();
        try {
          await file.delete();
        } catch (_) {}
      } catch (e) {
        if (e is NetworkException) break; // stop if offline mid-sync
        item.attempts++;
        item.lastAttempt = DateTime.now();
        await item.save();
      }
    }
  }

  // ── Sync pending medication / symptom logs ────────────────────────────────

  Future<void> syncPendingLogs() async {
    final items = _queue.values
        .where((i) =>
            (i.type == SyncType.symptom || i.type == SyncType.medication) &&
            !i.isAbandoned)
        .toList();

    for (final item in items) {
      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;

        if (item.type == SyncType.symptom) {
          await ApiService.instance.logSymptom(payload);
        }
        // MEDICATION type (non-photo confirms, e.g. skip) can be added here.

        await item.delete();
      } catch (e) {
        if (e is NetworkException) break;
        item.attempts++;
        item.lastAttempt = DateTime.now();
        await item.save();
      }
    }
  }

  // ── Refresh local cache ───────────────────────────────────────────────────

  Future<void> refreshLocalCache() async {
    await Future.wait([
      _refreshSchedule(),
      _refreshProfile(),
    ]);
  }

  Future<void> _refreshSchedule() async {
    try {
      final data = await ApiService.instance.getTodayMedication();
      final scheduleData = data['schedule'] as Map<String, dynamic>?;
      if (scheduleData != null) {
        final schedule = MedicationScheduleModel.fromJson(scheduleData);
        final box =
            Hive.box<MedicationScheduleModel>(HiveBoxes.medicationSchedule);
        await box.put('today', schedule);
      }
    } catch (_) {
      // Stale cache is acceptable during refresh failure.
    }
  }

  Future<void> _refreshProfile() async {
    try {
      final data = await ApiService.instance.getMyProfile();
      final profileData =
          data['patient_profile'] as Map<String, dynamic>?;
      if (profileData != null) {
        final profile = PatientProfileModel.fromJson(profileData);
        final box =
            Hive.box<PatientProfileModel>(HiveBoxes.patientProfile);
        await box.put('me', profile);
      }
    } catch (_) {}
  }

  // ── Queue helpers ─────────────────────────────────────────────────────────

  /// Enqueue a photo confirmation to be uploaded when online.
  Future<void> enqueuePhoto({
    required String localPath,
    required String scheduleId,
    String? deviceId,
    required DateTime photoTakenAt,
  }) async {
    final payloadMap = <String, dynamic>{
      'schedule_id': scheduleId,
      'photo_taken_at': photoTakenAt.toIso8601String(),
    };
    if (deviceId != null) payloadMap['device_id'] = deviceId;
    final item = SyncQueueItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: SyncType.photo,
      payload: jsonEncode(payloadMap),
      localPath: localPath,
      createdAt: photoTakenAt,
    );
    await _queue.put(item.id, item);
  }

  /// Enqueue a symptom log to be uploaded when online.
  Future<void> enqueueSymptom(Map<String, dynamic> symptomPayload) async {
    final item = SyncQueueItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: SyncType.symptom,
      payload: jsonEncode(symptomPayload),
      createdAt: DateTime.now(),
    );
    await _queue.put(item.id, item);
  }

  /// Number of items still pending sync.
  int get pendingCount => _queue.values
      .where((i) => !i.isAbandoned)
      .length;
}
