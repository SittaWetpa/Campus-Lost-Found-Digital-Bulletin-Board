import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/app.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/otp_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_lost_found/features/auth/presentation/screens/otp_verify_screen.dart';

// Stub that prevents OtpVerifyScreen's auto-send from hitting Cloud Functions.
class _FakeOtpNotifier extends OtpNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<void> sendOtp() async {}

  @override
  Future<void> verifyOtp(String code) async {}
}

const _authUser = AuthUser(uid: 'u1', email: 'test@mail.kmutt.ac.th');

final _verifiedUser = User(
  uid: 'u1',
  email: 'test@mail.kmutt.ac.th',
  firstName: 'Test',
  lastName: 'User',
  studentId: '64000000',
  telephone: '0812345678',
  emailVerified: true,
  createdAt: DateTime(2025),
);

final _unverifiedUser = User(
  uid: 'u1',
  email: 'test@mail.kmutt.ac.th',
  firstName: 'Test',
  lastName: 'User',
  studentId: '64000000',
  telephone: '0812345678',
  emailVerified: false,
  createdAt: DateTime(2025),
);

void main() {
  group('Router redirect guards', () {
    testWidgets('unauthenticated user is redirected to /login', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            currentUserProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const CampusLostFoundApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('verified user is redirected from /login to /feed',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_authUser)),
            currentUserProvider
                .overrideWith((ref) => Stream.value(_verifiedUser)),
          ],
          child: const CampusLostFoundApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Feed — WBS 1.2'), findsOneWidget);
    });

    testWidgets('unverified user is redirected to /otp-verify', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_authUser)),
            currentUserProvider
                .overrideWith((ref) => Stream.value(_unverifiedUser)),
            otpNotifierProvider.overrideWith(_FakeOtpNotifier.new),
          ],
          child: const CampusLostFoundApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OtpVerifyScreen), findsOneWidget);
    });
  });
}
