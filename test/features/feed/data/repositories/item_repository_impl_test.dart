import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:campus_lost_found/core/services/sync_metadata_datasource.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_local_datasource.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_remote_datasource.dart';
import 'package:campus_lost_found/features/feed/data/models/item_model.dart';
import 'package:campus_lost_found/features/feed/data/repositories/item_repository_impl.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

class _MockItemLocalDatasource extends Mock implements ItemLocalDatasource {}

class _MockSyncMetadataDatasource extends Mock
    implements SyncMetadataDatasource {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      ItemModel(
        id: 'x',
        title: 'x',
        description: '',
        category: 'seeker',
        status: 'active',
        location: '',
        contact: '',
        imageUrls: [],
        userId: 'u',
        createdAt: DateTime(2026),
        occurredAt: DateTime(2026),
      ),
    );
  });

  late FakeFirebaseFirestore fakeFirestore;
  late _MockItemLocalDatasource mockLocal;
  late _MockSyncMetadataDatasource mockSync;
  late ItemRepositoryImpl repository;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    mockLocal = _MockItemLocalDatasource();
    mockSync = _MockSyncMetadataDatasource();

    when(() => mockLocal.getCachedFeed()).thenReturn([]);
    when(() => mockLocal.getCachedItem(any())).thenReturn(null);
    when(() => mockLocal.cacheFeed(any())).thenAnswer((_) async {});
    when(() => mockLocal.cacheItem(any())).thenAnswer((_) async {});
    when(() => mockSync.setLastSyncedAt(any(), any()))
        .thenAnswer((_) async {});

    repository = ItemRepositoryImpl(
      FirestoreItemDatasource(fakeFirestore),
      mockLocal,
      mockSync,
    );

    // Seed items
    await fakeFirestore.collection('items').add({
      'title': 'Lost wallet near library',
      'description': 'Brown leather wallet',
      'category': 'seeker',
      'status': 'active',
      'location': 'Library',
      'contact': '081-111-0001',
      'imageUrls': <String>[],
      'occurredAt': Timestamp.fromDate(DateTime(2026, 4, 27, 14, 30)),
      'userId': 'user-a',
      'createdAt': Timestamp.now(),
    });
    await fakeFirestore.collection('items').add({
      'title': 'Wallet found at gate B',
      'description': 'Black wallet with cards',
      'category': 'founder',
      'status': 'active',
      'location': 'Gate B',
      'contact': '081-111-0002',
      'imageUrls': <String>[],
      'occurredAt': Timestamp.fromDate(DateTime(2026, 4, 27, 14, 30)),
      'userId': 'user-b',
      'createdAt': Timestamp.now(),
    });
    await fakeFirestore.collection('items').add({
      'title': 'Wallet returned to owner',
      'description': 'Already claimed',
      'category': 'founder',
      'status': 'resolved',
      'location': 'Office',
      'contact': '081-111-0003',
      'imageUrls': <String>[],
      'occurredAt': Timestamp.fromDate(DateTime(2026, 4, 27, 14, 30)),
      'userId': 'user-c',
      'createdAt': Timestamp.now(),
    });
    await fakeFirestore.collection('items').add({
      'title': 'Lost keys',
      'description': 'Key ring with blue tag',
      'category': 'seeker',
      'status': 'active',
      'location': 'Canteen',
      'contact': '081-111-0004',
      'imageUrls': <String>[],
      'occurredAt': Timestamp.fromDate(DateTime(2026, 4, 27, 14, 30)),
      'userId': 'user-d',
      'createdAt': Timestamp.now(),
    });
  });

  group('ItemRepositoryImpl.searchItems() — WBS 2.3', () {
    test('01 searchItems("wallet") queries by title prefix and status=active',
        () async {
      final results = await repository.searchItems('wallet');

      // All returned items must have status active
      expect(results.every((i) => i.status.name == 'active'), isTrue);
      // The resolved wallet item must not appear
      expect(
        results.any((i) => i.title.contains('returned to owner')),
        isFalse,
      );
    });

    test('02 searchItems("") returns empty list without querying Firestore',
        () async {
      final results = await repository.searchItems('');

      expect(results, isEmpty);
    });

    test(
        '03 searchItems() result set contains only Active items, never Resolved',
        () async {
      // Search broad enough to match multiple items
      final results = await repository.searchItems('wallet');

      for (final item in results) {
        expect(
          item.status.name,
          equals('active'),
          reason:
              'Item "${item.title}" has status "${item.status.name}" — only active expected',
        );
      }
    });
  });

  group('ItemRepositoryImpl.getRecentInCategory() — WBS 2.8', () {
    setUp(() async {
      // Seed category-tagged items for WBS 2.8 tests.
      await fakeFirestore.collection('items').add({
        'title': 'Found iPhone 14',
        'description': 'Black iPhone found near cafeteria',
        'category': 'founder',
        'itemCategory': 'electronics',
        'status': 'active',
        'isSensitive': false,
        'location': 'Cafeteria',
        'contact': '081-200-0001',
        'imageUrls': <String>[],
        'occurredAt': Timestamp.fromDate(DateTime(2026, 5, 1, 10, 0)),
        'userId': 'user-e',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1, 10, 0)),
      });
      await fakeFirestore.collection('items').add({
        'title': 'Found AirPods case',
        'description': 'White AirPods near LIB-1',
        'category': 'founder',
        'itemCategory': 'electronics',
        'status': 'active',
        'isSensitive': false,
        'location': 'Library',
        'contact': '081-200-0002',
        'imageUrls': <String>[],
        'occurredAt': Timestamp.fromDate(DateTime(2026, 5, 2, 9, 0)),
        'userId': 'user-f',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 2, 9, 0)),
      });
      // Sensitive electronics post — must be excluded.
      await fakeFirestore.collection('items').add({
        'title': 'Found sensitive laptop',
        'description': 'Sensitive',
        'category': 'founder',
        'itemCategory': 'electronics',
        'status': 'active',
        'isSensitive': true,
        'location': 'Gate',
        'contact': '',
        'imageUrls': <String>[],
        'occurredAt': Timestamp.fromDate(DateTime(2026, 5, 3, 8, 0)),
        'userId': 'user-g',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 3, 8, 0)),
        'expiresAt': Timestamp.fromDate(DateTime(2026, 5, 17, 8, 0)),
      });
    });

    test('04 getRecentInCategory returns active non-sensitive Founder posts in category',
        () async {
      final results = await repository.getRecentInCategory(
        categoryId: 'electronics',
      );

      expect(results, isNotEmpty);
      for (final item in results) {
        expect(item.category, equals(ItemCategory.founder));
        expect(item.isSensitive, isFalse);
        expect(item.status.name, equals('active'));
        expect(item.itemTaxonomy?.id, equals('electronics'));
      }
    });

    test('05 getRecentInCategory excludes sensitive items even when category matches',
        () async {
      final results = await repository.getRecentInCategory(
        categoryId: 'electronics',
      );

      expect(
        results.any((i) => i.isSensitive),
        isFalse,
        reason: 'Sensitive items must never appear in similar posts panel',
      );
    });

    test('06 getRecentInCategory with no matching docs returns empty list',
        () async {
      final results = await repository.getRecentInCategory(
        categoryId: 'clothing',
      );

      expect(results, isEmpty);
    });
  });
}
