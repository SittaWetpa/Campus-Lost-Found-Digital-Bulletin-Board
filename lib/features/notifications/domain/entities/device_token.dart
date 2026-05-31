// Android and Web only — no iOS per CLAUDE.md
enum DevicePlatform { android, web }

class DeviceToken {
  final String token;
  final String userId;
  final DevicePlatform platform;
  final DateTime registeredAt;

  const DeviceToken({
    required this.token,
    required this.userId,
    required this.platform,
    required this.registeredAt,
  });
}
