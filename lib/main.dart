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

  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) FlutterError.dumpErrorToConsole(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) debugPrint('Unhandled error: $error\n$stack');
    return true;
  };

  await _initHive();
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: DigitalPMOApp()));
}

// ── Hive setup ────────────────────────────────────────────────────────────────

Future<void> _initHive() async {
  await Hive.initFlutter();

  // Register adapters (order doesn't matter, typeIds must be unique)
  Hive
    ..registerAdapter(UserModelAdapter())
    ..registerAdapter(PatientProfileModelAdapter())
    ..registerAdapter(MedicationScheduleModelAdapter())
    ..registerAdapter(MedicationLogModelAdapter())
    ..registerAdapter(SymptomLogModelAdapter())
    ..registerAdapter(SideEffectLogModelAdapter())
    ..registerAdapter(ControlScheduleModelAdapter())
    ..registerAdapter(DropoutRiskModelAdapter())
    ..registerAdapter(MonthlyReportModelAdapter())
    ..registerAdapter(SyncQueueItemAdapter());

  // Open all boxes in parallel
  await Future.wait([
    Hive.openBox<UserModel>(HiveBoxes.user),
    Hive.openBox<PatientProfileModel>(HiveBoxes.patientProfile),
    Hive.openBox<MedicationScheduleModel>(HiveBoxes.medicationSchedule),
    Hive.openBox<MedicationLogModel>(HiveBoxes.medicationLog),
    Hive.openBox<SymptomLogModel>(HiveBoxes.symptomLog),
    Hive.openBox<SyncQueueItem>(HiveBoxes.syncQueue),
    // Plain dynamic boxes for untyped data
    Hive.openBox<dynamic>(HiveBoxes.education),
    Hive.openBox<dynamic>(HiveBoxes.chatHistory),
    Hive.openBox<dynamic>(HiveBoxes.settings),
  ]);
}

// ── App ───────────────────────────────────────────────────────────────────────

class DigitalPMOApp extends StatelessWidget {
  const DigitalPMOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DigitalPMO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      builder: (context, child) {
        // ConnectivityBanner slides in at the top of every screen.
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
