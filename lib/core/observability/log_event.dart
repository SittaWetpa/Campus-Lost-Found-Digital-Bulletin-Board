enum LogLevel { info, warn, error }

class LogEvent {
  final LogLevel level;
  final String message;
  final String tag;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, Object>? extras;
  final DateTime timestamp;

  const LogEvent({
    required this.level,
    required this.message,
    required this.tag,
    this.error,
    this.stackTrace,
    this.extras,
    required this.timestamp,
  });

  factory LogEvent.now({
    required LogLevel level,
    required String message,
    required String tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object>? extras,
  }) =>
      LogEvent(
        level: level,
        message: message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
        extras: extras,
        timestamp: DateTime.now(),
      );
}
