import 'package:campus_lost_found/features/auth/data/datasources/biometric_local_datasource.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/biometric_repository.dart';

/// Android: backed by the Keystore via `local_auth`'s `BiometricPrompt`.
///
/// Web: `BiometricLocalDatasource` returns `false` from [isDeviceSupported] and
/// `true` from [authenticate], so the resume guard degrades to a normal
/// session. WebAuthn (navigator.credentials / passkeys) is the intended Web
/// equivalent and would replace the datasource's Web branch when implemented.
class BiometricRepositoryImpl implements BiometricRepository {
  final BiometricLocalDatasource _datasource;
  const BiometricRepositoryImpl(this._datasource);

  @override
  Future<bool> isDeviceSupported() => _datasource.canAuthenticate();

  @override
  Future<bool> authenticate({required String reason}) =>
      _datasource.authenticate(reason: reason);
}
