import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_pagination_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';

part 'feed_provider.g.dart';

/// Filtered view of the feed — merges the live first page
/// ([watchFeedProvider]) with any startAfter-loaded older pages
/// ([feedPaginationProvider]), then applies [FeedFilter], the taxonomy filter
/// and the search query. The data layer (datasource, repository) lives in
/// `item_provider.dart`; this provider is a thin presentation-layer view-model.
@riverpod
Stream<List<Item>> feedItems(FeedItemsRef ref) {
  final filter = ref.watch(feedFilterNotifierProvider);
  final taxonomy = ref.watch(taxonomyFilterNotifierProvider);
  final query = ref.watch(searchQueryNotifierProvider).toLowerCase().trim();
  final older = ref.watch(feedPaginationProvider).items;

  return ref.watch(itemRepositoryProvider).watchFeed().map((head) {
    final merged = mergeFeedPages(head, older);
    return applyFeedFilters(merged, filter, taxonomy, query);
  });
}

/// Pure filter pipeline reused by [feedItemsProvider] and any consumer that
/// needs the same All/Found/Lost + taxonomy + keyword view of a list.
List<Item> applyFeedFilters(
  List<Item> items,
  FeedFilter filter,
  ItemTaxonomy? taxonomy,
  String query,
) {
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
    result =
        result.where((i) => i.title.toLowerCase().contains(query)).toList();
  }
  return result;
}
