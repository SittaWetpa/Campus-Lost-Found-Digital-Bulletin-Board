import 'package:riverpod_annotation/riverpod_annotation.dart';

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
