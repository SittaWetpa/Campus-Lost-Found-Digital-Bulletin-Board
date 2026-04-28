import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:campus_lost_found/features/feed/data/repositories/item_repository_impl.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_filter_provider.dart';

part 'feed_provider.g.dart';

@riverpod
FeedRemoteDatasource feedRemoteDatasource(FeedRemoteDatasourceRef ref) =>
    FeedRemoteDatasourceImpl(FirebaseFirestore.instance);

@riverpod
ItemRepository itemRepository(ItemRepositoryRef ref) =>
    ItemRepositoryImpl(ref.watch(feedRemoteDatasourceProvider));

@riverpod
Stream<List<Item>> feedItems(FeedItemsRef ref) {
  final filter = ref.watch(feedFilterNotifierProvider);
  return ref.watch(itemRepositoryProvider).watchFeed().map((items) {
    return switch (filter) {
      FeedFilter.all => items,
      FeedFilter.found =>
        items.where((i) => i.category == ItemCategory.founder).toList(),
      FeedFilter.lost =>
        items.where((i) => i.category == ItemCategory.seeker).toList(),
    };
  });
}
