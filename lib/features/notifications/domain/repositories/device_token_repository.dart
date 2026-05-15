import 'package:campus_lost_found/features/notifications/domain/entities/device_token.dart';

abstract interface class DeviceTokenRepository {
  /// Registers (or re-registers) a token. Safe to call on every app launch —
  /// the data layer must use Firestore arrayUnion for idempotency.
  Future<void> registerToken(DeviceToken token);

  /// Removes a single token. Call on logout or when FCM reports the token stale.
  Future<void> removeToken({required String userId, required String token});

  /// Removes all tokens for [userId]. Call on account deletion.
  Future<void> removeAllTokens(String userId);
}
