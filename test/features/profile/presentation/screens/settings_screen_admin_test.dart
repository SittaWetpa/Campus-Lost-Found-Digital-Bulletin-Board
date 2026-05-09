// WBS 2.18 — Settings screen Developer section gating

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/profile/domain/entities/user_preferences.dart';
import 'package:campus_lost_found/features/profile/domain/repositories/preference_repository.dart';
import 'package:campus_lost_found/features/profile/presentation/providers/profile_provider.dart';
import 'package:campus_lost_found/features/profile/presentation/screens/settings_screen.dart';

const _adminUser = User(
  uid: 'uid-admin',
  email: 'lead@mail.kmutt.ac.th',
  firstName: 'Lead',
  lastName: 'Admin',
  studentId: '6713050099',
  telephone: '0800000099',
  emailVerified: true,
  isAdmin: true,
);

const _regularUser = User(
  uid: 'uid-regular',
  email: 'student@mail.kmutt.ac.th',
  firstName: 'Reg',
  lastName: 'User',
  studentId: '6713050001',
  telephone: '0812345678',
  emailVerified: true,
);

const _defaultPrefs = UserPreferences(notificationsEnabled: true);

class _FakeAuthRepository implements AuthRepository {
  final String _uid;
  final String _email;
  _FakeAuthRepository(this._uid, this._email);

  @override
  Stream<AuthUser?> get authStateChanges =>
      Stream.value(AuthUser(uid: _uid, email: _email));

  @override
  Future<AuthUser> signIn(
          {required String email, required String password}) async =>
      AuthUser(uid: _uid, email: email);

  @override
  Future<AuthUser> signUp(
          {required String email, required String password}) async =>
      AuthUser(uid: _uid, email: email);

  @override
  Future<void> signOut() async {}
}

class _FakePreferenceRepository implements PreferenceRepository {
  @override
  Future<UserPreferences> getUserPreferences() async => _defaultPrefs;

  @override
  Future<void> setNotificationsEnabled({required bool value}) async {}
}

Widget _buildScreen(User user) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((_) => Stream.value(user)),
      userPreferencesProvider.overrideWith((_) async => _defaultPrefs),
      preferenceRepositoryProvider
          .overrideWith((_) => _FakePreferenceRepository()),
      authRepositoryProvider
          .overrideWith((_) => _FakeAuthRepository(user.uid, user.email)),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

void main() {
  group('SettingsScreen — WBS 2.18 Developer section gating', () {
    testWidgets(
      'WBS 2.18-01 — non-admin user does NOT see the Developer section',
      (tester) async {
        await tester.pumpWidget(_buildScreen(_regularUser));
        await tester.pumpAndSettle();

        expect(find.text('DEVELOPER'), findsNothing);
        expect(find.text('Remote Config'), findsNothing);
        expect(find.text('Rollback Plan'), findsNothing);
      },
    );

    testWidgets(
      'WBS 2.18-02 — admin user sees the Developer section with both rows',
      (tester) async {
        await tester.pumpWidget(_buildScreen(_adminUser));
        await tester.pumpAndSettle();

        expect(find.text('DEVELOPER'), findsOneWidget);
        expect(find.text('Remote Config'), findsOneWidget);
        expect(find.text('Rollback Plan'), findsOneWidget);
      },
    );
  });
}
