class UserPreferences {
  final bool notificationsEnabled;

  const UserPreferences({
    required this.notificationsEnabled,
  });

  UserPreferences copyWith({bool? notificationsEnabled}) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
