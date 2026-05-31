// WBS 2.5 — PreferenceService unit tests (startup loader)
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_lost_found/core/services/preference_service.dart';

void main() {
  group('PreferenceService — WBS 2.5', () {
    test('01 themeMode returns stored value', () async {
      SharedPreferences.setMockInitialValues({'pref_theme_mode': 'light'});
      final service = await PreferenceService.load();
      expect(service.themeMode, 'light');
    });

    test('02 missing key → themeMode defaults to "system"', () async {
      SharedPreferences.setMockInitialValues({});
      final service = await PreferenceService.load();
      expect(service.themeMode, 'system');
    });
  });
}
