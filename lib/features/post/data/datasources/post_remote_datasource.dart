import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_lost_found/features/feed/data/models/item_model.dart';

abstract interface class PostRemoteDatasource {
  Future<ItemModel> createItem(ItemModel model);
  Future<void> updateItem(ItemModel model);
  Future<void> deleteItem(String itemId);
}

class PostRemoteDatasourceImpl implements PostRemoteDatasource {
  final FirebaseFirestore _firestore;
  const PostRemoteDatasourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');

  @override
  Future<ItemModel> createItem(ItemModel model) async {
    final data = model.toFirestore();
    final ref = await _items.add(data);
    return ItemModel.fromMap(ref.id, data);
  }

  @override
  Future<void> updateItem(ItemModel model) async {
    final data = model.toFirestore()
      ..remove('createdAt')
      ..remove('userId')
      ..remove('editedAt');
    await _items.doc(model.id).update({
      ...data,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteItem(String itemId) => _items.doc(itemId).delete();
}
