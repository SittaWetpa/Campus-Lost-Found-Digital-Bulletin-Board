import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:campus_lost_found/core/services/sync_metadata_datasource.dart';
import 'package:campus_lost_found/features/auth/data/datasources/user_local_datasource.dart';
import 'package:campus_lost_found/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:campus_lost_found/features/auth/data/models/user_model.dart';
import 'package:campus_lost_found/features/auth/data/repositories/user_repository_impl.dart';

class _MockRemote extends Mock implements UserRemoteDatasource {}

class _MockLocal extends Mock implements UserLocalDatasource {}

class _MockSync extends Mock implements SyncMetadataDatasource {}

class _FakeUserModel extends Fake implements UserModel {}

UserModel _userModel(String uid) => UserModel(
      uid: uid,
      email: '$uid@mail.kmutt.ac.th',
      firstName: 'User',
      lastName: uid,
      studentId: '67000001',
      telephone: '0800000000',
      emailVerified: true,
    );

void main() {
  late _MockRemote mockRemote;
  late _MockLocal mockLocal;
  late _MockSync mockSync;
  late UserRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(_FakeUserModel());
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    mockRemote = _MockRemote();
    mockLocal = _MockLocal();
    mockSync = _MockSync();

    when(() => mockSync.setLastSyncedAt(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockLocal.cacheUser(any())).thenAnswer((_) async {});

    repo = UserRepositoryImpl(mockRemote, mockLocal, mockSync);
  });

  group('watchUser() — WBS 2.11', () {
    test(
        '01 non-empty cache + remote error → cache seed emitted, no error propagated',
        () async {
      final cached = _userModel('alice');
      when(() => mockLocal.getCachedUser('alice')).thenReturn(cached);
      when(() => mockRemote.watchUser('alice'))
          .thenAnswer((_) => Stream.error(Exception('offline')));

      final result = await repo.watchUser('alice').first;

      expect(result, isNotNull);
      expect(result!.uid, 'alice');
    });

    test(
        '02 online → cacheUser() and setLastSyncedAt() called on remote emit',
        () async {
      final model = _userModel('bob');
      when(() => mockLocal.getCachedUser('bob')).thenReturn(null);
      when(() => mockRemote.watchUser('bob'))
          .thenAnswer((_) => Stream.value(model));

      await repo.watchUser('bob').first;

      verify(() => mockLocal.cacheUser(model)).called(1);
      verify(() => mockSync.setLastSyncedAt(
            HiveSyncMetadataDatasource.userProfileKey,
            any(),
          )).called(1);
    });

    test('03 empty cache + remote error → error propagated', () async {
      when(() => mockLocal.getCachedUser('ghost')).thenReturn(null);
      when(() => mockRemote.watchUser('ghost'))
          .thenAnswer((_) => Stream.error(Exception('offline')));

      await expectLater(
          repo.watchUser('ghost'), emitsError(isA<Exception>()));
    });
  });

  group('getUserById() — WBS 2.11', () {
    test('04 falls back to Hive cache on FirebaseException', () async {
      final cached = _userModel('carol');
      when(() => mockLocal.getCachedUser('carol')).thenReturn(cached);
      when(() => mockRemote.getUserById('carol')).thenThrow(
          FirebaseException(plugin: 'firestore', message: 'offline'));

      final result = await repo.getUserById('carol');

      expect(result, isNotNull);
      expect(result!.uid, 'carol');
    });

    test('05 returns null when remote throws and cache is empty', () async {
      when(() => mockLocal.getCachedUser('nobody')).thenReturn(null);
      when(() => mockRemote.getUserById('nobody')).thenThrow(
          FirebaseException(plugin: 'firestore', message: 'offline'));

      final result = await repo.getUserById('nobody');

      expect(result, isNull);
    });
  });
}
