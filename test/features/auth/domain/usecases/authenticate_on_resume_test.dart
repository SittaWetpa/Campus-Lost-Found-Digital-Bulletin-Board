// R1(b) — AuthenticateOnResume use case.
//
// Verifies the graceful-fallback business rule: a device with no biometric /
// device-credential capability resumes without a prompt, while a capable
// device must pass the OS check.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:campus_lost_found/features/auth/domain/repositories/biometric_repository.dart';
import 'package:campus_lost_found/features/auth/domain/usecases/authenticate_on_resume.dart';

class _MockBiometricRepository extends Mock implements BiometricRepository {}

void main() {
  late _MockBiometricRepository repo;
  late AuthenticateOnResume sut;

  setUp(() {
    repo = _MockBiometricRepository();
    sut = AuthenticateOnResume(repo);
  });

  group('AuthenticateOnResume — R1(b)', () {
    test('01 falls back to a normal session when no biometrics are available',
        () async {
      when(() => repo.isDeviceSupported()).thenAnswer((_) async => false);

      final result = await sut.call(reason: 'unlock');

      expect(result, isTrue);
      verifyNever(() => repo.authenticate(reason: any(named: 'reason')));
    });

    test('02 returns true when the device check succeeds', () async {
      when(() => repo.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => repo.authenticate(reason: any(named: 'reason')))
          .thenAnswer((_) async => true);

      final result = await sut.call(reason: 'unlock');

      expect(result, isTrue);
      verify(() => repo.authenticate(reason: 'unlock')).called(1);
    });

    test('03 returns false when the device check fails or is cancelled',
        () async {
      when(() => repo.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => repo.authenticate(reason: any(named: 'reason')))
          .thenAnswer((_) async => false);

      final result = await sut.call(reason: 'unlock');

      expect(result, isFalse);
    });
  });
}
