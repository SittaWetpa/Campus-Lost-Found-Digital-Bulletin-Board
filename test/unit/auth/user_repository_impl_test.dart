// WBS 0.2 — UserRepositoryImpl
//
// Verifies the repository delegates to the datasource and translates
// FirebaseException / generic exceptions into the project's ServerFailure,
// matching the layer rule that domain callers must only see Failure types.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:campus_lost_found/features/auth/data/models/user_model.dart';
import 'package:campus_lost_found/features/auth/data/repositories/user_repository_impl.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';

class _MockUserDatasource extends Mock implements UserRemoteDatasource {}

class _FakeUserModel extends Fake implements UserModel {}

const _entity = User(
  uid: 'uid-1',
  email: 'sitta@mail.kmutt.ac.th',
  firstName: 'Sitta',
  lastName: 'Wetpa',
  studentId: '67000000',
  telephone: '0812345678',
  emailVerified: false,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUserModel());
  });

  late _MockUserDatasource datasource;
  late UserRepositoryImpl sut;

  setUp(() {
    datasource = _MockUserDatasource();
    sut = UserRepositoryImpl(datasource);
  });

  group('UserRepositoryImpl — WBS 0.2', () {
    group('createUserProfile', () {
      test('01 forwards a UserModel built from the entity to datasource',
          () async {
        when(() => datasource.createUser(any())).thenAnswer((_) async {});

        await sut.createUserProfile(_entity);

        final captured =
            verify(() => datasource.createUser(captureAny())).captured.single
                as UserModel;
        expect(captured.uid, equals(_entity.uid));
        expect(captured.email, equals(_entity.email));
        expect(captured.firstName, equals(_entity.firstName));
        expect(captured.lastName, equals(_entity.lastName));
        expect(captured.studentId, equals(_entity.studentId));
        expect(captured.telephone, equals(_entity.telephone));
      });

      test('02 wraps FirebaseException as ServerFailure', () async {
        when(() => datasource.createUser(any())).thenThrow(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        );

        await expectLater(
          sut.createUserProfile(_entity),
          throwsA(isA<ServerFailure>()),
        );
      });

      test('03 wraps generic exceptions as ServerFailure', () async {
        when(() => datasource.createUser(any())).thenThrow(
          Exception('boom'),
        );

        await expectLater(
          sut.createUserProfile(_entity),
          throwsA(isA<ServerFailure>()),
        );
      });
    });

    group('updateUserProfile', () {
      test('04 forwards a UserModel built from the entity to datasource',
          () async {
        when(() => datasource.updateUser(any())).thenAnswer((_) async {});

        await sut.updateUserProfile(_entity);

        verify(() => datasource.updateUser(any())).called(1);
      });

      test('05 wraps FirebaseException as ServerFailure', () async {
        when(() => datasource.updateUser(any())).thenThrow(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        );

        await expectLater(
          sut.updateUserProfile(_entity),
          throwsA(isA<ServerFailure>()),
        );
      });
    });

    group('getUserById', () {
      test('06 maps the datasource UserModel back into a domain User',
          () async {
        when(() => datasource.getUserById('uid-1')).thenAnswer(
          (_) async => UserModel.fromEntity(_entity),
        );

        final result = await sut.getUserById('uid-1');

        expect(result, isNotNull);
        expect(result!.uid, equals(_entity.uid));
        expect(result.email, equals(_entity.email));
        expect(result.firstName, equals(_entity.firstName));
      });

      test('07 returns null when the datasource returns null', () async {
        when(() => datasource.getUserById('missing'))
            .thenAnswer((_) async => null);

        final result = await sut.getUserById('missing');

        expect(result, isNull);
      });
    });

    group('watchUser', () {
      test('08 maps the datasource stream to domain User entities', () async {
        when(() => datasource.watchUser('uid-1')).thenAnswer(
          (_) => Stream.value(UserModel.fromEntity(_entity)),
        );

        final first = await sut.watchUser('uid-1').first;

        expect(first, isNotNull);
        expect(first!.uid, equals(_entity.uid));
      });
    });
  });
}
