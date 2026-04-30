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
          'userId': 'user-abc',
        };

        final id = await datasource.addItem(data);

        final doc = await fakeFirestore.collection('items').doc(id).get();
        expect(doc.exists, isTrue);
        expect(doc.data()!['userId'], equals('user-abc'));
        expect(doc.data()!['status'], equals('active'));
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
          'userId': 'user-def',
          'createdAt': Timestamp.now(),
        });

        await datasource.updateItem(ref.id, {'title': 'Found key ring'});

        final doc = await fakeFirestore.collection('items').doc(ref.id).get();
        expect(doc.data()!.containsKey('editedAt'), isTrue);
        expect(doc.data()!['editedAt'], isNotNull);
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
