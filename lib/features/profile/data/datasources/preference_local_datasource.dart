import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_lost_found/features/profile/domain/entities/user_preferences.dart';

abstract interface class PreferenceLocalDatasource {
  Future<UserPreferences> getUserPreferences();
  Future<void> setNotificationsEnabled({required bool value});
  Future<void> setThemeMode(String mode);
  Future<String?> getThemeMode();
  Future<void> setLastViewedCategory(String? category);
  Future<String?> getLastViewedCategory();
}

class SharedPreferencesDatasource implements PreferenceLocalDatasource {
  static const _keyNotifications = 'pref_notifications_enabled';
  static const _keyThemeMode = 'pref_theme_mode';
  static const _keyLastViewedCategory = 'pref_last_viewed_category';

  @override
  Future<UserPreferences> getUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return UserPreferences(
      notificationsEnabled: prefs.getBool(_keyNotifications) ?? true,
    );
  }

  @override
  Future<void> setNotificationsEnabled({required bool value}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  @override
  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  @override
  Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode);
  }

  @override
  Future<void> setLastViewedCategory(String? category) async {
    final prefs = await SharedPreferences.getInstance();
    if (category == null) {
      await prefs.remove(_keyLastViewedCategory);
    } else {
      await prefs.setString(_keyLastViewedCategory, category);
    }
  }

  @override
  Future<String?> getLastViewedCategory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastViewedCategory);
  }
}
