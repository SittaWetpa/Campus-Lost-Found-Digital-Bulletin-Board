import 'package:flutter/material.dart';

/// Global key for the root [ScaffoldMessenger]. Lets non-widget code
/// (router redirects, top-level error handlers) surface a [SnackBar]
/// without a [BuildContext]. Wired into [MaterialApp.router] in
/// `lib/app.dart`.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
