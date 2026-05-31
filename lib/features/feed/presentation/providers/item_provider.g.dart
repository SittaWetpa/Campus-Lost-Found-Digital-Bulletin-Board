// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$itemDatasourceHash() => r'd826898065545cf71a5a780af95ab401a60c7fca';

/// See also [itemDatasource].
@ProviderFor(itemDatasource)
final itemDatasourceProvider =
    AutoDisposeProvider<ItemRemoteDatasource>.internal(
  itemDatasource,
  name: r'itemDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$itemDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ItemDatasourceRef = AutoDisposeProviderRef<ItemRemoteDatasource>;
String _$itemLocalDatasourceHash() =>
    r'e48cfae28cc3ff7811013b24e293ea869598f21f';

/// See also [itemLocalDatasource].
@ProviderFor(itemLocalDatasource)
final itemLocalDatasourceProvider =
    AutoDisposeProvider<ItemLocalDatasource>.internal(
  itemLocalDatasource,
  name: r'itemLocalDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$itemLocalDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ItemLocalDatasourceRef = AutoDisposeProviderRef<ItemLocalDatasource>;
String _$itemRepositoryHash() => r'b58e620a61cd27a8ca0b8048549bbde1234b0e11';

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
String _$watchFeedHash() => r'13fbfe355f2f2eab3abc480edfb82e0db2f6368b';

/// See also [watchFeed].
@ProviderFor(watchFeed)
final watchFeedProvider = AutoDisposeStreamProvider<List<Item>>.internal(
  watchFeed,
  name: r'watchFeedProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$watchFeedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WatchFeedRef = AutoDisposeStreamProviderRef<List<Item>>;
String _$watchItemHash() => r'ca8bcb7c32b339fa6c7bcdbe8e8e5d7d9eb62abf';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [watchItem].
@ProviderFor(watchItem)
const watchItemProvider = WatchItemFamily();

/// See also [watchItem].
class WatchItemFamily extends Family<AsyncValue<Item?>> {
  /// See also [watchItem].
  const WatchItemFamily();

  /// See also [watchItem].
  WatchItemProvider call(
    String itemId,
  ) {
    return WatchItemProvider(
      itemId,
    );
  }

  @override
  WatchItemProvider getProviderOverride(
    covariant WatchItemProvider provider,
  ) {
    return call(
      provider.itemId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'watchItemProvider';
}

/// See also [watchItem].
class WatchItemProvider extends AutoDisposeStreamProvider<Item?> {
  /// See also [watchItem].
  WatchItemProvider(
    String itemId,
  ) : this._internal(
          (ref) => watchItem(
            ref as WatchItemRef,
            itemId,
          ),
          from: watchItemProvider,
          name: r'watchItemProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$watchItemHash,
          dependencies: WatchItemFamily._dependencies,
          allTransitiveDependencies: WatchItemFamily._allTransitiveDependencies,
          itemId: itemId,
        );

  WatchItemProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.itemId,
  }) : super.internal();

  final String itemId;

  @override
  Override overrideWith(
    Stream<Item?> Function(WatchItemRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchItemProvider._internal(
        (ref) => create(ref as WatchItemRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        itemId: itemId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<Item?> createElement() {
    return _WatchItemProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchItemProvider && other.itemId == itemId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, itemId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WatchItemRef on AutoDisposeStreamProviderRef<Item?> {
  /// The parameter `itemId` of this provider.
  String get itemId;
}

class _WatchItemProviderElement extends AutoDisposeStreamProviderElement<Item?>
    with WatchItemRef {
  _WatchItemProviderElement(super.provider);

  @override
  String get itemId => (origin as WatchItemProvider).itemId;
}

String _$watchMyItemsHash() => r'c40e39793038152aab11d6359393a348ebe9996b';

/// See also [watchMyItems].
@ProviderFor(watchMyItems)
const watchMyItemsProvider = WatchMyItemsFamily();

/// See also [watchMyItems].
class WatchMyItemsFamily extends Family<AsyncValue<List<Item>>> {
  /// See also [watchMyItems].
  const WatchMyItemsFamily();

  /// See also [watchMyItems].
  WatchMyItemsProvider call(
    String userId,
  ) {
    return WatchMyItemsProvider(
      userId,
    );
  }

  @override
  WatchMyItemsProvider getProviderOverride(
    covariant WatchMyItemsProvider provider,
  ) {
    return call(
      provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'watchMyItemsProvider';
}

/// See also [watchMyItems].
class WatchMyItemsProvider extends AutoDisposeStreamProvider<List<Item>> {
  /// See also [watchMyItems].
  WatchMyItemsProvider(
    String userId,
  ) : this._internal(
          (ref) => watchMyItems(
            ref as WatchMyItemsRef,
            userId,
          ),
          from: watchMyItemsProvider,
          name: r'watchMyItemsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$watchMyItemsHash,
          dependencies: WatchMyItemsFamily._dependencies,
          allTransitiveDependencies:
              WatchMyItemsFamily._allTransitiveDependencies,
          userId: userId,
        );

  WatchMyItemsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    Stream<List<Item>> Function(WatchMyItemsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchMyItemsProvider._internal(
        (ref) => create(ref as WatchMyItemsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Item>> createElement() {
    return _WatchMyItemsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchMyItemsProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WatchMyItemsRef on AutoDisposeStreamProviderRef<List<Item>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _WatchMyItemsProviderElement
    extends AutoDisposeStreamProviderElement<List<Item>> with WatchMyItemsRef {
  _WatchMyItemsProviderElement(super.provider);

  @override
  String get userId => (origin as WatchMyItemsProvider).userId;
}

String _$getItemSecretAnswerHash() =>
    r'746eb2fccf7508d4c7c63dbd61c29d0652764681';

/// See also [getItemSecretAnswer].
@ProviderFor(getItemSecretAnswer)
const getItemSecretAnswerProvider = GetItemSecretAnswerFamily();

/// See also [getItemSecretAnswer].
class GetItemSecretAnswerFamily extends Family<AsyncValue<String?>> {
  /// See also [getItemSecretAnswer].
  const GetItemSecretAnswerFamily();

  /// See also [getItemSecretAnswer].
  GetItemSecretAnswerProvider call(
    String itemId,
  ) {
    return GetItemSecretAnswerProvider(
      itemId,
    );
  }

  @override
  GetItemSecretAnswerProvider getProviderOverride(
    covariant GetItemSecretAnswerProvider provider,
  ) {
    return call(
      provider.itemId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'getItemSecretAnswerProvider';
}

/// See also [getItemSecretAnswer].
class GetItemSecretAnswerProvider extends AutoDisposeFutureProvider<String?> {
  /// See also [getItemSecretAnswer].
  GetItemSecretAnswerProvider(
    String itemId,
  ) : this._internal(
          (ref) => getItemSecretAnswer(
            ref as GetItemSecretAnswerRef,
            itemId,
          ),
          from: getItemSecretAnswerProvider,
          name: r'getItemSecretAnswerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getItemSecretAnswerHash,
          dependencies: GetItemSecretAnswerFamily._dependencies,
          allTransitiveDependencies:
              GetItemSecretAnswerFamily._allTransitiveDependencies,
          itemId: itemId,
        );

  GetItemSecretAnswerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.itemId,
  }) : super.internal();

  final String itemId;

  @override
  Override overrideWith(
    FutureOr<String?> Function(GetItemSecretAnswerRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetItemSecretAnswerProvider._internal(
        (ref) => create(ref as GetItemSecretAnswerRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        itemId: itemId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String?> createElement() {
    return _GetItemSecretAnswerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetItemSecretAnswerProvider && other.itemId == itemId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, itemId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GetItemSecretAnswerRef on AutoDisposeFutureProviderRef<String?> {
  /// The parameter `itemId` of this provider.
  String get itemId;
}

class _GetItemSecretAnswerProviderElement
    extends AutoDisposeFutureProviderElement<String?>
    with GetItemSecretAnswerRef {
  _GetItemSecretAnswerProviderElement(super.provider);

  @override
  String get itemId => (origin as GetItemSecretAnswerProvider).itemId;
}

String _$searchNotifierHash() => r'bd39a6b8430ed693086027b47e1708850adcaab6';

/// See also [SearchNotifier].
@ProviderFor(SearchNotifier)
final searchNotifierProvider = AutoDisposeNotifierProvider<SearchNotifier,
    AsyncValue<List<Item>>>.internal(
  SearchNotifier.new,
  name: r'searchNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SearchNotifier = AutoDisposeNotifier<AsyncValue<List<Item>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
