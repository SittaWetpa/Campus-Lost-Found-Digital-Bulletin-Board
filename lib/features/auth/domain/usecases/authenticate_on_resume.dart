import 'package:campus_lost_found/features/auth/domain/repositories/biometric_repository.dart';

/// R1(b) — Decides whether the app may resume into an authenticated session.
///
/// Business rule: if the device has no biometric / device-credential capability
/// we **gracefully fall back** to the normal session (return `true`). Otherwise
/// the user must pass the OS biometric check before resuming.
class AuthenticateOnResume {
  final BiometricRepository _repository;
  const AuthenticateOnResume(this._repository);

  Future<bool> call({required String reason}) async {
    if (!await _repository.isDeviceSupported()) return true;
    return _repository.authenticate(reason: reason);
  }
}
