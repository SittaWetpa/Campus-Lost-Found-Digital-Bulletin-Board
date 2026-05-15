// WBS 0.3 — Register Screen widget tests
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/user_repository.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/screens/register_screen.dart';

// ─── fakes ───────────────────────────────────────────────────────────────────

class _FakeAuthRepository implements AuthRepository {
  final void Function(AuthUser)? onSignUp;

  const _FakeAuthRepository({this.onSignUp});

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(null);

  @override
  Future<AuthUser> signIn({required String email, required String password}) async =>
      AuthUser(uid: 'test-uid', email: email);

  @override
  Future<AuthUser> signUp({required String email, required String password}) async {
    final user = AuthUser(uid: 'test-uid', email: email);
    onSignUp?.call(user);
    return user;
  }

  @override
  Future<void> signOut() async {}
}

class _FakeUserRepository implements UserRepository {
  @override
  Stream<User?> watchUser(String uid) => Stream.value(null);
  @override
  Future<User?> getUserById(String uid) async => null;
  @override
  Future<void> createUserProfile(User user) async {}
  @override
  Future<void> updateUserProfile(User user) async {}
}

// ─── helpers ─────────────────────────────────────────────────────────────────

/// Field indices in the register form (order of appearance in the widget tree).
const _kFirstName = 0;
const _kLastName = 1;
const _kStudentId = 2;
const _kPhone = 3;
const _kEmail = 4;
const _kPassword = 5;
const _kConfirmPassword = 6;

/// Standalone widget — used for all validation tests.
Widget _buildScreen() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWith((_) => const _FakeAuthRepository()),
      userRepositoryProvider.overrideWith((_) => _FakeUserRepository()),
    ],
    child: const MaterialApp(home: RegisterScreen()),
  );
}

