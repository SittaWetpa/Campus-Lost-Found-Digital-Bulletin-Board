// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedItemsHash() => r'45d4cbf074ac8bebcd35366fcf86feccd1258628';

/// Filtered view of the feed stream — applies [FeedFilter] on top of the
/// shared [itemRepositoryProvider] / `watchFeed()` chain defined in
/// `item_provider.dart`. The data layer (datasource, repository) lives there;
/// this provider is a thin presentation-layer view-model.
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
