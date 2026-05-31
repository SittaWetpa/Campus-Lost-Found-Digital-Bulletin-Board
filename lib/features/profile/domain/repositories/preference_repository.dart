import 'package:campus_lost_found/features/profile/domain/entities/user_preferences.dart';

abstract interface class PreferenceRepository {
  /// Returns all preferences; returns defaults if never set.
  Future<UserPreferences> getUserPreferences();

  Future<void> setNotificationsEnabled({required bool value});
  Future<void> setThemeMode(AppThemeMode mode);
  Future<void> setLastViewedCategory(String? category);
}
