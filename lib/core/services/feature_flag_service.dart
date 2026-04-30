// WBS 2.13 — Remote Config integration is a separate work package.
// Until then this service returns hardcoded in-app defaults so all
// feature-flagged code paths compile and run correctly.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeatureFlagService {
  const FeatureFlagService();

  // WBS 2.10 / 2.13 — gates the Secret Question feature on Founder Posts
  bool get secretQuestionEnabled => true;
}

final featureFlagsProvider = Provider<FeatureFlagService>(
  (_) => const FeatureFlagService(),
);
