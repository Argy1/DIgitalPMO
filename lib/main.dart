import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/navigation/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/connectivity_banner.dart';
import 'data/models/control_schedule_model.dart';
import 'data/models/dropout_risk_model.dart';
import 'data/models/medication_log_model.dart';
import 'data/models/medication_schedule_model.dart';
import 'data/models/monthly_report_model.dart';
import 'data/models/patient_profile_model.dart';
import 'data/models/side_effect_log_model.dart';
import 'data/models/symptom_log_model.dart';
import 'data/models/sync_queue_item.dart';
import 'data/models/user_model.dart';
import 'data/sync/sync_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase must be initialized before NotificationService so that the
  // FCM background handler is registered before any message arrives.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Firebase] Init skipped (no google-services.json?): $e');
  }

  FlutterError.onError = FlutterError.presentError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('Unhandled error: $error\n$stack');
    return true;
  };

  runApp(const ProviderScope(child: DigitalPMOApp()));
}

Future<void> _initHive() async {
  await Hive.initFlutter();

  // Initialization can be retried, so adapter registration must be idempotent.
  _registerAdapter(UserModelAdapter());
  _registerAdapter(PatientProfileModelAdapter());
  _registerAdapter(MedicationScheduleModelAdapter());
  _registerAdapter(MedicationLogModelAdapter());
  _registerAdapter(SymptomLogModelAdapter());
  _registerAdapter(SideEffectLogModelAdapter());
  _registerAdapter(ControlScheduleModelAdapter());
  _registerAdapter(DropoutRiskModelAdapter());
  _registerAdapter(MonthlyReportModelAdapter());
  _registerAdapter(SyncQueueItemAdapter());

  await Future.wait([
    Hive.openBox<UserModel>(HiveBoxes.user),
    Hive.openBox<PatientProfileModel>(HiveBoxes.patientProfile),
    Hive.openBox<MedicationScheduleModel>(HiveBoxes.medicationSchedule),
    Hive.openBox<MedicationLogModel>(HiveBoxes.medicationLog),
    Hive.openBox<SymptomLogModel>(HiveBoxes.symptomLog),
    Hive.openBox<SyncQueueItem>(HiveBoxes.syncQueue),
    Hive.openBox<dynamic>(HiveBoxes.education),
    Hive.openBox<dynamic>(HiveBoxes.chatHistory),
    Hive.openBox<dynamic>(HiveBoxes.settings),
  ]);
}

void _registerAdapter<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter<T>(adapter);
  }
}

Future<void> _initializeRequiredServices() async {
  await _initHive().timeout(const Duration(seconds: 10));
  unawaited(_initializeOptionalServices());
}

Future<void> _initializeOptionalServices() async {
  try {
    await NotificationService.instance.init().timeout(
      const Duration(seconds: 5),
    );
  } catch (error, stack) {
    debugPrint('Notification initialization skipped: $error\n$stack');
  }
}

typedef AppInitializer = Future<void> Function();

class DigitalPMOApp extends StatefulWidget {
  const DigitalPMOApp({
    super.key,
    this.initialize = _initializeRequiredServices,
  });

  final AppInitializer initialize;

  @override
  State<DigitalPMOApp> createState() => _DigitalPMOAppState();
}

class _DigitalPMOAppState extends State<DigitalPMOApp> {
  late Future<void> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = widget.initialize();
  }

  void _retryStartup() {
    setState(() {
      _startupFuture = widget.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupShell(child: _StartupLoadingScreen());
        }
        if (snapshot.hasError) {
          return _StartupShell(
            child: _StartupErrorScreen(onRetry: _retryStartup),
          );
        }
        return _buildAppRouter();
      },
    );
  }

  Widget _buildAppRouter() {
    // Wire notification taps → GoRouter navigation.
    NotificationService.instance.onNotificationTap = (String? route) {
      if (route != null && route.isNotEmpty) {
        appRouter.go(route);
      }
    };

    return MaterialApp.router(
      title: 'DigitalPMO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      builder: (context, child) {
        return Column(
          children: [
            const ConnectivityBanner(),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}

class _StartupShell extends StatelessWidget {
  const _StartupShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigitalPMO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: child,
    );
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A6B5A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 60, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'DigitalPMO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Menyiapkan aplikasi...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 54,
                color: Color(0xFF1A6B5A),
              ),
              const SizedBox(height: 20),
              Text(
                'Aplikasi belum siap',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Data lokal belum dapat dibuka. Silakan coba lagi.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
            ],
          ),
        ),
      ),
    );
  }
}
