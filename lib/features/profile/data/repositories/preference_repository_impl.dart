import 'package:campus_lost_found/features/profile/data/datasources/preference_local_datasource.dart';
import 'package:campus_lost_found/features/profile/domain/entities/user_preferences.dart';
import 'package:campus_lost_found/features/profile/domain/repositories/preference_repository.dart';

class PreferenceRepositoryImpl implements PreferenceRepository {
  final PreferenceLocalDatasource _datasource;
  const PreferenceRepositoryImpl(this._datasource);

  @override
  Future<UserPreferences> getUserPreferences() =>
      _datasource.getUserPreferences();

  @override
  Future<void> setNotificationsEnabled({required bool value}) =>
      _datasource.setNotificationsEnabled(value: value);
}
