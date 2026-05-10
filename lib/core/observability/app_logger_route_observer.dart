import 'package:flutter/material.dart' show NavigatorObserver, Route;

import 'app_logger.dart';

class AppLoggerRouteObserver extends NavigatorObserver {
  AppLoggerRouteObserver();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _report(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _report(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _report(newRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _report(previousRoute);

  void _report(Route<dynamic>? route) =>
      AppLogger.updateRoute(route?.settings.name ?? 'unknown');
}
