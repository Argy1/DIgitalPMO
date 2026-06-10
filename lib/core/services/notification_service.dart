import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/medication_schedule_model.dart';

// ── Channel IDs ───────────────────────────────────────────────────────────────

const _chMedId = 'digitalpmo_medication';
const _chMedName = 'Pengingat Obat TB';
const _chMedDesc = 'Notifikasi pengingat minum obat TB harian';

const _chPmoId = 'digitalpmo_pmo';
const _chPmoName = 'Notifikasi PMO';
const _chPmoDesc = 'Peringatan dari PMO dan status kepatuhan';

const _chChatId = 'digitalpmo_chat';
const _chChatName = 'Pesan';
const _chChatDesc = 'Pesan dari PMO atau pasien';

// ── FCM background handler (top-level, required by Firebase) ─────────────────

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Show local notification so it makes sound even when app is killed.
  await NotificationService.instance._showFromRemoteMessage(message);
}

// ── NotificationService ───────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Callback set by app router so taps can navigate
  void Function(String? payload)? onNotificationTap;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // Local notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onLocalTap,
      onDidReceiveBackgroundNotificationResponse: _onLocalTapBackground,
    );

    await _createChannels();

    // FCM background handler must be registered before Firebase.initializeApp
    // but we register it here as well for safety.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // FCM foreground messages → show as local notification
    FirebaseMessaging.onMessage.listen(_showFromRemoteMessage);

    // FCM tap while app is in background (not killed)
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      onNotificationTap?.call(msg.data['route'] as String?);
    });

    // FCM tap that launched the app from killed state
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      onNotificationTap?.call(initial.data['route'] as String?);
    }

    _initialized = true;
  }

  Future<void> _createChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _chMedId, _chMedName,
      description: _chMedDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _chPmoId, _chPmoName,
      description: _chPmoDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _chChatId, _chChatName,
      description: _chChatDesc,
      importance: Importance.high,
      playSound: true,
    ));
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  /// Call once after login / onboarding. Returns true if granted.
  Future<bool> requestPermissions() async {
    // Android 13+
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    bool granted = true;
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
      // Also request exact alarm permission (Android 12+)
      await android.requestExactAlarmsPermission();
    }

    // iOS
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      granted = await ios.requestPermissions(
            alert: true, sound: true, badge: true,
          ) ??
          false;
    }

    // FCM permission (iOS + Android 13)
    await FirebaseMessaging.instance.requestPermission(
      alert: true, sound: true, badge: true, announcement: false,
    );

    return granted;
  }

  // ── FCM token ─────────────────────────────────────────────────────────────

  Future<String?> getFCMToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
      return null;
    }
  }

  // ── Schedule medication reminders ────────────────────────────────────────

  Future<void> scheduleAll(MedicationScheduleModel schedule) async {
    await cancelMedicationReminders();

    for (var i = 0; i < schedule.scheduleTimes.length; i++) {
      final parts = schedule.scheduleTimes[i].split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      await _scheduleDailyReminder(
        id: 1000 + i,
        hour: hour,
        minute: minute,
        reminderBefore: schedule.reminderBefore,
        schedule: schedule,
      );
    }
    debugPrint('[Notif] Scheduled ${schedule.scheduleTimes.length} reminder(s).');
  }

  Future<void> _scheduleDailyReminder({
    required int id,
    required int hour,
    required int minute,
    required int reminderBefore,
    required MedicationScheduleModel schedule,
  }) async {
    final effMin = minute - reminderBefore;
    final effHour = hour + (effMin < 0 ? -1 : 0);
    final adjMin = effMin < 0 ? effMin + 60 : effMin;

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local, now.year, now.month, now.day,
      effHour.clamp(0, 23), adjMin.clamp(0, 59),
    );
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));

    final body = schedule.medicationType == 'FDC'
        ? 'Saatnya minum ${schedule.tabletCount ?? "?"} tablet ${schedule.fdcType ?? "FDC"}. Jangan lupa konfirmasi!'
        : 'Saatnya minum obat TB: ${schedule.medications.join(", ")}. Jangan lupa konfirmasi!';

    await _plugin.zonedSchedule(
      id,
      'Waktunya Minum Obat TB 💊',
      body,
      next,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chMedId, _chMedName,
          channelDescription: _chMedDesc,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF1A6B5A),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentSound: true, presentBadge: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({'route': '/medication/confirm'}),
    );
  }

  // ── Immediate notifications ───────────────────────────────────────────────

  Future<void> showMedicationConfirmed(int streak) async {
    await _plugin.show(
      2000,
      'Obat Terkonfirmasi ✅',
      'Hebat! Streak kamu sekarang $streak hari berturut-turut 🔥',
      _medDetails(),
      payload: '/home/dashboard',
    );
  }

  Future<void> showMissedAlert(String patientName) async {
    await _plugin.show(
      2001,
      'Pasien Belum Minum Obat ⚠️',
      '$patientName belum konfirmasi obat hari ini.',
      _pmoDetails(),
      payload: '/pmo/dashboard',
    );
  }

  Future<void> showPMOLinkRequest(String pmoName) async {
    await _plugin.show(
      2002,
      'Permintaan Link PMO',
      '$pmoName ingin menjadi PMO kamu. Buka app untuk menyetujui.',
      _pmoDetails(),
      payload: '/home/dashboard',
    );
  }

  Future<void> showChatMessage({
    required String senderName,
    required String message,
    required String route,
  }) async {
    await _plugin.show(
      2003,
      'Pesan dari $senderName',
      message,
      _chatDetails(),
      payload: route,
    );
  }

  Future<void> showImmediate({
    required String title,
    required String body,
    int id = 9999,
    String? route,
  }) async {
    await _plugin.show(id, title, body, _medDetails(), payload: route);
  }

  // ── Cancel helpers ────────────────────────────────────────────────────────

  Future<void> cancelMedicationReminders() async {
    for (var i = 0; i < 10; i++) {
      await _plugin.cancel(1000 + i);
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
  Future<void> cancel(int id) => _plugin.cancel(id);

  // ── Internal ──────────────────────────────────────────────────────────────

  NotificationDetails _medDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _chMedId, _chMedName,
          importance: Importance.max, priority: Priority.high,
          playSound: true, enableVibration: true,
          icon: '@mipmap/ic_launcher', color: Color(0xFF1A6B5A),
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

  NotificationDetails _pmoDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _chPmoId, _chPmoName,
          importance: Importance.high, priority: Priority.high,
          playSound: true, enableVibration: true,
          icon: '@mipmap/ic_launcher', color: Color(0xFF1A6B5A),
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

  NotificationDetails _chatDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _chChatId, _chChatName,
          importance: Importance.high, priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher', color: Color(0xFF1A6B5A),
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

  Future<void> _showFromRemoteMessage(RemoteMessage message) async {
    final notif = message.notification;
    final title = notif?.title ?? message.data['title'] as String? ?? 'DigitalPMO';
    final body = notif?.body ?? message.data['body'] as String? ?? '';
    final route = message.data['route'] as String?;

    final channelId = message.data['channel'] as String? ?? _chMedId;
    NotificationDetails details;
    if (channelId == _chChatId) {
      details = _chatDetails();
    } else if (channelId == _chPmoId) {
      details = _pmoDetails();
    } else {
      details = _medDetails();
    }

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      title, body, details,
      payload: route,
    );
  }

  void _onLocalTap(NotificationResponse response) {
    onNotificationTap?.call(response.payload);
  }
}

@pragma('vm:entry-point')
void _onLocalTapBackground(NotificationResponse response) {
  // Background tap — navigation is handled when app resumes via onNotificationTap
  debugPrint('[Notif] Background tap: ${response.payload}');
}
