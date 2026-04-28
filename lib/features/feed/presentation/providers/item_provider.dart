import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_remote_datasource.dart';
import 'package:campus_lost_found/features/feed/data/repositories/item_repository_impl.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';

part 'item_provider.g.dart';

@riverpod
ItemRemoteDatasource itemDatasource(ItemDatasourceRef ref) {
  return FirestoreItemDatasource(FirebaseFirestore.instance);
}

@riverpod
ItemRepository itemRepository(ItemRepositoryRef ref) {
  return ItemRepositoryImpl(ref.watch(itemDatasourceProvider));
}

@riverpod
Stream<List<Item>> watchFeed(WatchFeedRef ref) {
  return ref.watch(itemRepositoryProvider).watchFeed();
}

@riverpod
Stream<Item?> watchItem(WatchItemRef ref, String itemId) {
  return ref.watch(itemRepositoryProvider).watchItem(itemId);
}

@riverpod
Stream<List<Item>> watchMyItems(WatchMyItemsRef ref, String userId) {
  return ref.watch(itemRepositoryProvider).watchMyItems(userId);
}
