// WBS 2.13 — Remote Config integration is a separate work package.
// Until then this service returns hardcoded in-app defaults so all
// feature-flagged code paths compile and run correctly.

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feature_flag_service.g.dart';

class FeatureFlagService {
  const FeatureFlagService();

  // WBS 2.10 / 2.13 — gates the Secret Question feature on Founder Posts
  bool get secretQuestionEnabled => true;

  // WBS 2.14 — gates the Sensitive Item selector on the Post Form
  bool get sensitiveItemEnabled => true;

  // WBS 1.3 / 2.14 — security office phone number for sensitive items
  String get securityOfficeContact => '02-470-9999';
}

@riverpod
FeatureFlagService featureFlags(_) => const FeatureFlagService();
