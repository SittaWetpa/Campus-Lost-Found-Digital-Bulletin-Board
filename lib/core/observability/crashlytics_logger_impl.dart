import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

import 'log_event.dart';
import 'logger_repository.dart';

class CrashlyticsLoggerImpl implements LoggerRepository {
  const CrashlyticsLoggerImpl(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  bool get _active => !kIsWeb && kReleaseMode;

  @override
  Future<void> log(LogEvent event) async {
    if (!_active) return;
    await _crashlytics.log(_breadcrumb(event));
    if (event.level == LogLevel.error) {
      await _crashlytics.recordError(
        event.error ?? event.message,
        event.stackTrace,
        reason: event.message,
        information: _extrasList(event.extras),
        fatal: false,
      );
    }
  }

  @override
  Future<void> setUserContext({
    required String userId,
    required String appVersion,
    required String platform,
  }) async {
    if (!_active) return;
    await _crashlytics.setUserIdentifier(userId);
    await _crashlytics.setCustomKey('appVersion', appVersion);
    await _crashlytics.setCustomKey('platform', platform);
  }

  @override
  Future<void> updateRoute(String routeName) async {
    if (!_active) return;
    await _crashlytics.setCustomKey('currentRoute', routeName);
  }

  String _breadcrumb(LogEvent event) {
    final level = event.level.name.toUpperCase();
    return '[$level][${event.tag}] ${event.message}';
  }

  List<Object> _extrasList(Map<String, Object>? extras) {
    if (extras == null) return const [];
    return extras.entries.map((e) => '${e.key}=${e.value}').toList();
  }
}
