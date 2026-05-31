// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedItemsHash() => r'1e6452f5da25d0242d1bc3214c1f12bb0dc508ba';

/// Filtered view of the feed — merges the live first page
/// ([watchFeedProvider]) with any startAfter-loaded older pages
/// ([feedPaginationProvider]), then applies [FeedFilter], the taxonomy filter
/// and the search query. The data layer (datasource, repository) lives in
/// `item_provider.dart`; this provider is a thin presentation-layer view-model.
///
/// Copied from [feedItems].
@ProviderFor(feedItems)
final feedItemsProvider = AutoDisposeStreamProvider<List<Item>>.internal(
  feedItems,
  name: r'feedItemsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$feedItemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FeedItemsRef = AutoDisposeStreamProviderRef<List<Item>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
