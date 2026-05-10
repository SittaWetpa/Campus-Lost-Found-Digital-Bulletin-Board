import 'package:firebase_core/firebase_core.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_remote_datasource.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';

class ItemRepositoryImpl implements ItemRepository {
  final ItemRemoteDatasource _datasource;
  const ItemRepositoryImpl(this._datasource);

  @override
  Stream<List<Item>> watchFeed() {
    return _datasource.watchFeed().map(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
  }

  @override
  Stream<Item?> watchItem(String itemId) {
    return _datasource.watchItem(itemId).map((m) => m?.toEntity());
  }

  @override
  Stream<List<Item>> watchMyItems(String userId) {
    return _datasource.watchMyItems(userId).map(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
  }

  @override
  Future<Item?> getItemById(String itemId) async {
    try {
      final model = await _datasource.getItemById(itemId);
      return model?.toEntity();
    } on FirebaseException catch (e) {
      throw ItemFailure(e.message ?? 'Failed to fetch item.');
    } catch (_) {
      throw const ItemFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<List<Item>> searchItems(String keyword) async {
    if (keyword.trim().isEmpty) return [];
    try {
      final models = await _datasource.searchByTitle(keyword);
      return models.map((m) => m.toEntity()).toList();
    } on FirebaseException catch (e) {
      throw ItemFailure(e.message ?? 'Search failed.');
    } catch (_) {
      throw const ItemFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<List<Item>> getSimilarFounderPosts(String keyword) async {
    try {
      final models = await _datasource.findSimilarFounderPosts(keyword);
      return models.map((m) => m.toEntity()).toList();
    } on FirebaseException catch (e) {
      throw ItemFailure(e.message ?? 'Failed to load similar posts.');
    } catch (_) {
      throw const ItemFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<String?> getItemSecretAnswer(String itemId) async {
    try {
      return await _datasource.readSecretAnswer(itemId);
    } on FirebaseException catch (e) {
      throw ItemFailure(e.message ?? 'Failed to fetch secret answer.');
    } catch (_) {
      throw const ItemFailure('An unexpected error occurred.');
    }
  }
}
