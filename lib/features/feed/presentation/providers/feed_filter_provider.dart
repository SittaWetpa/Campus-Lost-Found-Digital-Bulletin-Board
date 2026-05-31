import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/post/domain/entities/item_taxonomy.dart';

part 'feed_filter_provider.g.dart';

enum FeedFilter { all, found, lost }

@riverpod
class FeedFilterNotifier extends _$FeedFilterNotifier {
  @override
  FeedFilter build() => FeedFilter.all;

  void select(FeedFilter filter) => state = filter;
}

@riverpod
class SearchQueryNotifier extends _$SearchQueryNotifier {
  @override
  String build() => '';

  void update(String query) => state = query;
}

@riverpod
class TaxonomyFilterNotifier extends _$TaxonomyFilterNotifier {
  @override
  ItemTaxonomy? build() => null;

  void select(ItemTaxonomy? taxonomy) => state = taxonomy;

  void clear() => state = null;
}
