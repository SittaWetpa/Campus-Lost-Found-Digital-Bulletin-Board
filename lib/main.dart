import 'dart:async';
import 'dart:ui';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'config/firebase_options.dart';
import 'core/observability/app_logger.dart';
import 'core/observability/console_logger_impl.dart';
import 'core/observability/crashlytics_logger_impl.dart';
import 'core/services/feature_flag_service.dart';
import 'core/services/preference_service.dart';
import 'app.dart';

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Firebase core
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on FirebaseException catch (e) {
        if (e.code != 'duplicate-app') rethrow;
        // Native Firebase still alive after hot restart — safe to continue
      }
    }

    // Hive (WBS 2.11)
    await Hive.initFlutter();
    // Register @HiveType adapters here once they're generated:
    // Hive.registerAdapter(ItemAdapter());

    // Crashlytics (WBS 2.12) – mobile only
    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(kReleaseMode);
    }

    // Preferences (WBS 2.5) — load before first frame so theme is ready
    final prefService = await PreferenceService.load();

    // Feature flags (WBS 2.13) — fetch before first frame; failure is silent
    final flagService = FeatureFlagService(FirebaseRemoteConfig.instance);
    await flagService.fetchAndActivate();

    // AppLogger (WBS 2.12) — init before first frame
    AppLogger.init(
      (!kIsWeb && kReleaseMode)
          ? CrashlyticsLoggerImpl(FirebaseCrashlytics.instance)
          : const ConsoleLoggerImpl(),
    );
    await AppLogger.setUserContext(
      userId: 'anonymous',
      appVersion: '1.0.0',
      platform: kIsWeb ? 'web' : 'android',
    );

    runApp(ProviderScope(
      overrides: [
        featureFlagsProvider.overrideWithValue(flagService),
        preferenceServiceProvider.overrideWithValue(prefService),
      ],
      child: const CampusLostFoundApp(),
    ));
  }, (error, stack) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      AppLogger.error(
        'Uncaught zone error',
        tag: 'ZoneGuard',
        error: error,
        stackTrace: stack,
      );
      if (kDebugMode) debugPrint('Uncaught zone error: $error\n$stack');
    }
  });
}
