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
import 'core/services/feature_flag_service.dart';
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

    // Feature flags (WBS 2.13) — fetch before first frame; failure is silent
    final flagService = FeatureFlagService(FirebaseRemoteConfig.instance);
    await flagService.fetchAndActivate();

    runApp(ProviderScope(
      overrides: [
        featureFlagsProvider.overrideWithValue(flagService),
      ],
      child: const CampusLostFoundApp(),
    ));
  }, (error, stack) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      if (kDebugMode) debugPrint('Uncaught zone error: $error\n$stack');
    }
  });
}
