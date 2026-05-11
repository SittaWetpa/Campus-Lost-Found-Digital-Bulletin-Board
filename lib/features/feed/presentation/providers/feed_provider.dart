import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';

part 'feed_provider.g.dart';

/// Filtered view of the feed stream — applies [FeedFilter], the taxonomy
/// filter, and the search query on top of the shared
/// [itemRepositoryProvider] / `watchFeed()` chain defined in
/// `item_provider.dart`. The data layer (datasource, repository) lives there;
/// this provider is a thin presentation-layer view-model.
@riverpod
Stream<List<Item>> feedItems(FeedItemsRef ref) {
  final filter = ref.watch(feedFilterNotifierProvider);
  final taxonomy = ref.watch(taxonomyFilterNotifierProvider);
  final query = ref.watch(searchQueryNotifierProvider).toLowerCase().trim();
  return ref.watch(itemRepositoryProvider).watchFeed().map((items) {
    var result = switch (filter) {
      FeedFilter.all => items,
      FeedFilter.found =>
        items.where((i) => i.category == ItemCategory.founder).toList(),
      FeedFilter.lost =>
        items.where((i) => i.category == ItemCategory.seeker).toList(),
    };
    if (taxonomy != null) {
      result = result.where((i) => i.itemTaxonomy == taxonomy).toList();
    }
    if (query.isNotEmpty) {
      result = result
          .where((i) => i.title.toLowerCase().contains(query))
          .toList();
    }
    return result;
  });
}
