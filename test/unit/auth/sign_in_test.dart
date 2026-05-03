// WBS 0.1 — SignIn use case
//
// Covers the WBS 0.1 testing requirement: signIn with a non-KMUTT email
// must throw InvalidDomainFailure before any Firebase Auth call is made.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_lost_found/features/auth/domain/usecases/sign_in.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository authRepo;
  late SignIn sut;

  const validEmail = 'someone@mail.kmutt.ac.th';
  const password = 'pass1234';

  setUp(() {
    authRepo = _MockAuthRepository();
    sut = SignIn(authRepo);
  });

  group('SignIn — WBS 0.1', () {
    test(
      '01 throws InvalidDomainFailure for @gmail.com',
      () {
        // SignIn.call is not async, so the validation throw is synchronous —
        // wrap in a closure for `throwsA` to catch it.
        expect(
          () => sut.call(email: 'user@gmail.com', password: password),
          throwsA(isA<InvalidDomainFailure>()),
        );
      },
    );

    test(
      '02 throws InvalidDomainFailure for @student.kmutt.ac.th',
      () {
        expect(
          () => sut.call(email: 'user@student.kmutt.ac.th', password: password),
          throwsA(isA<InvalidDomainFailure>()),
        );
      },
    );

    test(
      '03 does NOT call authRepository.signIn when domain is invalid',
      () {
        expect(
          () => sut.call(email: 'user@gmail.com', password: password),
          throwsA(isA<InvalidDomainFailure>()),
        );

        verifyNever(
          () => authRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    test(
      '04 delegates to authRepository.signIn for a valid KMUTT email',
      () async {
        when(
          () => authRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => const AuthUser(uid: 'uid-1', email: validEmail),
        );

        final result = await sut.call(email: validEmail, password: password);

        verify(
          () => authRepo.signIn(email: validEmail, password: password),
        ).called(1);
        expect(result.uid, equals('uid-1'));
        expect(result.email, equals(validEmail));
      },
    );
  });
}
