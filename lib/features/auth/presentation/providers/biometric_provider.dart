import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:campus_lost_found/core/constants/app_constants.dart';
import 'package:campus_lost_found/features/auth/data/datasources/biometric_local_datasource.dart';
import 'package:campus_lost_found/features/auth/data/repositories/biometric_repository_impl.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/biometric_repository.dart';
import 'package:campus_lost_found/features/auth/domain/usecases/authenticate_on_resume.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';

part 'biometric_provider.g.dart';

@riverpod
BiometricLocalDatasource biometricDatasource(BiometricDatasourceRef ref) {
  return BiometricLocalDatasource(LocalAuthentication());
}

@riverpod
BiometricRepository biometricRepository(BiometricRepositoryRef ref) {
  return BiometricRepositoryImpl(ref.watch(biometricDatasourceProvider));
}

/// Lock state for the R1(b) resume guard. `true` means the app is locked and a
/// biometric / device-credential check is required before the UI is shown.
@riverpod
class BiometricLock extends _$BiometricLock {
  @override
  bool build() => false;

  /// Called when the app is backgrounded. Locks **only** if a Firebase session
  /// exists, so a signed-out user is never prompted. No-op on Web.
  void markBackgrounded() {
    if (kIsWeb) return;
    if (ref.read(authStateProvider).valueOrNull != null) {
      state = true;
    }
  }

  /// Called on resume. Runs the biometric check and unlocks on success.
  /// Graceful fallback (no biometrics enrolled) resolves to unlock inside the
  /// [AuthenticateOnResume] use case.
  Future<void> authenticateAndUnlock() async {
    if (!state) return;
    final ok = await AuthenticateOnResume(ref.read(biometricRepositoryProvider))
        .call(reason: AppConstants.biometricReason);
    if (ok) state = false;
  }
}
