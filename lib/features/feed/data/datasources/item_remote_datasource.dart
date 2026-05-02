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
    final ref = await _items.add({
      ...data,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  @override
  Future<void> updateItem(String itemId, Map<String, dynamic> data) async {
    await _items.doc(itemId).update({
      ...data,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteItem(String itemId) async {
    await _items.doc(itemId).delete();
  }
}