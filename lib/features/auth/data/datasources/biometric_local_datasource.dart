import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:local_auth/local_auth.dart';

/// Thin wrapper over `local_auth`. On Android this uses the Keystore-backed
/// `BiometricPrompt`; on Web it is a no-op (WebAuthn is the intended Web
/// equivalent — see [BiometricRepositoryImpl]).
class BiometricLocalDatasource {
  final LocalAuthentication _localAuth;
  const BiometricLocalDatasource(this._localAuth);

  /// `true` when the device can run a biometric OR device-credential check.
  Future<bool> canAuthenticate() async {
    if (kIsWeb) return false;
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      return isSupported || canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Shows the OS prompt. `biometricOnly: false` lets the user fall back to the
  /// device PIN/pattern; `stickyAuth` survives the app being briefly paused by
  /// the system biometric dialog.
  Future<bool> authenticate({required String reason}) async {
    if (kIsWeb) return true;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
