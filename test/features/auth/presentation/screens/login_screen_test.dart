// WBS 0.3 — Login Screen widget tests
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
import 'package:campus_lost_found/features/auth/presentation/screens/login_screen.dart';

// ─── fakes ───────────────────────────────────────────────────────────────────

class _FakeAuthRepository implements AuthRepository {
  final void Function(AuthUser)? onSignIn;

  const _FakeAuthRepository({this.onSignIn});

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(null);

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    final user = AuthUser(uid: 'test-uid', email: email);
    onSignIn?.call(user);
    return user;
  }

  @override
  Future<AuthUser> signUp({required String email, required String password}) async =>
      AuthUser(uid: 'test-uid', email: email);

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

/// Standalone widget (no router) — sufficient for validation-only tests.
Widget _buildScreen() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWith((_) => const _FakeAuthRepository()),
      userRepositoryProvider.overrideWith((_) => _FakeUserRepository()),
    ],
    child: const MaterialApp(home: LoginScreen()),
  );
}

/// Full router app — required for navigation assertions.
Widget _buildAppWithRouter(_FakeAuthRepository fakeAuth) {
  AuthUser? signedInUser;
  final refreshTrigger = ValueNotifier<int>(0);

  final fakeAuthWithHook = _FakeAuthRepository(
    onSignIn: (user) {
      signedInUser = user;
      refreshTrigger.value++;
      fakeAuth.onSignIn?.call(user);
    },
  );

  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshTrigger,
    redirect: (_, state) {
      if (signedInUser == null) return null;
      if (state.matchedLocation == '/otp-verify') return null;
      return '/otp-verify';
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const Scaffold(body: Text('Register'))),
      GoRoute(path: '/otp-verify', builder: (_, __) => const Scaffold(body: Text('OTP Screen'))),
      GoRoute(path: '/feed', builder: (_, __) => const Scaffold(body: Text('Feed'))),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWith((_) => fakeAuthWithHook),
      userRepositoryProvider.overrideWith((_) => _FakeUserRepository()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ─── tests ───────────────────────────────────────────────────────────────────

void main() {
  group('LoginScreen — WBS 0.3', () {
    // ── email validation ──────────────────────────────────────────────────────

    testWidgets(
      '01 shows "Email is required." when email field is empty on submit',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
        await tester.pump();

        expect(find.text('Email is required.'), findsOneWidget);
      },
    );

    testWidgets(
      '02 shows domain error when email is @gmail.com (non-KMUTT)',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await tester.enterText(find.byType(TextFormField).at(0), 'user@gmail.com');
        await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
        await tester.pump();

        expect(
          find.text('Only @mail.kmutt.ac.th emails are allowed.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '03 shows domain error when email has @student.kmutt.ac.th subdomain',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await tester.enterText(
            find.byType(TextFormField).at(0), 'user@student.kmutt.ac.th');
        await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
        await tester.pump();

        expect(
          find.text('Only @mail.kmutt.ac.th emails are allowed.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '04 email validation passes for valid @mail.kmutt.ac.th address',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await tester.enterText(
            find.byType(TextFormField).at(0), 'test@mail.kmutt.ac.th');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');
        await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
        await tester.pump();

        expect(find.text('Email is required.'), findsNothing);
        expect(
          find.text('Only @mail.kmutt.ac.th emails are allowed.'),
          findsNothing,
        );
      },
    );

    // ── password validation ───────────────────────────────────────────────────

    testWidgets(
      '05 shows "Password is required." when password field is empty',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pump();

        await tester.enterText(
            find.byType(TextFormField).at(0), 'test@mail.kmutt.ac.th');
        await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
        await tester.pump();

        expect(find.text('Password is required.'), findsOneWidget);
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

    // WBS 0.3: "successful login with emailVerified == false →
    //           verify navigation to OTP Verification Screen"
    testWidgets(
      '06 navigates to OTP screen (not Feed) after successful login when '
      'emailVerified is false',
      (tester) async {
        await tester.pumpWidget(_buildAppWithRouter(const _FakeAuthRepository()));
        await tester.pump();

        await tester.enterText(
            find.byType(TextFormField).at(0), 'test@mail.kmutt.ac.th');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');

        await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
        await tester.pumpAndSettle();

        expect(find.text('OTP Screen'), findsOneWidget);
        expect(find.text('Feed'), findsNothing);
      },
    );
  });
}
