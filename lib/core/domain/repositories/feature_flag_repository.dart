import '../entities/feature_flags.dart';

abstract interface class FeatureFlagRepository {
  /// Fetches the latest Remote Config values and activates them.
  /// Must be called once at app startup before [currentFlags] is used.
  /// Silently falls back to [FeatureFlags.defaults] on network failure.
  Future<void> fetchAndActivate();

  /// Returns the currently activated flag values.
  /// Before [fetchAndActivate] completes, returns [FeatureFlags.defaults].
  FeatureFlags get currentFlags;
}
