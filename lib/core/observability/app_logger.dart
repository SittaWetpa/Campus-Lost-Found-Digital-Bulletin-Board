import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'console_logger_impl.dart';
import 'crashlytics_logger_impl.dart';
import 'log_event.dart';
import 'logger_repository.dart';

part 'app_logger.g.dart';

@Riverpod(keepAlive: true)
LoggerRepository loggerRepository(LoggerRepositoryRef ref) {
  if (!kIsWeb && kReleaseMode) {
    return CrashlyticsLoggerImpl(FirebaseCrashlytics.instance);
  }
  return const ConsoleLoggerImpl();
}

class AppLogger {
  AppLogger._();

  static LoggerRepository? _repo;

  static void init(LoggerRepository repo) => _repo = repo;

  static void info(
    String message, {
    required String tag,
    Map<String, Object>? extras,
  }) =>
      _emit(LogLevel.info, message, tag: tag, extras: extras);

  static void warn(
    String message, {
    required String tag,
    Map<String, Object>? extras,
  }) =>
      _emit(LogLevel.warn, message, tag: tag, extras: extras);

  static void error(
    String message, {
    required String tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object>? extras,
  }) =>
      _emit(
        LogLevel.error,
        message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
        extras: extras,
      );

  static Future<void> setUserContext({
    required String userId,
    required String appVersion,
    required String platform,
  }) =>
      _repo?.setUserContext(
            userId: userId,
            appVersion: appVersion,
            platform: platform,
          ) ??
      Future.value();

  static Future<void> updateRoute(String routeName) =>
      _repo?.updateRoute(routeName) ?? Future.value();

  static void _emit(
    LogLevel level,
    String message, {
    required String tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object>? extras,
  }) {
    final event = LogEvent.now(
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      extras: extras,
    );
    _repo?.log(event);
  }
}
