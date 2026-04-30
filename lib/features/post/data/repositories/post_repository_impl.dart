import 'package:campus_lost_found/features/feed/data/models/item_model.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/post/data/datasources/post_remote_datasource.dart';
import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDatasource _datasource;
  const PostRepositoryImpl(this._datasource);

  @override
  Future<Item> createItem(Item item) async {
    final created = await _datasource.createItem(ItemModel.fromEntity(item));
    return created.toEntity();
  }

  @override
  Future<void> updateItem(Item item) =>
      _datasource.updateItem(ItemModel.fromEntity(item));

  @override
  Future<void> deleteItem(String itemId) => _datasource.deleteItem(itemId);
}
