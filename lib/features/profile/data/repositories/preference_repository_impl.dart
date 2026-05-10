import 'package:campus_lost_found/features/profile/data/datasources/preference_local_datasource.dart';
import 'package:campus_lost_found/features/profile/domain/entities/user_preferences.dart';
import 'package:campus_lost_found/features/profile/domain/repositories/preference_repository.dart';

class PreferenceRepositoryImpl implements PreferenceRepository {
  final PreferenceLocalDatasource _datasource;
  const PreferenceRepositoryImpl(this._datasource);

  @override
  Future<UserPreferences> getUserPreferences() async {
    final base = await _datasource.getUserPreferences();
    final rawTheme = await _datasource.getThemeMode();
    final lastViewedCategory = await _datasource.getLastViewedCategory();
    return UserPreferences(
      notificationsEnabled: base.notificationsEnabled,
      themeMode: _parseThemeMode(rawTheme),
      lastViewedCategory: lastViewedCategory,
    );
  }

  @override
  Future<void> setNotificationsEnabled({required bool value}) =>
      _datasource.setNotificationsEnabled(value: value);

  @override
  Future<void> setThemeMode(AppThemeMode mode) =>
      _datasource.setThemeMode(mode.name);

  @override
  Future<void> setLastViewedCategory(String? category) =>
      _datasource.setLastViewedCategory(category);

  AppThemeMode _parseThemeMode(String? raw) =>
      AppThemeMode.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => AppThemeMode.system,
      );
}
