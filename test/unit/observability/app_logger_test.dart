// WBS 2.12 — AppLogger unit tests
//
// U1: AppLogger.error() delegates to LoggerRepository.log with level=error
// U2: AppLogger.info()  delegates to LoggerRepository.log with level=info
//     and does not trigger a second log call with level=error

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:campus_lost_found/core/observability/app_logger.dart';
import 'package:campus_lost_found/core/observability/log_event.dart';
import 'package:campus_lost_found/core/observability/logger_repository.dart';

class _MockLoggerRepository extends Mock implements LoggerRepository {}

class _NoOpLoggerRepository implements LoggerRepository {
  const _NoOpLoggerRepository();
  @override Future<void> log(LogEvent event) async {}
  @override Future<void> setUserContext({
    required String userId,
    required String appVersion,
    required String platform,
  }) async {}
  @override Future<void> updateRoute(String routeName) async {}
}

void main() {
  late _MockLoggerRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(
      LogEvent.now(level: LogLevel.info, message: '', tag: ''),
    );
  });

  setUp(() {
    mockRepo = _MockLoggerRepository();
    when(() => mockRepo.log(any())).thenAnswer((_) async {});
    AppLogger.init(mockRepo);
  });

  tearDown(() {
    AppLogger.init(const _NoOpLoggerRepository());
  });

  group('AppLogger — WBS 2.12', () {
    test(
      'U1 — error() calls repo.log with level=error and preserves error object',
      () {
        final exception = Exception('boom');

        AppLogger.error(
          'Something went wrong',
          tag: 'TestTag',
          error: exception,
          stackTrace: StackTrace.empty,
        );

        final captured =
            verify(() => mockRepo.log(captureAny())).captured.single
                as LogEvent;

        expect(captured.level, equals(LogLevel.error));
        expect(captured.message, equals('Something went wrong'));
        expect(captured.tag, equals('TestTag'));
        expect(captured.error, equals(exception));
        expect(captured.stackTrace, equals(StackTrace.empty));
      },
    );

    test(
      'U2 — info() calls repo.log with level=info and no error fields',
      () {
        AppLogger.info('User opened feed', tag: 'FeedScreen');

        final captured =
            verify(() => mockRepo.log(captureAny())).captured.single
                as LogEvent;

        expect(captured.level, equals(LogLevel.info));
        expect(captured.message, equals('User opened feed'));
        expect(captured.tag, equals('FeedScreen'));
        expect(captured.error, isNull);
        expect(captured.stackTrace, isNull);
      },
    );
  });
}
