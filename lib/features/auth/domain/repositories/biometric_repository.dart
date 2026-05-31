/// R1(b) — Biometric / device-credential gate for resuming an existing session.
///
/// Pure-domain abstraction. The data-layer implementation wraps `local_auth`
/// (Android Keystore-backed) on mobile and is a Web-safe no-op on Web, where
/// WebAuthn is the intended equivalent (see `biometric_repository_impl.dart`).
abstract interface class BiometricRepository {
  /// Whether the device can perform a biometric or device-credential check.
  ///
  /// Returns `false` on Web and on devices with no enrolled biometrics or
  /// device credential — callers treat that as "fall back to a normal session".
  Future<bool> isDeviceSupported();

  /// Prompts the OS for a biometric (or device-credential) check.
  ///
  /// Returns `true` only when the user authenticates successfully.
  Future<bool> authenticate({required String reason});
}