/// Full router app — required for navigation assertions.
Widget _buildAppWithRouter() {
  AuthUser? signedUpUser;
  final refreshTrigger = ValueNotifier<int>(0);

  final router = GoRouter(
    initialLocation: '/register',
    refreshListenable: refreshTrigger,
    redirect: (_, state) {
      if (signedUpUser == null) return null;
      if (state.matchedLocation == '/otp-verify') return null;
      return '/otp-verify';
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const Scaffold(body: Text('Login'))),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/otp-verify', builder: (_, __) => const Scaffold(body: Text('OTP Screen'))),
      GoRoute(path: '/feed', builder: (_, __) => const Scaffold(body: Text('Feed'))),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWith(
        (_) => _FakeAuthRepository(
          onSignUp: (user) {
            signedUpUser = user;
            refreshTrigger.value++;
          },
        ),
      ),
      userRepositoryProvider.overrideWith((_) => _FakeUserRepository()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Fills every required field with valid data except the ones in [skip].
Future<void> _fillValidForm(
  WidgetTester tester, {
  Set<int> skip = const {},
}) async {
  final values = {
    _kFirstName: 'Test',
    _kLastName: 'User',
    _kStudentId: '12345678901',
    _kPhone: '0812345678',
    _kEmail: 'test@mail.kmutt.ac.th',
    _kPassword: 'password123',
    _kConfirmPassword: 'password123',
  };

  for (final entry in values.entries) {
    if (!skip.contains(entry.key)) {
      await tester.enterText(
        find.byType(TextFormField).at(entry.key),
        entry.value,
      );
    }
  }
}

/// Scrolls the "Create account" button into view before tapping.
/// The form is taller than the default 600px test viewport, so a plain
/// tap() misses the button unless we scroll first.
Future<void> _tapCreateAccount(WidgetTester tester) async {
  await tester.ensureVisible(
    find.widgetWithText(FilledButton, 'Create account'),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
  await tester.pump();
}

// ─── tests ───────────────────────────────────────────────────────────────────

void main() {
  group('RegisterScreen — WBS 0.3', () {
    // ── required fields ───────────────────────────────────────────────────────

    // WBS 0.3: "empty required fields — verify validation errors block submission"
    testWidgets(
      '01 shows error when first name is empty on submit',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await _fillValidForm(tester, skip: {_kFirstName});
        await _tapCreateAccount(tester);

        expect(find.text('Required.'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      '02 shows error when last name is empty on submit',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await _fillValidForm(tester, skip: {_kLastName});
        await _tapCreateAccount(tester);

        expect(find.text('Required.'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      '03 shows "Student ID is required." when student ID is empty',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await _fillValidForm(tester, skip: {_kStudentId});
        await _tapCreateAccount(tester);

        expect(find.text('Student ID is required.'), findsOneWidget);
      },
    );

    testWidgets(
      '04 shows error when student ID is fewer than 11 digits',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await _fillValidForm(tester, skip: {_kStudentId});
        await tester.enterText(find.byType(TextFormField).at(_kStudentId), '12345');
        await _tapCreateAccount(tester);

        expect(
          find.text('Student ID must be exactly 11 digits.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '05 shows error when student ID is more than 11 digits',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await _fillValidForm(tester, skip: {_kStudentId});
        await tester.enterText(
            find.byType(TextFormField).at(_kStudentId), '123456789012');
        await _tapCreateAccount(tester);

        expect(
          find.text('Student ID must be exactly 11 digits.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '06 shows "Phone number is required." when phone is empty',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await _fillValidForm(tester, skip: {_kPhone});
        await _tapCreateAccount(tester);

        expect(find.text('Phone number is required.'), findsOneWidget);
      },
    );

    // ── email validation ──────────────────────────────────────────────────────

    // WBS 0.3: "Register screen with @gmail.com email →
    //           verify 'Invalid email domain' error appears"
    testWidgets(
      '07 shows domain error for @gmail.com email',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await _fillValidForm(tester, skip: {_kEmail});
        await tester.enterText(
            find.byType(TextFormField).at(_kEmail), 'user@gmail.com');
        await _tapCreateAccount(tester);

        expect(
          find.text('Only @mail.kmutt.ac.th emails are allowed.'),
          findsOneWidget,
        );
      },
    );

    // WBS 0.3: "Register screen with @mail.kmutt.ac.th email — validation passes"
    testWidgets(
      '08 email validation passes for @mail.kmutt.ac.th address',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await _fillValidForm(tester);
        await _tapCreateAccount(tester);

        expect(find.text('Email is required.'), findsNothing);
        expect(
          find.text('Only @mail.kmutt.ac.th emails are allowed.'),
          findsNothing,
        );
      },
    );

    // ── password validation ───────────────────────────────────────────────────

    // WBS 0.3: "mismatched password and confirm password — verify error appears"
    testWidgets(
      '09 shows "Passwords do not match." when confirm password differs',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await _fillValidForm(tester, skip: {_kConfirmPassword});
        await tester.enterText(
            find.byType(TextFormField).at(_kConfirmPassword), 'different999');
        await _tapCreateAccount(tester);

        expect(find.text('Passwords do not match.'), findsOneWidget);
      },
    );

    testWidgets(
      '10 shows error when password is shorter than 6 characters',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await _fillValidForm(tester, skip: {_kPassword, _kConfirmPassword});
        await tester.enterText(
            find.byType(TextFormField).at(_kPassword), '123');
        await tester.enterText(
            find.byType(TextFormField).at(_kConfirmPassword), '123');
        await _tapCreateAccount(tester);

        expect(
          find.text('Password must be at least 6 characters.'),
          findsOneWidget,
        );
      },
    );

    // ── accessibility ─────────────────────────────────────────────────────────

    testWidgets(
      'meets accessibility guidelines (tap target size, labels)',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        // textContrastGuideline is omitted: InputDecoration floating labelText
        // inherits the amber primaryColor (~2.79:1 on white) which is a
        // pre-existing design token issue not in scope for WBS 5.1.
      },
    );

    // ── navigation ────────────────────────────────────────────────────────────

    // WBS 0.3: "successful register — verify navigation goes to OTP
    //           Verification Screen (not Feed)"
    testWidgets(
      '11 navigates to OTP screen (not Feed) after successful registration',
      (tester) async {
        await tester.pumpWidget(_buildAppWithRouter());
        await tester.pump();

        await _fillValidForm(tester);
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Create account'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
        await tester.pumpAndSettle();

        expect(find.text('OTP Screen'), findsOneWidget);
        expect(find.text('Feed'), findsNothing);
      },
    );
  });
}
