import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_lost_found/features/feed/data/models/item_model.dart';

abstract interface class ItemRemoteDatasource {
  Stream<List<ItemModel>> watchFeed();
  Stream<ItemModel?> watchItem(String itemId);
  Stream<List<ItemModel>> watchMyItems(String userId);
  Future<ItemModel?> getItemById(String itemId);
  Future<List<ItemModel>> searchByTitle(String keyword);
  Future<List<ItemModel>> findSimilarFounderPosts(String keyword);
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
}

class FirestoreItemDatasource implements ItemRemoteDatasource {
  final FirebaseFirestore _firestore;
  const FirestoreItemDatasource(this._firestore);

  CollectionReference get _items => _firestore.collection('items');

  @override
  Stream<List<ItemModel>> watchFeed() {
    return _items
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
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
  Stream<List<ItemModel>> watchMyItems(String userId) {
    return _items
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ItemModel.fromFirestore).toList());
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
  Future<List<ItemModel>> findSimilarFounderPosts(String keyword) async {
    final end = keyword + String.fromCharCode(0xF8FF);
    final snapshot = await _items
        .where('status', isEqualTo: 'active')
        .where('category', isEqualTo: 'founder')
        .where('title', isGreaterThanOrEqualTo: keyword)
        .where('title', isLessThan: end)
        .limit(3)
        .get();
    return snapshot.docs.map(ItemModel.fromFirestore).toList();
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
}