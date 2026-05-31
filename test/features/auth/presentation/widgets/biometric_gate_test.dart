// R1(b) — Resume guard: BiometricLock notifier + BiometricGate widget.
//
// Notifier tests prove the lock only engages for a signed-in session and that
// the graceful fallback unlocks. Widget tests prove the lock overlay renders
// over the routed child when locked and disappears when not.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/core/constants/app_constants.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/biometric_repository.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/biometric_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/widgets/biometric_gate.dart';

class _FakeBiometricRepository implements BiometricRepository {
  _FakeBiometricRepository({required this.supported, required this.willPass});
  final bool supported;
  final bool willPass;
  int authCalls = 0;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> authenticate({required String reason}) async {
    authCalls++;
    return willPass;
  }
}

ProviderContainer _container({
  AuthUser? user,
  required _FakeBiometricRepository repo,
}) {
  final c = ProviderContainer(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(user)),
      biometricRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('BiometricLock notifier — R1(b)', () {
    test('01 locks on background when a session exists', () async {
      final repo = _FakeBiometricRepository(supported: true, willPass: true);
      final c = _container(
        user: const AuthUser(uid: 'u1', email: 'a@mail.kmutt.ac.th'),
        repo: repo,
      );
      await c.read(authStateProvider.future);

      c.read(biometricLockProvider.notifier).markBackgrounded();

      expect(c.read(biometricLockProvider), isTrue);
    });

    test('02 does NOT lock when signed out', () async {
      final repo = _FakeBiometricRepository(supported: true, willPass: true);
      final c = _container(user: null, repo: repo);
      await c.read(authStateProvider.future);

      c.read(biometricLockProvider.notifier).markBackgrounded();

      expect(c.read(biometricLockProvider), isFalse);
    });

    test('03 unlocks after a successful check', () async {
      final repo = _FakeBiometricRepository(supported: true, willPass: true);
      final c = _container(
        user: const AuthUser(uid: 'u1', email: 'a@mail.kmutt.ac.th'),
        repo: repo,
      );
      await c.read(authStateProvider.future);

      c.read(biometricLockProvider.notifier).markBackgrounded();
      await c.read(biometricLockProvider.notifier).authenticateAndUnlock();

      expect(c.read(biometricLockProvider), isFalse);
      expect(repo.authCalls, 1);
    });

    test('04 stays locked when the check fails', () async {
      final repo = _FakeBiometricRepository(supported: true, willPass: false);
      final c = _container(
        user: const AuthUser(uid: 'u1', email: 'a@mail.kmutt.ac.th'),
        repo: repo,
      );
      await c.read(authStateProvider.future);

      c.read(biometricLockProvider.notifier).markBackgrounded();
      await c.read(biometricLockProvider.notifier).authenticateAndUnlock();

      expect(c.read(biometricLockProvider), isTrue);
    });

    test('05 graceful fallback unlocks without prompting when unsupported',
        () async {
      final repo = _FakeBiometricRepository(supported: false, willPass: false);
      final c = _container(
        user: const AuthUser(uid: 'u1', email: 'a@mail.kmutt.ac.th'),
        repo: repo,
      );
      await c.read(authStateProvider.future);

      c.read(biometricLockProvider.notifier).markBackgrounded();
      await c.read(biometricLockProvider.notifier).authenticateAndUnlock();

      expect(c.read(biometricLockProvider), isFalse);
      expect(repo.authCalls, 0);
    });
  });

  group('BiometricGate widget — R1(b)', () {
    testWidgets('shows the lock overlay over the child when locked',
        (tester) async {
      final repo = _FakeBiometricRepository(supported: true, willPass: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            biometricRepositoryProvider.overrideWithValue(repo),
            biometricLockProvider.overrideWith(_AlwaysLocked.new),
          ],
          child: const MaterialApp(
            home: BiometricGate(child: Text('protected-content')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('protected-content'), findsOneWidget);
      expect(find.text(AppConstants.biometricUnlockLabel), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('renders only the child when unlocked', (tester) async {
      final repo = _FakeBiometricRepository(supported: true, willPass: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            biometricRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: BiometricGate(child: Text('protected-content')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('protected-content'), findsOneWidget);
      expect(find.text(AppConstants.biometricUnlockLabel), findsNothing);
    });
  });
}

class _AlwaysLocked extends BiometricLock {
  @override
  bool build() => true;
}
