import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preference_service.g.dart';

class PreferenceService {
  // Intentionally duplicated from datasource — core/ cannot import features/
  static const _kThemeMode = 'pref_theme_mode';
  static const _kLastViewedCategory = 'pref_last_viewed_category';

  static Future<PreferenceService> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferenceService._(prefs);
  }

  PreferenceService._(this._prefs);
  final SharedPreferences _prefs;

  String get themeMode => _prefs.getString(_kThemeMode) ?? 'system';
  String? get lastViewedCategory => _prefs.getString(_kLastViewedCategory);
}

@riverpod
PreferenceService preferenceService(PreferenceServiceRef ref) {
  throw UnimplementedError('preferenceServiceProvider must be overridden in main.dart');
}
