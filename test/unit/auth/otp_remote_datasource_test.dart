// WBS 0.1 — OTP remote datasource (Cloud Functions caller)
//
// In this codebase the OTP business logic (code matching, 10-minute expiry,
// the 5-attempt lock-out) lives in Cloud Functions (Node.js, see
// `functions/index.js`), NOT in Dart. The Dart layer is a thin caller that
// translates `FirebaseFunctionsException` into the project's `OtpFailure`.
//
// This file therefore covers only what Dart actually owns: the exception
// mapping and the call shape (function name + arguments). The four
// behavioural OTP cases listed in WBS 0.1 ("correct code returns true",
// "expired", "5 wrong attempts", "attempts ≥ 5") belong in a Cloud
// Functions test suite — flagged in test_scripts.md WBS 0.1.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/auth/data/datasources/otp_remote_datasource.dart';

class _MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class _MockHttpsCallable extends Mock implements HttpsCallable {}

class _MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<dynamic> {}

void main() {
  late _MockFirebaseFunctions functions;
  late _MockHttpsCallable callable;
  late _MockHttpsCallableResult result;
  late CloudFunctionOtpDatasource sut;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    functions = _MockFirebaseFunctions();
    callable = _MockHttpsCallable();
    result = _MockHttpsCallableResult();
    sut = CloudFunctionOtpDatasource(functions);
  });

  group('CloudFunctionOtpDatasource — WBS 0.1', () {
    group('sendOtp()', () {
      test(
        '01 invokes the "sendOtp" callable with no arguments',
        () async {
          when(() => functions.httpsCallable('sendOtp')).thenReturn(callable);
          when(() => callable.call()).thenAnswer((_) async => result);

          await sut.sendOtp();

          verify(() => functions.httpsCallable('sendOtp')).called(1);
          verify(() => callable.call()).called(1);
        },
      );

      test(
        '02 wraps FirebaseFunctionsException as OtpFailure with the '
        'function-side message',
        () async {
          when(() => functions.httpsCallable('sendOtp')).thenReturn(callable);
          when(() => callable.call()).thenThrow(
            FirebaseFunctionsException(
              message: 'OTP throttled — wait 1 minute.',
              code: 'resource-exhausted',
            ),
          );

          await expectLater(
            sut.sendOtp(),
            throwsA(
              isA<OtpFailure>().having(
                (f) => f.message,
                'message',
                'OTP throttled — wait 1 minute.',
              ),
            ),
          );
        },
      );

    });

    group('verifyOtp()', () {
      test(
        '04 invokes the "verifyOtp" callable with {code: <input>}',
        () async {
          when(() => functions.httpsCallable('verifyOtp')).thenReturn(callable);
          when(() => callable.call(any())).thenAnswer((_) async => result);

          await sut.verifyOtp('123456');

          final captured =
              verify(() => callable.call(captureAny())).captured.single
                  as Map<String, dynamic>;
          expect(captured, equals({'code': '123456'}));
        },
      );

      test(
        '05 wraps FirebaseFunctionsException as OtpFailure with the '
        'function-side message (e.g. invalid code, expired, locked)',
        () async {
          when(() => functions.httpsCallable('verifyOtp')).thenReturn(callable);
          when(() => callable.call(any())).thenThrow(
            FirebaseFunctionsException(
              message: 'Too many wrong attempts. Try again later.',
              code: 'permission-denied',
            ),
          );

          await expectLater(
            sut.verifyOtp('000000'),
            throwsA(
              isA<OtpFailure>().having(
                (f) => f.message,
                'message',
                'Too many wrong attempts. Try again later.',
              ),
            ),
          );
        },
      );

    });
  });
}
