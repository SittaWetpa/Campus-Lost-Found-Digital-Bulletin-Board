import 'log_event.dart';

abstract interface class LoggerRepository {
  Future<void> log(LogEvent event);

  Future<void> setUserContext({
    required String userId,
    required String appVersion,
    required String platform,
  });

  Future<void> updateRoute(String routeName);
}
