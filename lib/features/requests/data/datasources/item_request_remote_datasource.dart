import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:campus_lost_found/features/requests/data/models/item_request_model.dart';

abstract interface class ItemRequestRemoteDatasource {
  Stream<List<ItemRequestModel>> watchRequestsForItem(String itemId);

  /// Filtered stream — only requests where requesterId == [requesterId].
  /// Uses a .where() query that satisfies Firestore list-query rules for
  /// non-poster users, avoiding permission-denied on unfiltered collection reads.
  Stream<List<ItemRequestModel>> watchMyRequestForItem(
      String itemId, String requesterId);

  /// Single-document stream for one request. Readable by both the poster
  /// and the requester under existing Firestore rules.
  Stream<ItemRequestModel?> watchSingleRequest(
      String itemId, String requestId);
  Future<ItemRequestModel> submitRequest(ItemRequestModel model);
  Future<void> approveRequest({
    required String itemId,
    required String requestId,
    required String requesterId,
  });
  Future<void> rejectRequest({
    required String itemId,
    required String requestId,
  });
  Future<void> cancelRequest({
    required String itemId,
    required String requestId,
  });
  Future<bool> hasPendingRequests(String itemId);

  /// Uploads a photo for a Found Report and returns the download URL (WBS 2.4).
  Future<String> uploadRequestPhoto(File imageFile);
}

class FirestoreItemRequestDatasource implements ItemRequestRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirestoreItemRequestDatasource(this._firestore, {FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  CollectionReference _requests(String itemId) =>
      _firestore.collection('items').doc(itemId).collection('requests');

  DocumentReference _item(String itemId) =>
      _firestore.collection('items').doc(itemId);

  @override
  Stream<List<ItemRequestModel>> watchRequestsForItem(String itemId) {
    return _requests(itemId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ItemRequestModel.fromFirestore).toList());
  }

  @override
  Stream<List<ItemRequestModel>> watchMyRequestForItem(
      String itemId, String requesterId) {
    return _requests(itemId)
        .where('requesterId', isEqualTo: requesterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ItemRequestModel.fromFirestore).toList());
  }

  @override
  Stream<ItemRequestModel?> watchSingleRequest(
      String itemId, String requestId) {
    return _requests(itemId).doc(requestId).snapshots().map(
          (doc) => doc.exists ? ItemRequestModel.fromFirestore(doc) : null,
        );
  }

  @override
  Future<ItemRequestModel> submitRequest(ItemRequestModel model) async {
    final ref = await _requests(model.itemId).add({
      ...model.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    final doc = await ref.get();
    return ItemRequestModel.fromFirestore(doc);
  }

  @override
  Future<void> approveRequest({
    required String itemId,
    required String requestId,
    required String requesterId,
  }) async {
    final batch = _firestore.batch();
    batch.update(
      _requests(itemId).doc(requestId),
      {'status': 'approved'},
    );
    batch.update(
      _item(itemId),
      {'status': 'resolved', 'claimedBy': requesterId},
    );
    await batch.commit();
  }

  @override
  Future<void> rejectRequest({
    required String itemId,
    required String requestId,
  }) async {
    await _requests(itemId).doc(requestId).update({'status': 'rejected'});
  }

  @override
  Future<void> cancelRequest({
    required String itemId,
    required String requestId,
  }) async {
    await _requests(itemId).doc(requestId).update({'status': 'cancelled'});
  }

  @override
  Future<bool> hasPendingRequests(String itemId) async {
    final snapshot = await _requests(itemId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<String> uploadRequestPhoto(File imageFile) async {
    final ref = _storage
        .ref()
        .child('request_photos')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(imageFile);
    return ref.getDownloadURL();
  }
}
