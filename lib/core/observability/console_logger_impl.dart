import 'package:flutter/foundation.dart' show debugPrint;

import 'log_event.dart';
import 'logger_repository.dart';

class ConsoleLoggerImpl implements LoggerRepository {
  const ConsoleLoggerImpl();

  @override
  Future<void> log(LogEvent event) async => debugPrint(_format(event));

  @override
  Future<void> setUserContext({
    required String userId,
    required String appVersion,
    required String platform,
  }) async =>
      debugPrint(
        '[OBSERVABILITY] session: userId=$userId appVersion=$appVersion platform=$platform',
      );

  @override
  Future<void> updateRoute(String routeName) async =>
      debugPrint('[OBSERVABILITY] route -> $routeName');

  String _format(LogEvent event) {
    final level = event.level.name.toUpperCase();
    final buf = StringBuffer(
      '[${event.timestamp.toIso8601String()}][$level][${event.tag}] ${event.message}',
    );
    if (event.error != null) buf.write('\n  error: ${event.error}');
    if (event.stackTrace != null) buf.write('\n  stack: ${event.stackTrace}');
    if (event.extras != null && event.extras!.isNotEmpty) {
      buf.write('\n  extras: ${event.extras}');
    }
    return buf.toString();
  }
}
