import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/medication_schedule_model.dart';

// ── Channel constants ─────────────────────────────────────────────────────────

const _channelId = 'digitalpmo_medication';
const _channelName = 'Pengingat Obat TB';
const _channelDesc = 'Notifikasi pengingat minum obat TB harian';

// ── NotificationService ───────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false, // asked explicitly during onboarding
      requestSoundPermission: false,
      requestBadgePermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    await _createAndroidChannel();
    _initialized = true;
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  /// Call during onboarding for iOS permission prompt.
  Future<bool> requestPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            sound: true,
            badge: true,
          ) ??
          false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  /// Cancel all existing scheduled notifications and reschedule from [schedule].
  /// Call on first login, every 7 days, or after settings change.
  Future<void> scheduleAll(MedicationScheduleModel schedule) async {
    await cancelAll();

    for (var i = 0; i < schedule.scheduleTimes.length; i++) {
      final timeStr = schedule.scheduleTimes[i];
      final parts = timeStr.split(':');
      if (parts.length < 2) continue;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final notifId = 1000 + i; // stable IDs across reschedules
      await _scheduleDaily(
        id: notifId,
        hour: hour,
        minute: minute,
        reminderBefore: schedule.reminderBefore,
        medications: schedule.medications,
      );
    }

    debugPrint(
      '[Notifications] Scheduled ${schedule.scheduleTimes.length} daily reminder(s).',
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required int reminderBefore,
    required List<String> medications,
  }) async {
    // Fire `reminderBefore` minutes before the scheduled dose time
    final effectiveMinute = minute - reminderBefore;
    final effectiveHour = hour + (effectiveMinute < 0 ? -1 : 0);
    final adjustedMinute = effectiveMinute < 0 ? effectiveMinute + 60 : effectiveMinute;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      effectiveHour.clamp(0, 23),
      adjustedMinute.clamp(0, 59),
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final medNames = medications.join(', ');

    await _plugin.zonedSchedule(
      id,
      'Waktunya Minum Obat TB 💊',
      'Saatnya minum $medNames. Jangan lupa konfirmasi!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  // ── Immediate / one-shot ──────────────────────────────────────────────────

  Future<void> showImmediate({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true),
      ),
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> cancel(int id) => _plugin.cancel(id);

  // ── Tap handler ───────────────────────────────────────────────────────────

  void _onTap(NotificationResponse response) {
    // Route to medication confirm screen — handled by GoRouter in the app.
    debugPrint('[Notifications] Tapped: payload=${response.payload}');
  }
}
