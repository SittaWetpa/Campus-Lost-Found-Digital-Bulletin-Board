// WBS 0.5 — OTP Verification Screen widget tests
//
// Pins down the email-masking behaviour of [OtpVerifyScreen]. The screen
// previously read FirebaseAuth.instance directly inside build(), which
// crashed widget tests. After the fix the masked email is derived from
// `authStateProvider`, so these tests exercise the full pump path without
// touching Firebase.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/otp_provider.dart';
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

Widget _buildScreen(AuthUser? user) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(user)),
      otpNotifierProvider.overrideWith(_FakeOtpNotifier.new),
    ],
    child: const MaterialApp(home: OtpVerifyScreen()),
  );
}

void main() {
  group('OtpVerifyScreen — WBS 0.5', () {
    testWidgets(
      '01 masks the local part of a normal email',
      (tester) async {
        await tester.pumpWidget(
          _buildScreen(
            const AuthUser(uid: 'u1', email: 'sittawetpa@mail.kmutt.ac.th'),
          ),
        );
        await tester.pump();

        expect(find.text('s***@mail.kmutt.ac.th'), findsOneWidget);
        expect(find.text('We sent a 6-digit code to'), findsOneWidget);
      },
    );

    testWidgets(
      '02 renders without crash when authStateProvider has no user',
      (tester) async {
        await tester.pumpWidget(_buildScreen(null));
        await tester.pump();

        // The "We sent..." line still renders; the masked-email line is
        // empty (the screen does not throw).
        expect(find.text('We sent a 6-digit code to'), findsOneWidget);
        expect(find.byType(OtpVerifyScreen), findsOneWidget);
      },
    );

    testWidgets(
      '03 masks single-character local part',
      (tester) async {
        await tester.pumpWidget(
          _buildScreen(const AuthUser(uid: 'u1', email: 'a@x')),
        );
        await tester.pump();

        expect(find.text('a***@x'), findsOneWidget);
      },
    );

    testWidgets(
      '04 leaves email unmasked when "@" is the first character',
      (tester) async {
        await tester.pumpWidget(
          _buildScreen(const AuthUser(uid: 'u1', email: '@bad')),
        );
        await tester.pump();

        expect(find.text('@bad'), findsOneWidget);
      },
    );

    // Accessibility — tap-target size and labelled targets. Text-contrast
    // guideline is intentionally omitted: the screen has pre-existing
    // grey-on-white styling (timer + "Didn't get a code?") that fails
    // contrast and is out of scope for the WBS 0.5 testability fix.
    testWidgets(
      '05 meets accessibility guidelines (tap target size, labels)',
      (tester) async {
        await tester.pumpWidget(
          _buildScreen(
            const AuthUser(uid: 'u1', email: 'test@mail.kmutt.ac.th'),
          ),
        );
        await tester.pump();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      },
    );
  });
}
