import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_lost_found/features/feed/data/models/item_model.dart';

abstract interface class FeedRemoteDatasource {
  Stream<List<ItemModel>> watchFeed();
  Stream<ItemModel?> watchItem(String itemId);
  Future<ItemModel?> getItemById(String itemId);
  Future<List<ItemModel>> searchItems(String keyword);
  Future<List<ItemModel>> getSimilarFounderPosts(String keyword);
  Stream<List<ItemModel>> watchMyItems(String userId);
}

class FeedRemoteDatasourceImpl implements FeedRemoteDatasource {
  final FirebaseFirestore _firestore;
  const FeedRemoteDatasourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');

  @override
  Stream<List<ItemModel>> watchFeed() => _items
      .where('status', isEqualTo: 'active')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ItemModel.fromFirestore).toList());

  @override
  Stream<ItemModel?> watchItem(String itemId) => _items
      .doc(itemId)
      .snapshots()
      .map((d) => d.exists ? ItemModel.fromFirestore(d) : null);

  @override
  Future<ItemModel?> getItemById(String itemId) async {
    final doc = await _items.doc(itemId).get();
    return doc.exists ? ItemModel.fromFirestore(doc) : null;
  }

  @override
  Future<List<ItemModel>> searchItems(String keyword) async {
    final end = keyword.substring(0, keyword.length - 1) +
        String.fromCharCode(keyword.codeUnitAt(keyword.length - 1) + 1);
    final snap = await _items
        .where('status', isEqualTo: 'active')
        .where('title', isGreaterThanOrEqualTo: keyword)
        .where('title', isLessThan: end)
        .get();
    return snap.docs.map(ItemModel.fromFirestore).toList();
  }

  @override
  Future<List<ItemModel>> getSimilarFounderPosts(String keyword) async {
    final end = keyword.substring(0, keyword.length - 1) +
        String.fromCharCode(keyword.codeUnitAt(keyword.length - 1) + 1);
    final snap = await _items
        .where('category', isEqualTo: 'founder')
        .where('status', isEqualTo: 'active')
        .where('title', isGreaterThanOrEqualTo: keyword)
        .where('title', isLessThan: end)
        .limit(3)
        .get();
    return snap.docs.map(ItemModel.fromFirestore).toList();
  }

  @override
  Stream<List<ItemModel>> watchMyItems(String userId) => _items
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ItemModel.fromFirestore).toList());
}
