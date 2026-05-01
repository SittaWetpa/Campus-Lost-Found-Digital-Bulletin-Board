import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/feed/data/providers.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_filter_provider.dart';

export 'package:campus_lost_found/features/feed/data/providers.dart'
    show itemRepositoryProvider, feedRemoteDatasourceProvider;

part 'feed_provider.g.dart';

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
