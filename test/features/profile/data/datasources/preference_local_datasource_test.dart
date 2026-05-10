// WBS 2.5 — Datasource unit tests (SharedPreferences raw-string operations)
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_lost_found/features/profile/data/datasources/preference_local_datasource.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SharedPreferencesDatasource — WBS 2.5', () {
    test('01 setThemeMode/getThemeMode round-trip', () async {
      final ds = SharedPreferencesDatasource();
      await ds.setThemeMode('dark');
      expect(await ds.getThemeMode(), 'dark');
    });

    test('02 getThemeMode returns null on fresh install', () async {
      final ds = SharedPreferencesDatasource();
      expect(await ds.getThemeMode(), isNull);
    });

    test('03 setLastViewedCategory(null) removes the key', () async {
      final ds = SharedPreferencesDatasource();
      await ds.setLastViewedCategory('lost');
      await ds.setLastViewedCategory(null);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('pref_last_viewed_category'), isFalse);
    });

    test('04 setLastViewedCategory/getLastViewedCategory round-trip', () async {
      final ds = SharedPreferencesDatasource();
      await ds.setLastViewedCategory('lost');
      expect(await ds.getLastViewedCategory(), 'lost');
    });
  });
}
