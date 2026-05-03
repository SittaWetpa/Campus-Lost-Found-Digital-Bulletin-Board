// WBS 0.2 — Firestore user-profile datasource
//
// Covers the WBS 0.2 testing requirements that live in Dart:
//  * createUser writes to `users/{uid}` with all required profile fields
//  * createUser uses `FieldValue.serverTimestamp()` for `createdAt`
//  * getUserById returns a UserModel with all expected profile fields
//  * createUser stamps `emailVerified: false` so a freshly-registered user
//    must pass OTP before the route guard lets them past /otp-verify
//
// Cross-user access denial is enforced by Firestore Security Rules and is
// covered by `test/firestore_rules/rules.test.js`, not Dart.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:campus_lost_found/features/auth/data/models/user_model.dart';

UserModel _buildModel({
  String uid = 'uid-1',
  String email = 'sitta@mail.kmutt.ac.th',
  String firstName = 'Sitta',
  String lastName = 'Wetpa',
  String studentId = '67000000',
  String telephone = '0812345678',
  String? avatarUrl,
  bool emailVerified = false,
  DateTime? createdAt,
}) =>
    UserModel(
      uid: uid,
      email: email,
      firstName: firstName,
      lastName: lastName,
      studentId: studentId,
      telephone: telephone,
      avatarUrl: avatarUrl,
      emailVerified: emailVerified,
      createdAt: createdAt,
    );

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreUserDatasource sut;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    sut = FirestoreUserDatasource(firestore);
  });

  group('FirestoreUserDatasource — WBS 0.2', () {
    group('01 createUser()', () {
      test('writes to users/{uid} with all required profile fields',
          () async {
        await sut.createUser(_buildModel());

        final doc = await firestore.collection('users').doc('uid-1').get();
        expect(doc.exists, isTrue);
        final data = doc.data()!;
        expect(data['email'], equals('sitta@mail.kmutt.ac.th'));
        expect(data['firstName'], equals('Sitta'));
        expect(data['lastName'], equals('Wetpa'));
        expect(data['studentId'], equals('67000000'));
        expect(data['telephone'], equals('0812345678'));
      });

      test('keys the document by the auth uid (path = users/<uid>)',
          () async {
        await sut.createUser(_buildModel(uid: 'auth-uid-42'));

        final doc =
            await firestore.collection('users').doc('auth-uid-42').get();
        expect(doc.exists, isTrue);
        // No other doc is silently created.
        final all = await firestore.collection('users').get();
        expect(all.docs.length, equals(1));
        expect(all.docs.single.id, equals('auth-uid-42'));
      });

      test('stamps emailVerified=false on a freshly-created profile',
          () async {
        await sut.createUser(_buildModel(emailVerified: false));

        final doc = await firestore.collection('users').doc('uid-1').get();
        expect(doc.data()!['emailVerified'], isFalse);
      });

      test(
          'forces emailVerified=false even if the model claims true '
          '(server is the source of truth — OTP must verify it)',
          () async {
        await sut.createUser(_buildModel(emailVerified: true));

        final doc = await firestore.collection('users').doc('uid-1').get();
        expect(doc.data()!['emailVerified'], isFalse);
      });

      test('stamps createdAt with a server timestamp', () async {
        await sut.createUser(_buildModel());

        final doc = await firestore.collection('users').doc('uid-1').get();
        // fake_cloud_firestore materialises FieldValue.serverTimestamp() into
        // a Timestamp on read — so we just assert the field is present and
        // is a Timestamp, not a sentinel placeholder.
        final stored = doc.data()!['createdAt'];
        expect(
          stored,
          isA<Timestamp>(),
          reason: 'createdAt must be written via FieldValue.serverTimestamp()',
        );
      });
    });

    group('02 getUserById()', () {
      test('returns a UserModel containing all profile fields', () async {
        await sut.createUser(_buildModel(uid: 'uid-2'));

        final fetched = await sut.getUserById('uid-2');

        expect(fetched, isNotNull);
        expect(fetched!.uid, equals('uid-2'));
        expect(fetched.email, equals('sitta@mail.kmutt.ac.th'));
        expect(fetched.firstName, equals('Sitta'));
        expect(fetched.lastName, equals('Wetpa'));
        expect(fetched.studentId, equals('67000000'));
        expect(fetched.telephone, equals('0812345678'));
        expect(fetched.emailVerified, isFalse);
      });

      test('returns null when the doc does not exist', () async {
        final fetched = await sut.getUserById('does-not-exist');
        expect(fetched, isNull);
      });
    });

    group('03 watchUser()', () {
      test('emits a UserModel for the watched uid', () async {
        await sut.createUser(_buildModel(uid: 'uid-3'));

        final first = await sut.watchUser('uid-3').first;

        expect(first, isNotNull);
        expect(first!.uid, equals('uid-3'));
      });

      test('emits null when the doc does not exist', () async {
        final first = await sut.watchUser('does-not-exist').first;
        expect(first, isNull);
      });
    });

    group('04 updateUser()', () {
      test('updates the existing doc without re-writing createdAt', () async {
        await sut.createUser(_buildModel(uid: 'uid-4'));
        final before = await firestore.collection('users').doc('uid-4').get();
        final originalCreatedAt = before.data()!['createdAt'];

        await sut.updateUser(
          _buildModel(uid: 'uid-4', firstName: 'Updated'),
        );

        final after = await firestore.collection('users').doc('uid-4').get();
        expect(after.data()!['firstName'], equals('Updated'));
        expect(
          after.data()!['createdAt'],
          equals(originalCreatedAt),
          reason: 'updateUser must not overwrite createdAt',
        );
      });
    });
  });
}
