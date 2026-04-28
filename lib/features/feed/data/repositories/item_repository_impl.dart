import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';

class ItemRepositoryImpl implements ItemRepository {
  final FeedRemoteDatasource _datasource;
  const ItemRepositoryImpl(this._datasource);

  @override
  Stream<List<Item>> watchFeed() => _datasource
      .watchFeed()
      .map((models) => models.map((m) => m.toEntity()).toList());

  @override
  Stream<Item?> watchItem(String itemId) =>
      _datasource.watchItem(itemId).map((m) => m?.toEntity());

  @override
  Future<Item?> getItemById(String itemId) async {
    final model = await _datasource.getItemById(itemId);
    return model?.toEntity();
  }

  @override
  Future<List<Item>> searchItems(String keyword) async {
    try {
      return (await _datasource.searchItems(keyword))
          .map((m) => m.toEntity())
          .toList();
    } on FirebaseException catch (_) {
      throw const ServerFailure('A server error occurred. Please try again.');
    }
  }

  @override
  Future<List<Item>> getSimilarFounderPosts(String keyword) async {
    try {
      return (await _datasource.getSimilarFounderPosts(keyword))
          .map((m) => m.toEntity())
          .toList();
    } on FirebaseException catch (_) {
      throw const ServerFailure('A server error occurred. Please try again.');
    }
  }

  @override
  Stream<List<Item>> watchMyItems(String userId) => _datasource
      .watchMyItems(userId)
      .map((models) => models.map((m) => m.toEntity()).toList());
}
