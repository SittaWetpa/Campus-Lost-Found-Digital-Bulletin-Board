const _sentinel = Object();

enum AppThemeMode { system, light, dark }

class UserPreferences {
  final bool notificationsEnabled;
  final AppThemeMode themeMode;
  final String? lastViewedCategory;

  const UserPreferences({
    required this.notificationsEnabled,
    this.themeMode = AppThemeMode.system,
    this.lastViewedCategory,
  });

  UserPreferences copyWith({
    bool? notificationsEnabled,
    AppThemeMode? themeMode,
    Object? lastViewedCategory = _sentinel,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      lastViewedCategory: lastViewedCategory == _sentinel
          ? this.lastViewedCategory
          : lastViewedCategory as String?,
    );
  }
}
