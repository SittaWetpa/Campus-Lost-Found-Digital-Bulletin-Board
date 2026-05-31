import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_lost_found/core/constants/app_constants.dart';
import 'package:campus_lost_found/features/feed/data/models/item_model.dart';

abstract interface class ItemRemoteDatasource {
  /// Live first page of the feed, bounded to [limit] docs (R5(d)).
  Stream<List<ItemModel>> watchFeed({int limit = AppConstants.feedPageSize});
  Stream<ItemModel?> watchItem(String itemId);
  /// Live first page of a user's items, bounded to [limit] docs (R5(d)).
  Stream<List<ItemModel>> watchMyItems(
    String userId, {
    int limit = AppConstants.feedPageSize,
  });

  /// startAfter-based "load more" page of active feed items, ordered by
  /// createdAt desc. Pass the createdAt of the last loaded item as [startAfter]
  /// to fetch the next [limit] older items (R5(d)).
  Future<List<ItemModel>> fetchFeedPage({
    DateTime? startAfter,
    int limit = AppConstants.feedPageSize,
  });

  /// startAfter-based "load more" page of a user's items (R5(d)).
  Future<List<ItemModel>> fetchMyItemsPage({
    required String userId,
    DateTime? startAfter,
    int limit = AppConstants.feedPageSize,
  });
  Future<ItemModel?> getItemById(String itemId);
  Future<List<ItemModel>> searchByTitle(String keyword);
  /// Returns up to [limit] active, non-sensitive Founder posts in [categoryId],
  /// ordered by createdAt descending. Used by the Similar Posts panel (WBS 2.8).
  Future<List<ItemModel>> getRecentInCategory({
    required String categoryId,
    int limit = 5,
  });

  /// Fire-and-forget: writes itemCategory='other' on legacy docs that lack it.
  void backfillItemCategory(String itemId);
  Future<String> addItem(Map<String, dynamic> data);
  Future<void> updateItem(String itemId, Map<String, dynamic> data);
  Future<void> deleteItem(String itemId);

  /// Writes [answer] to `items/{itemId}/private/answer` — a sub-document
  /// restricted to the poster. Never writes to the main item document.
  Future<void> writeSecretAnswer(String itemId, String answer);

  /// Reads the secret answer from the private sub-document.
  /// Returns null when no answer has been stored (new item without SQ, or
  /// legacy item not yet migrated).
  Future<String?> readSecretAnswer(String itemId);
  /// Returns true if the item has at least one request with status == "pending".
  Future<bool> hasPendingRequests(String itemId);
}

class FirestoreItemDatasource implements ItemRemoteDatasource {
  final FirebaseFirestore _firestore;
  const FirestoreItemDatasource(this._firestore);

  CollectionReference get _items => _firestore.collection('items');

  @override
  Stream<List<ItemModel>> watchFeed({int limit = AppConstants.feedPageSize}) {
    return _items
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(ItemModel.fromFirestore).toList());
  }

  @override
  Stream<ItemModel?> watchItem(String itemId) {
    return _items.doc(itemId).snapshots().map(
          (doc) => doc.exists ? ItemModel.fromFirestore(doc) : null,
        );
  }

  @override
  Stream<List<ItemModel>> watchMyItems(
    String userId, {
    int limit = AppConstants.feedPageSize,
  }) {
    return _items
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(ItemModel.fromFirestore).toList());
  }

  @override
  Future<List<ItemModel>> fetchFeedPage({
    DateTime? startAfter,
    int limit = AppConstants.feedPageSize,
  }) async {
    Query query = _items
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true);
    if (startAfter != null) {
      query = query.startAfter([Timestamp.fromDate(startAfter)]);
    }
    final snapshot = await query.limit(limit).get();
    return snapshot.docs.map(ItemModel.fromFirestore).toList();
  }

  @override
  Future<List<ItemModel>> fetchMyItemsPage({
    required String userId,
    DateTime? startAfter,
    int limit = AppConstants.feedPageSize,
  }) async {
    Query query = _items
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);
    if (startAfter != null) {
      query = query.startAfter([Timestamp.fromDate(startAfter)]);
    }
    final snapshot = await query.limit(limit).get();
    return snapshot.docs.map(ItemModel.fromFirestore).toList();
  }

  @override
  Future<ItemModel?> getItemById(String itemId) async {
    final doc = await _items.doc(itemId).get();
    return doc.exists ? ItemModel.fromFirestore(doc) : null;
  }

  @override
  Future<List<ItemModel>> searchByTitle(String keyword) async {
    // String.fromCharCode(0xF8FF) is a private-use-area char near end of Unicode
    // and acts as an upper-bound for Firestore prefix-range queries (WBS 2.3).
    final end = keyword + String.fromCharCode(0xF8FF);
    final snapshot = await _items
        .where('status', isEqualTo: 'active')
        .where('title', isGreaterThanOrEqualTo: keyword)
        .where('title', isLessThan: end)
        .get();
    return snapshot.docs.map(ItemModel.fromFirestore).toList();
  }

  @override
  Future<List<ItemModel>> getRecentInCategory({
    required String categoryId,
    int limit = 5,
  }) async {
    final snapshot = await _items
        .where('category', isEqualTo: 'founder')
        .where('itemCategory', isEqualTo: categoryId)
        .where('isSensitive', isEqualTo: false)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map(ItemModel.fromFirestore).toList();
  }

  @override
  void backfillItemCategory(String itemId) {
    // Fire-and-forget: silently patch legacy docs missing itemCategory.
    _items.doc(itemId).update({'itemCategory': 'other'}).ignore();
  }

  @override
  Future<String> addItem(Map<String, dynamic> data) async {
    // Extract secretAnswer before writing to main document — it lives in the
    // private sub-collection so only the poster can read it.
    final secretAnswer = data['secretAnswer'] as String?;
    final mainData = Map<String, dynamic>.from(data)..remove('secretAnswer');

    final ref = await _items.add({
      ...mainData,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (secretAnswer != null) {
      await writeSecretAnswer(ref.id, secretAnswer);
    }
    return ref.id;
  }

  @override
  Future<void> updateItem(String itemId, Map<String, dynamic> data) async {
    final secretAnswer = data['secretAnswer'] as String?;
    final mainData = Map<String, dynamic>.from(data)..remove('secretAnswer');

    await _items.doc(itemId).update({
      ...mainData,
      'editedAt': FieldValue.serverTimestamp(),
    });

    if (secretAnswer != null) {
      await writeSecretAnswer(itemId, secretAnswer);
    }
  }

  @override
  Future<void> deleteItem(String itemId) async {
    await _items.doc(itemId).delete();
  }

  @override
  Future<void> writeSecretAnswer(String itemId, String answer) async {
    await _firestore
        .collection('items')
        .doc(itemId)
        .collection('private')
        .doc('answer')
        .set({'secretAnswer': answer});
  }

  @override
  Future<String?> readSecretAnswer(String itemId) async {
    final doc = await _firestore
        .collection('items')
        .doc(itemId)
        .collection('private')
        .doc('answer')
        .get();
    if (!doc.exists) return null;
    return doc.data()!['secretAnswer'] as String?;
  }

  @override
  Future<bool> hasPendingRequests(String itemId) async {
    final snap = await _items
        .doc(itemId)
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}