import '../entities/feature_flags.dart';

abstract interface class FeatureFlagRepository {
  /// Fetches the latest Remote Config values and activates them.
  /// Must be called once at app startup before [currentFlags] is used.
  /// Silently falls back to [FeatureFlags.defaults] on network failure.
  Future<void> fetchAndActivate();

  /// Returns the currently activated flag values.
  /// Before [fetchAndActivate] completes, returns [FeatureFlags.defaults].
  FeatureFlags get currentFlags;

  /// Wall-clock time of the most recent successful Remote Config fetch.
  /// Returns the Unix epoch (1970-01-01) before the first fetch completes,
  /// which UI layers should display as "never".
  DateTime get lastFetchTime;
}
