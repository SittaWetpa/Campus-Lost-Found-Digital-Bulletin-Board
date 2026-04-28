// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedRemoteDatasourceHash() =>
    r'31426a9aae7dc0bd1ddaeba2d307a7cb6757ca19';

/// See also [feedRemoteDatasource].
@ProviderFor(feedRemoteDatasource)
final feedRemoteDatasourceProvider =
    AutoDisposeProvider<FeedRemoteDatasource>.internal(
  feedRemoteDatasource,
  name: r'feedRemoteDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedRemoteDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FeedRemoteDatasourceRef = AutoDisposeProviderRef<FeedRemoteDatasource>;
String _$itemRepositoryHash() => r'e6ad0ddb6736953b0baf39bf8c210fed1246ec9c';

/// See also [itemRepository].
@ProviderFor(itemRepository)
final itemRepositoryProvider = AutoDisposeProvider<ItemRepository>.internal(
  itemRepository,
  name: r'itemRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$itemRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ItemRepositoryRef = AutoDisposeProviderRef<ItemRepository>;
String _$feedItemsHash() => r'45d4cbf074ac8bebcd35366fcf86feccd1258628';

/// See also [feedItems].
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
