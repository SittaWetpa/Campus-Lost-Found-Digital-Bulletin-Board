// WBS 1.3 — Item Detail Screen / WBS 2.4 — Request System:
// ItemRequestRepositoryImpl — approveRequest() batch-write integration test

import 'package:campus_lost_found/features/requests/data/datasources/item_request_remote_datasource.dart';
import 'package:campus_lost_found/features/requests/data/repositories/item_request_repository_impl.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ItemRequestRepositoryImpl — WBS 1.3 / 2.4', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ItemRequestRepositoryImpl repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = ItemRequestRepositoryImpl(
        FirestoreItemRequestDatasource(fakeFirestore),
      );
    });

    test(
      'approveRequest() batch-writes request.status=approved, '
      'item.status=resolved, item.claimedBy=requesterId atomically',
      () async {
        // Seed item and request documents.
        await fakeFirestore
            .collection('items')
            .doc('item-001')
            .set({'status': 'active', 'userId': 'poster-001'});
        await fakeFirestore
            .collection('items')
            .doc('item-001')
            .collection('requests')
            .doc('req-001')
            .set({'status': 'pending', 'requesterId': 'requester-001'});

        await repository.approveRequest(
          itemId: 'item-001',
          requestId: 'req-001',
          requesterId: 'requester-001',
        );

        final itemDoc =
            await fakeFirestore.collection('items').doc('item-001').get();
        final reqDoc = await fakeFirestore
            .collection('items')
            .doc('item-001')
            .collection('requests')
            .doc('req-001')
            .get();

        expect(itemDoc.data()!['status'], 'resolved');
        expect(itemDoc.data()!['claimedBy'], 'requester-001');
        expect(reqDoc.data()!['status'], 'approved');
      },
    );

    test(
      'rejectRequest() sets request.status = rejected',
      () async {
        await fakeFirestore
            .collection('items')
            .doc('item-001')
            .collection('requests')
            .doc('req-001')
            .set({'status': 'pending'});

        await repository.rejectRequest(
          itemId: 'item-001',
          requestId: 'req-001',
        );

        final doc = await fakeFirestore
            .collection('items')
            .doc('item-001')
            .collection('requests')
            .doc('req-001')
            .get();
        expect(doc.data()!['status'], 'rejected');
      },
    );

    test(
      'cancelRequest() sets request.status = cancelled',
      () async {
        await fakeFirestore
            .collection('items')
            .doc('item-001')
            .collection('requests')
            .doc('req-001')
            .set({'status': 'pending'});

        await repository.cancelRequest(
          itemId: 'item-001',
          requestId: 'req-001',
        );

        final doc = await fakeFirestore
            .collection('items')
            .doc('item-001')
            .collection('requests')
            .doc('req-001')
            .get();
        expect(doc.data()!['status'], 'cancelled');
      },
    );

    test(
      'hasPendingRequests() returns true when a pending request exists',
      () async {
        await fakeFirestore
            .collection('items')
            .doc('item-001')
            .collection('requests')
            .doc('req-001')
            .set({'status': 'pending'});

        final result =
            await repository.hasPendingRequests('item-001');
        expect(result, isTrue);
      },
    );

    test(
      'hasPendingRequests() returns false when no pending requests exist',
      () async {
        await fakeFirestore
            .collection('items')
            .doc('item-001')
            .collection('requests')
            .doc('req-001')
            .set({'status': 'approved'});

        final result =
            await repository.hasPendingRequests('item-001');
        expect(result, isFalse);
      },
    );

    test(
      'watchMyRequestForItem() streams only requests matching requesterId',
      () async {
        final col = fakeFirestore
            .collection('items')
            .doc('item-001')
            .collection('requests');

        await col.doc('req-A').set({
          'status': 'pending',
          'requesterId': 'user-A',
          'requesterName': 'Alice',
          'requesterContact': '0800000001',
          'studentId': '63000001',
          'type': 'claim',
          'createdAt': DateTime(2025, 1, 1),
        });
        await col.doc('req-B').set({
          'status': 'pending',
          'requesterId': 'user-B',
          'requesterName': 'Bob',
          'requesterContact': '0800000002',
          'studentId': '63000002',
          'type': 'claim',
          'createdAt': DateTime(2025, 1, 2),
        });

        final results = await repository
            .watchMyRequestForItem('item-001', 'user-A')
            .first;

        expect(results.length, 1);
        expect(results.first.id, 'req-A');
        expect(results.first.requesterId, 'user-A');
      },
    );

    test(
      'watchSingleRequest() streams a single request by ID',
      () async {
        await fakeFirestore
            .collection('items')
            .doc('item-001')
            .collection('requests')
            .doc('req-001')
            .set({
          'status': 'pending',
          'requesterId': 'user-X',
          'requesterName': 'Xavier',
          'requesterContact': '0800000003',
          'studentId': '63000003',
          'type': 'found',
          'createdAt': DateTime(2025, 1, 1),
        });

        final result = await repository
            .watchSingleRequest('item-001', 'req-001')
            .first;

        expect(result, isNotNull);
        expect(result!.id, 'req-001');
        expect(result.requesterId, 'user-X');
      },
    );

    test(
      'watchSingleRequest() emits null for a non-existent request',
      () async {
        final result = await repository
            .watchSingleRequest('item-001', 'does-not-exist')
            .first;

        expect(result, isNull);
      },
    );
  });
}
