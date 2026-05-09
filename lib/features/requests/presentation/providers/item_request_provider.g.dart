// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_request_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$itemRequestDatasourceHash() =>
    r'4c962a46bccd25b5f5e522cbde952e64d4cb4558';

/// See also [itemRequestDatasource].
@ProviderFor(itemRequestDatasource)
final itemRequestDatasourceProvider =
    AutoDisposeProvider<ItemRequestRemoteDatasource>.internal(
  itemRequestDatasource,
  name: r'itemRequestDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$itemRequestDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ItemRequestDatasourceRef
    = AutoDisposeProviderRef<ItemRequestRemoteDatasource>;
String _$itemRequestRepositoryHash() =>
    r'a721bec70879613a26db38f9a3c63c56cbccbcda';

/// See also [itemRequestRepository].
@ProviderFor(itemRequestRepository)
final itemRequestRepositoryProvider =
    AutoDisposeProvider<ItemRequestRepository>.internal(
  itemRequestRepository,
  name: r'itemRequestRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$itemRequestRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ItemRequestRepositoryRef
    = AutoDisposeProviderRef<ItemRequestRepository>;
String _$watchRequestsForItemHash() =>
    r'489c797d0f3c7da909eb302ac9785b00ce785270';

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

/// See also [watchRequestsForItem].
@ProviderFor(watchRequestsForItem)
const watchRequestsForItemProvider = WatchRequestsForItemFamily();

/// See also [watchRequestsForItem].
class WatchRequestsForItemFamily extends Family<AsyncValue<List<ItemRequest>>> {
  /// See also [watchRequestsForItem].
  const WatchRequestsForItemFamily();

  /// See also [watchRequestsForItem].
  WatchRequestsForItemProvider call(
    String itemId,
  ) {
    return WatchRequestsForItemProvider(
      itemId,
    );
  }

  @override
  WatchRequestsForItemProvider getProviderOverride(
    covariant WatchRequestsForItemProvider provider,
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
  String? get name => r'watchRequestsForItemProvider';
}

/// See also [watchRequestsForItem].
class WatchRequestsForItemProvider
    extends AutoDisposeStreamProvider<List<ItemRequest>> {
  /// See also [watchRequestsForItem].
  WatchRequestsForItemProvider(
    String itemId,
  ) : this._internal(
          (ref) => watchRequestsForItem(
            ref as WatchRequestsForItemRef,
            itemId,
          ),
          from: watchRequestsForItemProvider,
          name: r'watchRequestsForItemProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$watchRequestsForItemHash,
          dependencies: WatchRequestsForItemFamily._dependencies,
          allTransitiveDependencies:
              WatchRequestsForItemFamily._allTransitiveDependencies,
          itemId: itemId,
        );

  WatchRequestsForItemProvider._internal(
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
    Stream<List<ItemRequest>> Function(WatchRequestsForItemRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchRequestsForItemProvider._internal(
        (ref) => create(ref as WatchRequestsForItemRef),
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
  AutoDisposeStreamProviderElement<List<ItemRequest>> createElement() {
    return _WatchRequestsForItemProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchRequestsForItemProvider && other.itemId == itemId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, itemId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WatchRequestsForItemRef
    on AutoDisposeStreamProviderRef<List<ItemRequest>> {
  /// The parameter `itemId` of this provider.
  String get itemId;
}

class _WatchRequestsForItemProviderElement
    extends AutoDisposeStreamProviderElement<List<ItemRequest>>
    with WatchRequestsForItemRef {
  _WatchRequestsForItemProviderElement(super.provider);

  @override
  String get itemId => (origin as WatchRequestsForItemProvider).itemId;
}

String _$watchMyRequestForItemHash() =>
    r'2f7af3c3b7d0b5a0114bccec9b5c53f64eff087e';

/// See also [watchMyRequestForItem].
@ProviderFor(watchMyRequestForItem)
const watchMyRequestForItemProvider = WatchMyRequestForItemFamily();

/// See also [watchMyRequestForItem].
class WatchMyRequestForItemFamily
    extends Family<AsyncValue<List<ItemRequest>>> {
  /// See also [watchMyRequestForItem].
  const WatchMyRequestForItemFamily();

  /// See also [watchMyRequestForItem].
  WatchMyRequestForItemProvider call(
    String itemId,
    String requesterId,
  ) {
    return WatchMyRequestForItemProvider(
      itemId,
      requesterId,
    );
  }

  @override
  WatchMyRequestForItemProvider getProviderOverride(
    covariant WatchMyRequestForItemProvider provider,
  ) {
    return call(
      provider.itemId,
      provider.requesterId,
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
  String? get name => r'watchMyRequestForItemProvider';
}

/// See also [watchMyRequestForItem].
class WatchMyRequestForItemProvider
    extends AutoDisposeStreamProvider<List<ItemRequest>> {
  /// See also [watchMyRequestForItem].
  WatchMyRequestForItemProvider(
    String itemId,
    String requesterId,
  ) : this._internal(
          (ref) => watchMyRequestForItem(
            ref as WatchMyRequestForItemRef,
            itemId,
            requesterId,
          ),
          from: watchMyRequestForItemProvider,
          name: r'watchMyRequestForItemProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$watchMyRequestForItemHash,
          dependencies: WatchMyRequestForItemFamily._dependencies,
          allTransitiveDependencies:
              WatchMyRequestForItemFamily._allTransitiveDependencies,
          itemId: itemId,
          requesterId: requesterId,
        );

  WatchMyRequestForItemProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.itemId,
    required this.requesterId,
  }) : super.internal();

  final String itemId;
  final String requesterId;

  @override
  Override overrideWith(
    Stream<List<ItemRequest>> Function(WatchMyRequestForItemRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchMyRequestForItemProvider._internal(
        (ref) => create(ref as WatchMyRequestForItemRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        itemId: itemId,
        requesterId: requesterId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ItemRequest>> createElement() {
    return _WatchMyRequestForItemProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchMyRequestForItemProvider &&
        other.itemId == itemId &&
        other.requesterId == requesterId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, itemId.hashCode);
    hash = _SystemHash.combine(hash, requesterId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WatchMyRequestForItemRef
    on AutoDisposeStreamProviderRef<List<ItemRequest>> {
  /// The parameter `itemId` of this provider.
  String get itemId;

  /// The parameter `requesterId` of this provider.
  String get requesterId;
}

class _WatchMyRequestForItemProviderElement
    extends AutoDisposeStreamProviderElement<List<ItemRequest>>
    with WatchMyRequestForItemRef {
  _WatchMyRequestForItemProviderElement(super.provider);

  @override
  String get itemId => (origin as WatchMyRequestForItemProvider).itemId;
  @override
  String get requesterId =>
      (origin as WatchMyRequestForItemProvider).requesterId;
}

String _$watchSingleRequestHash() =>
    r'3ae7aff7fcdc7082668b667aec0d122edd372569';

/// See also [watchSingleRequest].
@ProviderFor(watchSingleRequest)
const watchSingleRequestProvider = WatchSingleRequestFamily();

/// See also [watchSingleRequest].
class WatchSingleRequestFamily extends Family<AsyncValue<ItemRequest?>> {
  /// See also [watchSingleRequest].
  const WatchSingleRequestFamily();

  /// See also [watchSingleRequest].
  WatchSingleRequestProvider call(
    String itemId,
    String requestId,
  ) {
    return WatchSingleRequestProvider(
      itemId,
      requestId,
    );
  }

  @override
  WatchSingleRequestProvider getProviderOverride(
    covariant WatchSingleRequestProvider provider,
  ) {
    return call(
      provider.itemId,
      provider.requestId,
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
  String? get name => r'watchSingleRequestProvider';
}

/// See also [watchSingleRequest].
class WatchSingleRequestProvider
    extends AutoDisposeStreamProvider<ItemRequest?> {
  /// See also [watchSingleRequest].
  WatchSingleRequestProvider(
    String itemId,
    String requestId,
  ) : this._internal(
          (ref) => watchSingleRequest(
            ref as WatchSingleRequestRef,
            itemId,
            requestId,
          ),
          from: watchSingleRequestProvider,
          name: r'watchSingleRequestProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$watchSingleRequestHash,
          dependencies: WatchSingleRequestFamily._dependencies,
          allTransitiveDependencies:
              WatchSingleRequestFamily._allTransitiveDependencies,
          itemId: itemId,
          requestId: requestId,
        );

  WatchSingleRequestProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.itemId,
    required this.requestId,
  }) : super.internal();

  final String itemId;
  final String requestId;

  @override
  Override overrideWith(
    Stream<ItemRequest?> Function(WatchSingleRequestRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchSingleRequestProvider._internal(
        (ref) => create(ref as WatchSingleRequestRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        itemId: itemId,
        requestId: requestId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<ItemRequest?> createElement() {
    return _WatchSingleRequestProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchSingleRequestProvider &&
        other.itemId == itemId &&
        other.requestId == requestId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, itemId.hashCode);
    hash = _SystemHash.combine(hash, requestId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WatchSingleRequestRef on AutoDisposeStreamProviderRef<ItemRequest?> {
  /// The parameter `itemId` of this provider.
  String get itemId;

  /// The parameter `requestId` of this provider.
  String get requestId;
}

class _WatchSingleRequestProviderElement
    extends AutoDisposeStreamProviderElement<ItemRequest?>
    with WatchSingleRequestRef {
  _WatchSingleRequestProviderElement(super.provider);

  @override
  String get itemId => (origin as WatchSingleRequestProvider).itemId;
  @override
  String get requestId => (origin as WatchSingleRequestProvider).requestId;
}

String _$itemDetailActionNotifierHash() =>
    r'5f2d860ad3837c91e8eef3d088bf3fb14b674e1a';

/// See also [ItemDetailActionNotifier].
@ProviderFor(ItemDetailActionNotifier)
final itemDetailActionNotifierProvider = AutoDisposeNotifierProvider<
    ItemDetailActionNotifier, AsyncValue<void>>.internal(
  ItemDetailActionNotifier.new,
  name: r'itemDetailActionNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$itemDetailActionNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ItemDetailActionNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
