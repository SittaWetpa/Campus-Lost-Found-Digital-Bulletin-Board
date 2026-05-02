// WBS 0.1 — SignUp use case
//
// Covers the WBS 0.1 testing requirements that live in Dart:
//  * signUp with @mail.kmutt.ac.th — Firebase (auth + user repos) IS called
//  * signUp with @gmail.com / other domains — InvalidDomainFailure thrown
//    BEFORE any Firebase call is made
//
// The OTP-side WBS 0.1 cases (correct code, expired, locked-out) live in
// Cloud Functions (functions/index.js) and are out of scope for the Dart
// test suite — see test_scripts.md WBS 0.1 row.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/user_repository.dart';
import 'package:campus_lost_found/features/auth/domain/usecases/sign_up.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _FakeUser extends Fake implements User {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUser());
  });

  late _MockAuthRepository authRepo;
  late _MockUserRepository userRepo;
  late SignUp sut;

  const validEmail = 'someone@mail.kmutt.ac.th';
  const password = 'pass1234';
  const firstName = 'Sitta';
  const lastName = 'Wetpa';
  const studentId = '67000000';
  const telephone = '0812345678';

  setUp(() {
    authRepo = _MockAuthRepository();
    userRepo = _MockUserRepository();
    sut = SignUp(authRepo, userRepo);
  });

  group('SignUp — WBS 0.1', () {
    group('domain validation', () {
      test(
        '01 throws InvalidDomainFailure for @gmail.com',
        () async {
          await expectLater(
            sut.call(
              email: 'user@gmail.com',
              password: password,
              firstName: firstName,
              lastName: lastName,
              studentId: studentId,
              telephone: telephone,
            ),
            throwsA(isA<InvalidDomainFailure>()),
          );
        },
      );

      test(
        '02 throws InvalidDomainFailure for @student.kmutt.ac.th '
        '(KMUTT subdomain — not allowed)',
        () async {
          await expectLater(
            sut.call(
              email: 'user@student.kmutt.ac.th',
              password: password,
              firstName: firstName,
              lastName: lastName,
              studentId: studentId,
              telephone: telephone,
            ),
            throwsA(isA<InvalidDomainFailure>()),
          );
        },
      );

      test(
        '03 throws InvalidDomainFailure for empty email',
        () async {
          await expectLater(
            sut.call(
              email: '',
              password: password,
              firstName: firstName,
              lastName: lastName,
              studentId: studentId,
              telephone: telephone,
            ),
            throwsA(isA<InvalidDomainFailure>()),
          );
        },
      );

      test(
        '04 does NOT call Firebase when email domain is invalid',
        () async {
          try {
            await sut.call(
              email: 'user@gmail.com',
              password: password,
              firstName: firstName,
              lastName: lastName,
              studentId: studentId,
              telephone: telephone,
            );
            fail('Expected InvalidDomainFailure');
          } on InvalidDomainFailure {
            // expected
          }

          verifyNever(
            () => authRepo.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          );
          verifyNever(() => userRepo.createUserProfile(any()));
        },
      );
    });

    group('happy path', () {
      test(
        '05 calls authRepository.signUp with the provided email and password',
        () async {
          when(
            () => authRepo.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer(
            (_) async => const AuthUser(uid: 'uid-1', email: validEmail),
          );
          when(() => userRepo.createUserProfile(any()))
              .thenAnswer((_) async {});

          await sut.call(
            email: validEmail,
            password: password,
            firstName: firstName,
            lastName: lastName,
            studentId: studentId,
            telephone: telephone,
          );

          verify(
            () => authRepo.signUp(email: validEmail, password: password),
          ).called(1);
        },
      );

      test(
        '06 creates the user profile after auth sign-up with the auth uid '
        'and all registration fields',
        () async {
          when(
            () => authRepo.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer(
            (_) async => const AuthUser(uid: 'uid-1', email: validEmail),
          );
          when(() => userRepo.createUserProfile(any()))
              .thenAnswer((_) async {});

          await sut.call(
            email: validEmail,
            password: password,
            firstName: firstName,
            lastName: lastName,
            studentId: studentId,
            telephone: telephone,
          );

          final captured =
              verify(() => userRepo.createUserProfile(captureAny()))
                  .captured
                  .single as User;
          expect(captured.uid, equals('uid-1'));
          expect(captured.email, equals(validEmail));
          expect(captured.firstName, equals(firstName));
          expect(captured.lastName, equals(lastName));
          expect(captured.studentId, equals(studentId));
          expect(captured.telephone, equals(telephone));
          expect(
            captured.emailVerified,
            isFalse,
            reason: 'emailVerified must be false until OTP confirms',
          );
        },
      );

      test(
        '07 calls auth.signUp BEFORE user.createUserProfile',
        () async {
          final calls = <String>[];
          when(
            () => authRepo.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer((_) async {
            calls.add('auth');
            return const AuthUser(uid: 'uid-1', email: validEmail);
          });
          when(() => userRepo.createUserProfile(any())).thenAnswer((_) async {
            calls.add('user');
          });

          await sut.call(
            email: validEmail,
            password: password,
            firstName: firstName,
            lastName: lastName,
            studentId: studentId,
            telephone: telephone,
          );

          expect(calls, equals(['auth', 'user']));
        },
      );
    });
  });
}
