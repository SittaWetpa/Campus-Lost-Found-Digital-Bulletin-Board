import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:campus_lost_found/features/auth/data/datasources/user_local_datasource.dart';
import 'package:campus_lost_found/features/auth/data/models/user_model.dart';

UserModel _user({
  String uid = 'u1',
  String email = 'test@mail.kmutt.ac.th',
  String? avatarUrl,
  DateTime? createdAt,
  bool isAdmin = false,
}) =>
    UserModel(
      uid: uid,
      email: email,
      firstName: 'Test',
      lastName: 'User',
      studentId: '67000001',
      telephone: '0812345678',
      avatarUrl: avatarUrl,
      emailVerified: true,
      createdAt: createdAt,
      isAdmin: isAdmin,
    );

void main() {
  late Directory tmpDir;
  late Box<Map> box;
  late HiveUserLocalDatasource ds;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('hive_user_test_');
    Hive.init(tmpDir.path);
    box = await Hive.openBox<Map>('user_profile_box_test');
    ds = HiveUserLocalDatasource(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('user_profile_box_test');
    await tmpDir.delete(recursive: true);
  });

  group('HiveUserLocalDatasource — WBS 2.11', () {
    test('01 getCachedUser() returns null on cold start', () {
      expect(ds.getCachedUser('u1'), isNull);
    });

    test('02 cacheUser() persists and getCachedUser() retrieves by uid',
        () async {
      final model = _user(uid: 'alice', email: 'alice@mail.kmutt.ac.th');
      await ds.cacheUser(model);

      final result = ds.getCachedUser('alice');
      expect(result, isNotNull);
      expect(result!.uid, 'alice');
      expect(result.email, 'alice@mail.kmutt.ac.th');
    });

    test('03 cacheUser() upserts — replaces entry with same uid', () async {
      await ds.cacheUser(_user(uid: 'u1', email: 'old@mail.kmutt.ac.th'));
      await ds.cacheUser(_user(uid: 'u1', email: 'new@mail.kmutt.ac.th'));

      expect(ds.getCachedUser('u1')!.email, 'new@mail.kmutt.ac.th');
    });

    test('04 round-trip toHiveMap/fromHiveMap preserves all non-null fields',
        () async {
      final original = UserModel(
        uid: 'u99',
        email: 'rt@mail.kmutt.ac.th',
        firstName: 'Round',
        lastName: 'Trip',
        studentId: '67009999',
        telephone: '0899999999',
        avatarUrl: 'https://example.com/avatar.jpg',
        emailVerified: true,
        createdAt: DateTime(2026, 1, 15, 9, 0),
        isAdmin: false,
      );
      await ds.cacheUser(original);
      final result = ds.getCachedUser('u99')!;

      expect(result.uid, original.uid);
      expect(result.email, original.email);
      expect(result.firstName, original.firstName);
      expect(result.lastName, original.lastName);
      expect(result.studentId, original.studentId);
      expect(result.telephone, original.telephone);
      expect(result.avatarUrl, original.avatarUrl);
      expect(result.emailVerified, original.emailVerified);
      expect(result.createdAt, original.createdAt);
      expect(result.isAdmin, original.isAdmin);
    });

    test('05 nullable avatarUrl and createdAt preserved as null', () async {
      await ds.cacheUser(_user(uid: 'u2', avatarUrl: null, createdAt: null));
      final result = ds.getCachedUser('u2')!;

      expect(result.avatarUrl, isNull);
      expect(result.createdAt, isNull);
    });
  });
}
