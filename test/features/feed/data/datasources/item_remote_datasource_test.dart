import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_remote_datasource.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreItemDatasource datasource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    datasource = FirestoreItemDatasource(fakeFirestore);
  });

  group('FirestoreItemDatasource — WBS 2.2', () {
    group('01 addItem()', () {
      test('creates document containing userId and status=active', () async {
        final data = {
          'title': 'Lost laptop',
          'description': 'MacBook Pro 14 inch',
          'category': 'seeker',
          'location': 'Library',
          'contact': '081-000-0001',
          'imageUrls': <String>[],
          'occurredAt': Timestamp.fromDate(DateTime(2026, 4, 27, 14, 30)),
          'userId': 'user-abc',
        };

        final id = await datasource.addItem(data);

        final doc = await fakeFirestore.collection('items').doc(id).get();
        expect(doc.exists, isTrue);
        expect(doc.data()!['userId'], equals('user-abc'));
        expect(doc.data()!['status'], equals('active'));
      });

      test('persists occurredAt as a Timestamp on the new document (WBS 2.2)',
          () async {
        final occurredAt = DateTime(2026, 4, 27, 14, 30);
        final data = {
          'title': 'Lost laptop',
          'description': 'MacBook Pro 14 inch',
          'category': 'seeker',
          'location': 'Library',
          'contact': '081-000-0001',
          'imageUrls': <String>[],
          'occurredAt': Timestamp.fromDate(occurredAt),
          'userId': 'user-abc',
        };

        final id = await datasource.addItem(data);

        final doc = await fakeFirestore.collection('items').doc(id).get();
        final stored = doc.data()!['occurredAt'];
        expect(stored, isA<Timestamp>());
        expect((stored as Timestamp).toDate(), equals(occurredAt));
      });
    });

    group('02 watchFeed()', () {
      test('stream excludes items where status is resolved', () async {
        await fakeFirestore.collection('items').add({
          'title': 'Active item',
          'description': 'desc',
          'category': 'seeker',
          'status': 'active',
          'location': 'Canteen',
          'contact': '081-000-0002',
          'imageUrls': <String>[],
          'occurredAt': Timestamp.fromDate(DateTime(2026, 4, 27, 14, 30)),
          'userId': 'user-xyz',
          'createdAt': Timestamp.now(),
        });
        await fakeFirestore.collection('items').add({
          'title': 'Resolved item',
          'description': 'desc',
          'category': 'founder',
          'status': 'resolved',
          'location': 'Gate B',
          'contact': '081-000-0003',
          'imageUrls': <String>[],
          'occurredAt': Timestamp.fromDate(DateTime(2026, 4, 27, 14, 30)),
          'userId': 'user-xyz',
          'createdAt': Timestamp.now(),
        });

        final models = await datasource.watchFeed().first;

        expect(models.length, equals(1));
        expect(models.first.title, equals('Active item'));
        expect(models.first.status, equals('active'));
      });
    });

    group('03 updateItem()', () {
      test('updated document contains editedAt field', () async {
        final ref = await fakeFirestore.collection('items').add({
          'title': 'Found keys',
          'description': 'Key ring',
          'category': 'founder',
          'status': 'active',
          'location': 'Parking lot',
          'contact': '081-000-0004',
          'imageUrls': <String>[],
          'occurredAt': Timestamp.fromDate(DateTime(2026, 4, 27, 14, 30)),
          'userId': 'user-def',
          'createdAt': Timestamp.now(),
        });

        await datasource.updateItem(ref.id, {'title': 'Found key ring'});

        final doc = await fakeFirestore.collection('items').doc(ref.id).get();
        expect(doc.data()!.containsKey('editedAt'), isTrue);
        expect(doc.data()!['editedAt'], isNotNull);
      });
    });

    // R5(d) — feed pagination: bounded live query + startAfter "load more".
    group('05 pagination (R5(d))', () {
      Future<void> seedActive(int n) async {
        for (var i = 0; i < n; i++) {
          await fakeFirestore.collection('items').add({
            'title': 'Item $i',
            'description': 'desc',
            'category': 'seeker',
            'status': 'active',
            'location': 'Canteen',
            'contact': '081-000-0000',
            'imageUrls': <String>[],
            'occurredAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
            'userId': 'user-page',
            // increasing createdAt → i=(n-1) is newest
            'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1).add(Duration(minutes: i))),
          });
        }
      }

      test('watchFeed(limit:) bounds the live query', () async {
        await seedActive(5);
        final models = await datasource.watchFeed(limit: 2).first;
        expect(models.length, equals(2));
      });

      test('fetchFeedPage returns newest-first, bounded to limit', () async {
        await seedActive(5);

        // First page = newest `limit` items, createdAt descending.
        final page1 = await datasource.fetchFeedPage(limit: 2);
        expect(page1.map((m) => m.title), equals(['Item 4', 'Item 3']));
        // (Value-based startAfter paging is not modelled by
        // fake_cloud_firestore; the cursor wiring is asserted in
        // feed_pagination_provider_test.dart.)
      });

      test('fetchFeedPage signals end of list with a short final page',
          () async {
        await seedActive(3);
        final page = await datasource.fetchFeedPage(limit: 20);
        expect(page.length, equals(3)); // < limit → caller marks reachedEnd
      });

      test('fetchMyItemsPage is scoped to the userId', () async {
        await seedActive(2); // userId: user-page
        await fakeFirestore.collection('items').add({
          'title': 'Other user',
          'description': 'desc',
          'category': 'seeker',
          'status': 'active',
          'location': 'Gate',
          'contact': '081-000-0001',
          'imageUrls': <String>[],
          'occurredAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
          'userId': 'someone-else',
          'createdAt': Timestamp.now(),
        });

        final page = await datasource.fetchMyItemsPage(userId: 'user-page');
        expect(page.length, equals(2));
        expect(page.every((m) => m.userId == 'user-page'), isTrue);
      });
    });

    group('04 deleteItem()', () {
      test('document no longer exists after deletion', () async {
        final ref = await fakeFirestore.collection('items').add({
          'title': 'Old item',
          'description': 'desc',
          'category': 'seeker',
          'status': 'active',
          'location': 'Gym',
          'contact': '081-000-0005',
          'imageUrls': <String>[],
          'occurredAt': Timestamp.fromDate(DateTime(2026, 4, 27, 14, 30)),
          'userId': 'user-ghi',
          'createdAt': Timestamp.now(),
        });

        await datasource.deleteItem(ref.id);

        final doc = await fakeFirestore.collection('items').doc(ref.id).get();
        expect(doc.exists, isFalse);
      });
    });
  });
}
