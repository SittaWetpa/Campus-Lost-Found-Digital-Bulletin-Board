import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:campus_lost_found/core/services/sync_metadata_datasource.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_local_datasource.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_remote_datasource.dart';
import 'package:campus_lost_found/features/feed/data/models/item_model.dart';
import 'package:campus_lost_found/features/feed/data/repositories/item_repository_impl.dart';

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
}
