import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/core/services/sync_metadata_datasource.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_local_datasource.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_remote_datasource.dart';
import 'package:campus_lost_found/features/feed/data/models/item_model.dart';
import 'package:campus_lost_found/features/feed/data/repositories/item_repository_impl.dart';

class _MockRemoteDatasource extends Mock implements ItemRemoteDatasource {}

class _MockLocalDatasource extends Mock implements ItemLocalDatasource {}

class _MockSyncMetadata extends Mock implements SyncMetadataDatasource {}

ItemModel _model(String id) => ItemModel(
      id: id,
      title: 'T$id',
      description: '',
      category: 'seeker',
      status: 'active',
      location: '',
      contact: '',
      imageUrls: const [],
      userId: 'u',
      createdAt: DateTime(2026, 1, 1),
      occurredAt: DateTime(2026, 1, 1),
    );

void main() {
  late _MockRemoteDatasource mockRemote;
  late _MockLocalDatasource mockLocal;
  late _MockSyncMetadata mockSync;
  late ItemRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(_model('fallback'));
    registerFallbackValue(<ItemModel>[]);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    mockRemote = _MockRemoteDatasource();
    mockLocal = _MockLocalDatasource();
    mockSync = _MockSyncMetadata();

    when(() => mockSync.setLastSyncedAt(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockLocal.cacheFeed(any())).thenAnswer((_) async {});
    when(() => mockLocal.cacheItem(any())).thenAnswer((_) async {});

    repo = ItemRepositoryImpl(mockRemote, mockLocal, mockSync);
  });

  group('watchFeed() — WBS 2.11', () {
    test(
        '01 non-empty cache + remote error → cache seed emitted, no error propagated',
        () async {
      final cached = [_model('c1'), _model('c2')];
      when(() => mockLocal.getCachedFeed()).thenReturn(cached);
      when(() => mockRemote.watchFeed())
          .thenAnswer((_) => Stream.error(Exception('offline')));

      final stream = repo.watchFeed();
      final result = await stream.first;

      expect(result.map((i) => i.id), containsAll(['c1', 'c2']));
    });

    test('02 online → cacheFeed() and setLastSyncedAt called on remote emit',
        () async {
      final remote = [_model('r1')];
      when(() => mockLocal.getCachedFeed()).thenReturn([]);
      when(() => mockRemote.watchFeed())
          .thenAnswer((_) => Stream.value(remote));

      await repo.watchFeed().first;

      verify(() => mockLocal.cacheFeed(remote)).called(1);
      verify(() => mockSync.setLastSyncedAt(
            HiveSyncMetadataDatasource.itemsFeedKey,
            any(),
          )).called(1);
    });

    test('03 empty cache + remote error → error propagated', () async {
      when(() => mockLocal.getCachedFeed()).thenReturn([]);
      when(() => mockRemote.watchFeed())
          .thenAnswer((_) => Stream.error(Exception('offline')));

      await expectLater(repo.watchFeed(), emitsError(isA<Exception>()));
    });
  });

  group('getItemById() — WBS 2.11', () {
    test('04 falls back to cache on FirebaseException', () async {
      final cached = _model('cached-id');
      when(() => mockLocal.getCachedItem('cached-id')).thenReturn(cached);
      when(() => mockRemote.getItemById('cached-id'))
          .thenThrow(FirebaseException(plugin: 'firestore', message: 'offline'));

      final result = await repo.getItemById('cached-id');

      expect(result, isNotNull);
      expect(result!.id, 'cached-id');
    });

    test('05 throws ItemFailure when both remote and cache miss', () async {
      when(() => mockLocal.getCachedItem('missing')).thenReturn(null);
      when(() => mockRemote.getItemById('missing'))
          .thenThrow(FirebaseException(plugin: 'firestore', message: 'offline'));

      expect(() => repo.getItemById('missing'), throwsA(isA<ItemFailure>()));
    });
  });

  group('watchItem() — WBS 2.11', () {
    test(
        '06 non-empty cache + remote error → cache seed emitted, no error propagated',
        () async {
      final cached = _model('item1');
      when(() => mockLocal.getCachedItem('item1')).thenReturn(cached);
      when(() => mockRemote.watchItem('item1'))
          .thenAnswer((_) => Stream.error(Exception('offline')));

      final result = await repo.watchItem('item1').first;

      expect(result, isNotNull);
      expect(result!.id, 'item1');
    });

    test('07 online → cacheItem() called on remote emit', () async {
      final remote = _model('item2');
      when(() => mockLocal.getCachedItem('item2')).thenReturn(null);
      when(() => mockRemote.watchItem('item2'))
          .thenAnswer((_) => Stream.value(remote));

      await repo.watchItem('item2').first;

      verify(() => mockLocal.cacheItem(remote)).called(1);
    });

    test('08 empty cache + remote error → error propagated', () async {
      when(() => mockLocal.getCachedItem('gone')).thenReturn(null);
      when(() => mockRemote.watchItem('gone'))
          .thenAnswer((_) => Stream.error(Exception('offline')));

      await expectLater(
          repo.watchItem('gone'), emitsError(isA<Exception>()));
    });
  });

  group('watchMyItems() — WBS 2.11', () {
    test(
        '09 non-empty cache (matching userId) + remote error → cached items emitted',
        () async {
      final cached = [_model('m1'), _model('m2')]; // both have userId: 'u'
      when(() => mockLocal.getCachedFeed()).thenReturn(cached);
      when(() => mockRemote.watchMyItems('u'))
          .thenAnswer((_) => Stream.error(Exception('offline')));

      final result = await repo.watchMyItems('u').first;

      expect(result.map((i) => i.id), containsAll(['m1', 'm2']));
    });

    test('10 online → cacheItem() called for each remote item', () async {
      final remote = [_model('r1'), _model('r2')];
      when(() => mockLocal.getCachedFeed()).thenReturn([]);
      when(() => mockRemote.watchMyItems('u'))
          .thenAnswer((_) => Stream.value(remote));

      await repo.watchMyItems('u').first;

      verify(() => mockLocal.cacheItem(any())).called(2);
    });

    test('11 empty cache + remote error → error propagated', () async {
      when(() => mockLocal.getCachedFeed()).thenReturn([]);
      when(() => mockRemote.watchMyItems('u'))
          .thenAnswer((_) => Stream.error(Exception('offline')));

      await expectLater(
          repo.watchMyItems('u'), emitsError(isA<Exception>()));
    });
  });
}
