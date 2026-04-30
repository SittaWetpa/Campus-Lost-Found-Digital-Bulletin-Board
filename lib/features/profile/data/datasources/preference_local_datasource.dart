import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_lost_found/features/profile/domain/entities/user_preferences.dart';

abstract interface class PreferenceLocalDatasource {
  Future<UserPreferences> getUserPreferences();
  Future<void> setNotificationsEnabled({required bool value});
}

class SharedPreferencesDatasource implements PreferenceLocalDatasource {
  static const _keyNotifications = 'pref_notifications_enabled';

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
}
