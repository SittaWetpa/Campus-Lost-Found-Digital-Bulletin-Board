import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/core/services/sync_metadata_datasource.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_local_datasource.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_remote_datasource.dart';
import 'package:campus_lost_found/core/constants/app_constants.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_page_repository.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';

class ItemRepositoryImpl implements ItemRepository, ItemPageRepository {
  final ItemRemoteDatasource _remoteDatasource;
  final ItemLocalDatasource _localDatasource;
  final SyncMetadataDatasource _syncMetadata;

  const ItemRepositoryImpl(
    this._remoteDatasource,
    this._localDatasource,
    this._syncMetadata,
  );

  @override
  Stream<List<Item>> watchFeed() {
    final cached = _localDatasource.getCachedFeed();
    final controller = StreamController<List<Item>>();

    if (cached.isNotEmpty) {
      controller.add(cached.map((m) => m.toEntity()).toList());
    }

    final sub = _remoteDatasource.watchFeed().listen(
      (models) async {
        await _localDatasource.cacheFeed(models);
        await _syncMetadata.setLastSyncedAt(
            HiveSyncMetadataDatasource.itemsFeedKey, DateTime.now());
        if (!controller.isClosed) {
          controller.add(models.map((m) => m.toEntity()).toList());
        }
      },
      onError: (e) {
        if (!controller.isClosed && cached.isEmpty) controller.addError(e);
        // cache available — suppress error so UI stays on cached data
      },
    );
    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };
    return controller.stream;
  }

  @override
  Stream<Item?> watchItem(String itemId) {
    final cachedModel = _localDatasource.getCachedItem(itemId);
    final controller = StreamController<Item?>();

    if (cachedModel != null) {
      controller.add(cachedModel.toEntity());
    }

    final sub = _remoteDatasource.watchItem(itemId).listen(
      (model) async {
        if (model != null) await _localDatasource.cacheItem(model);
        if (!controller.isClosed) controller.add(model?.toEntity());
      },
      onError: (e) {
        if (!controller.isClosed && cachedModel == null) controller.addError(e);
      },
    );
    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };
    return controller.stream;
  }

  @override
  Stream<List<Item>> watchMyItems(String userId) {
    final cached = _localDatasource
        .getCachedFeed()
        .where((m) => m.userId == userId)
        .toList();
    final controller = StreamController<List<Item>>();

    if (cached.isNotEmpty) {
      controller.add(cached.map((m) => m.toEntity()).toList());
    }

    final sub = _remoteDatasource.watchMyItems(userId).listen(
      (models) async {
        for (final m in models) {
          await _localDatasource.cacheItem(m);
        }
        if (!controller.isClosed) {
          controller.add(models.map((m) => m.toEntity()).toList());
        }
      },
      onError: (e) {
        if (!controller.isClosed && cached.isEmpty) controller.addError(e);
      },
    );
    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };
    return controller.stream;
  }

  @override
  Future<Item?> getItemById(String itemId) async {
    try {
      final model = await _remoteDatasource.getItemById(itemId);
      if (model == null) return null;
      // Lazy backfill: patch legacy docs missing itemCategory (fire-and-forget).
      if (model.itemCategory == null) {
        _remoteDatasource.backfillItemCategory(itemId);
      }
      return model.toEntity();
    } on FirebaseException catch (e) {
      final cached = _localDatasource.getCachedItem(itemId);
      if (cached != null) return cached.toEntity();
      throw ItemFailure(e.message ?? 'Failed to fetch item.');
    } catch (_) {
      throw const ItemFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<List<Item>> searchItems(String keyword) async {
    if (keyword.trim().isEmpty) return [];
    try {
      final models = await _remoteDatasource.searchByTitle(keyword);
      return models.map((m) => m.toEntity()).toList();
    } on FirebaseException catch (e) {
      throw ItemFailure(e.message ?? 'Search failed.');
    } catch (_) {
      throw const ItemFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<List<Item>> getRecentInCategory({
    required String categoryId,
    int limit = 5,
  }) async {
    try {
      final models = await _remoteDatasource.getRecentInCategory(
        categoryId: categoryId,
        limit: limit,
      );
      return models.map((m) => m.toEntity()).toList();
    } on FirebaseException catch (e) {
      throw ItemFailure(e.message ?? 'Failed to load similar posts.');
    } catch (_) {
      throw const ItemFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<List<Item>> fetchFeedPage({
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  }) async {
    try {
      final models = await _remoteDatasource.fetchFeedPage(
        startAfter: startAfterCreatedAt,
        limit: limit,
      );
      return models.map((m) => m.toEntity()).toList();
    } on FirebaseException catch (e) {
      throw ItemFailure(e.message ?? 'Failed to load more items.');
    } catch (_) {
      throw const ItemFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<List<Item>> fetchMyItemsPage({
    required String userId,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  }) async {
    try {
      final models = await _remoteDatasource.fetchMyItemsPage(
        userId: userId,
        startAfter: startAfterCreatedAt,
        limit: limit,
      );
      return models.map((m) => m.toEntity()).toList();
    } on FirebaseException catch (e) {
      throw ItemFailure(e.message ?? 'Failed to load more items.');
    } catch (_) {
      throw const ItemFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<String?> getItemSecretAnswer(String itemId) async {
    try {
      return await _remoteDatasource.readSecretAnswer(itemId);
    } on FirebaseException catch (e) {
      throw ItemFailure(e.message ?? 'Failed to fetch secret answer.');
    } catch (_) {
      throw const ItemFailure('An unexpected error occurred.');
    }
  }
}
