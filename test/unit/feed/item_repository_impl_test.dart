// WBS 1.2 — ItemRepositoryImpl unit tests
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/core/services/sync_metadata_datasource.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_local_datasource.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_remote_datasource.dart';
import 'package:campus_lost_found/features/feed/data/models/item_model.dart';
import 'package:campus_lost_found/features/feed/data/repositories/item_repository_impl.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

class _MockDatasource extends Mock implements ItemRemoteDatasource {}

class _MockLocalDatasource extends Mock implements ItemLocalDatasource {}

class _MockSyncMetadata extends Mock implements SyncMetadataDatasource {}

// ── helpers ───────────────────────────────────────────────────────────────────

final _createdAt = DateTime(2025, 3, 15, 10, 30);

ItemModel _makeModel({
  String id = 'item-001',
  String title = 'Test item',
  String category = 'founder',
  String status = 'active',
}) =>
    ItemModel(
      id: id,
      title: title,
      description: 'Description',
      category: category,
      status: status,
      location: 'Location',
      contact: '0800000000',
      imageUrls: const [],
      userId: 'uid-user',
      createdAt: _createdAt,
      occurredAt: _createdAt,
    );

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(_makeModel());
    registerFallbackValue(<ItemModel>[]);
    registerFallbackValue(DateTime(2026));
  });

  late _MockDatasource mockDatasource;
  late _MockLocalDatasource mockLocal;
  late _MockSyncMetadata mockSync;
  late ItemRepositoryImpl repo;

  setUp(() {
    mockDatasource = _MockDatasource();
    mockLocal = _MockLocalDatasource();
    mockSync = _MockSyncMetadata();

    when(() => mockLocal.getCachedFeed()).thenReturn([]);
    when(() => mockLocal.getCachedItem(any())).thenReturn(null);
    when(() => mockLocal.cacheFeed(any())).thenAnswer((_) async {});
    when(() => mockLocal.cacheItem(any())).thenAnswer((_) async {});
    when(() => mockSync.setLastSyncedAt(any(), any()))
        .thenAnswer((_) async {});

    repo = ItemRepositoryImpl(mockDatasource, mockLocal, mockSync);
  });

  // ── watchFeed() ────────────────────────────────────────────────────────────

  group('watchFeed() — WBS 1.2', () {
    test('emits Item entities mapped from datasource models', () async {
      final m1 = _makeModel(id: 'i1', category: 'founder');
      final m2 = _makeModel(id: 'i2', category: 'seeker');
      when(() => mockDatasource.watchFeed())
          .thenAnswer((_) => Stream.value([m1, m2]));

      final items = await repo.watchFeed().first;

      expect(items, hasLength(2));
      expect(items[0].id, 'i1');
      expect(items[0].category, ItemCategory.founder);
      expect(items[1].id, 'i2');
      expect(items[1].category, ItemCategory.seeker);
    });

    test('emits an empty list when datasource emits empty list', () async {
      when(() => mockDatasource.watchFeed())
          .thenAnswer((_) => Stream.value([]));

      final items = await repo.watchFeed().first;
      expect(items, isEmpty);
    });

    test('maps all required fields correctly', () async {
      final model = _makeModel(id: 'full-001', title: 'Wallet', category: 'seeker');
      when(() => mockDatasource.watchFeed())
          .thenAnswer((_) => Stream.value([model]));

      final item = (await repo.watchFeed().first).first;

      expect(item.id,        'full-001');
      expect(item.title,     'Wallet');
      expect(item.category,  ItemCategory.seeker);
      expect(item.status,    ItemStatus.active);
      expect(item.userId,    'uid-user');
      expect(item.createdAt, _createdAt);
    });
  });

  // ── watchItem() ────────────────────────────────────────────────────────────

  group('watchItem() — WBS 1.2', () {
    test('emits Item entity when model exists', () async {
      final model = _makeModel(id: 'watch-001');
      when(() => mockDatasource.watchItem('watch-001'))
          .thenAnswer((_) => Stream.value(model));

      final item = await repo.watchItem('watch-001').first;

      expect(item, isNotNull);
      expect(item!.id, 'watch-001');
    });

    test('emits null when model is null', () async {
      when(() => mockDatasource.watchItem('missing'))
          .thenAnswer((_) => Stream.value(null));

      final item = await repo.watchItem('missing').first;
      expect(item, isNull);
    });
  });

  // ── getItemById() ──────────────────────────────────────────────────────────

  group('getItemById() — WBS 1.2', () {
    test('returns Item entity when model exists', () async {
      final model = _makeModel(id: 'get-001');
      when(() => mockDatasource.getItemById('get-001'))
          .thenAnswer((_) async => model);

      final item = await repo.getItemById('get-001');

      expect(item, isNotNull);
      expect(item!.id, 'get-001');
    });

    test('returns null when model is null', () async {
      when(() => mockDatasource.getItemById('missing'))
          .thenAnswer((_) async => null);

      final item = await repo.getItemById('missing');
      expect(item, isNull);
    });
  });

  // ── searchItems() ──────────────────────────────────────────────────────────

  group('searchItems() — WBS 1.2', () {
    test('returns mapped entities on success', () async {
      final model = _makeModel(id: 'search-001', title: 'Wallet');
      when(() => mockDatasource.searchByTitle('Wallet'))
          .thenAnswer((_) async => [model]);

      final items = await repo.searchItems('Wallet');

      expect(items, hasLength(1));
      expect(items.first.id, 'search-001');
    });

    test('wraps FirebaseException in ItemFailure', () async {
      when(() => mockDatasource.searchByTitle(any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      expect(
        () => repo.searchItems('keyword'),
        throwsA(isA<ItemFailure>()),
      );
    });
  });

  // ── getRecentInCategory() — WBS 2.8 ──────────────────────────────────────

  group('getRecentInCategory() — WBS 2.8', () {
    test('returns mapped entities on success', () async {
      final model = _makeModel(id: 'cat-001', category: 'founder');
      when(() => mockDatasource.getRecentInCategory(
            categoryId: 'electronics',
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [model]);

      final items = await repo.getRecentInCategory(categoryId: 'electronics');

      expect(items, hasLength(1));
      expect(items.first.category, ItemCategory.founder);
    });

    test('wraps FirebaseException in ItemFailure', () async {
      when(() => mockDatasource.getRecentInCategory(
            categoryId: any(named: 'categoryId'),
            limit: any(named: 'limit'),
          )).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      expect(
        () => repo.getRecentInCategory(categoryId: 'electronics'),
        throwsA(isA<ItemFailure>()),
      );
    });
  });

  // ── watchMyItems() ─────────────────────────────────────────────────────────

  group('watchMyItems() — WBS 1.2', () {
    test('emits Item entities for the given userId', () async {
      final m1 = _makeModel(id: 'my-001');
      final m2 = _makeModel(id: 'my-002');
      when(() => mockDatasource.watchMyItems('uid-user'))
          .thenAnswer((_) => Stream.value([m1, m2]));

      final items = await repo.watchMyItems('uid-user').first;

      expect(items, hasLength(2));
      expect(items[0].id, 'my-001');
      expect(items[1].id, 'my-002');
    });
  });
}
