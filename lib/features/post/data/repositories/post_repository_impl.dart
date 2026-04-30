import 'package:firebase_core/firebase_core.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_remote_datasource.dart';
import 'package:campus_lost_found/features/feed/data/models/item_model.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  final ItemRemoteDatasource _datasource;
  const PostRepositoryImpl(this._datasource);

  @override
  Future<Item> createItem(Item item) async {
    try {
      final data = ItemModel.fromEntity(item).toFirestore();
      final id = await _datasource.addItem(data);
      // Fetch back to get the server-stamped createdAt.
      final created = await _datasource.getItemById(id);
      if (created == null) throw const ItemFailure('Created item not found.');
      return created.toEntity();
    } on ItemFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw ItemFailure(e.message ?? 'Failed to create item.');
    } catch (_) {
      throw const ItemFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<void> updateItem(Item item) async {
    try {
      final data = ItemModel.fromEntity(item).toFirestore();
      await _datasource.updateItem(item.id, data);
    } on FirebaseException catch (e) {
      throw ItemFailure(e.message ?? 'Failed to update item.');
    } catch (_) {
      throw const ItemFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<void> deleteItem(String itemId) async {
    try {
      await _datasource.deleteItem(itemId);
    } on FirebaseException catch (e) {
      throw ItemFailure(e.message ?? 'Failed to delete item.');
    } catch (_) {
      throw const ItemFailure('An unexpected error occurred.');
    }
  }
}
