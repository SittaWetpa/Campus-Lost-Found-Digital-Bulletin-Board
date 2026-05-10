// WBS 2.5 — Repository unit tests (enum conversion + delegation)
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_lost_found/features/profile/data/datasources/preference_local_datasource.dart';
import 'package:campus_lost_found/features/profile/data/repositories/preference_repository_impl.dart';
import 'package:campus_lost_found/features/profile/domain/entities/user_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  PreferenceRepositoryImpl makeRepo() =>
      PreferenceRepositoryImpl(SharedPreferencesDatasource());

  group('PreferenceRepositoryImpl — WBS 2.5', () {
    test('01 stored "dark" → getUserPreferences().themeMode == AppThemeMode.dark',
        () async {
      SharedPreferences.setMockInitialValues({'pref_theme_mode': 'dark'});
      final prefs = await makeRepo().getUserPreferences();
      expect(prefs.themeMode, AppThemeMode.dark);
    });

    test(
        '02 no stored value → getUserPreferences().themeMode == AppThemeMode.system',
        () async {
      final prefs = await makeRepo().getUserPreferences();
      expect(prefs.themeMode, AppThemeMode.system);
    });
  });
}
