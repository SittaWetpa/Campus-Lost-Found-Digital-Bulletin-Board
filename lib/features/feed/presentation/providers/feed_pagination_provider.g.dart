// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_pagination_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$itemPageRepositoryHash() =>
    r'3bd918351e0c290823b457b71e2c638466b2d4b4';

/// R5(d) — startAfter paging. Constructed independently of [itemRepositoryProvider]
/// so test fakes that override the live repo do not need to also implement
/// [ItemPageRepository].
///
/// Copied from [itemPageRepository].
@ProviderFor(itemPageRepository)
final itemPageRepositoryProvider =
    AutoDisposeProvider<ItemPageRepository>.internal(
  itemPageRepository,
  name: r'itemPageRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$itemPageRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ItemPageRepositoryRef = AutoDisposeProviderRef<ItemPageRepository>;
String _$feedPaginationHash() => r'206d4c641d200d06657019ab72ae91f99faa79aa';

/// Older feed pages appended below the live first page (R5(d)).
///
/// [loadMore] takes the createdAt of the last currently-shown item as the
/// startAfter cursor. Duplicates against the live head are removed by
/// [mergeFeedPages] downstream, so this notifier need not hold the head.
///
/// Copied from [FeedPagination].
@ProviderFor(FeedPagination)
final feedPaginationProvider =
    AutoDisposeNotifierProvider<FeedPagination, PagedItems>.internal(
  FeedPagination.new,
  name: r'feedPaginationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedPaginationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FeedPagination = AutoDisposeNotifier<PagedItems>;
String _$myItemsPaginationHash() => r'0b327a300901a9bed16d656c0b3f81e4e8e8f78e';

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

abstract class _$MyItemsPagination
    extends BuildlessAutoDisposeNotifier<PagedItems> {
  late final String userId;

  PagedItems build(
    String userId,
  );
}

/// Older My-Posts pages appended below the live first page (R5(d)).
///
/// Copied from [MyItemsPagination].
@ProviderFor(MyItemsPagination)
const myItemsPaginationProvider = MyItemsPaginationFamily();

/// Older My-Posts pages appended below the live first page (R5(d)).
///
/// Copied from [MyItemsPagination].
class MyItemsPaginationFamily extends Family<PagedItems> {
  /// Older My-Posts pages appended below the live first page (R5(d)).
  ///
  /// Copied from [MyItemsPagination].
  const MyItemsPaginationFamily();

  /// Older My-Posts pages appended below the live first page (R5(d)).
  ///
  /// Copied from [MyItemsPagination].
  MyItemsPaginationProvider call(
    String userId,
  ) {
    return MyItemsPaginationProvider(
      userId,
    );
  }

  @override
  MyItemsPaginationProvider getProviderOverride(
    covariant MyItemsPaginationProvider provider,
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
  String? get name => r'myItemsPaginationProvider';
}

/// Older My-Posts pages appended below the live first page (R5(d)).
///
/// Copied from [MyItemsPagination].
class MyItemsPaginationProvider
    extends AutoDisposeNotifierProviderImpl<MyItemsPagination, PagedItems> {
  /// Older My-Posts pages appended below the live first page (R5(d)).
  ///
  /// Copied from [MyItemsPagination].
  MyItemsPaginationProvider(
    String userId,
  ) : this._internal(
          () => MyItemsPagination()..userId = userId,
          from: myItemsPaginationProvider,
          name: r'myItemsPaginationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$myItemsPaginationHash,
          dependencies: MyItemsPaginationFamily._dependencies,
          allTransitiveDependencies:
              MyItemsPaginationFamily._allTransitiveDependencies,
          userId: userId,
        );

  MyItemsPaginationProvider._internal(
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
  PagedItems runNotifierBuild(
    covariant MyItemsPagination notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(MyItemsPagination Function() create) {
    return ProviderOverride(
      origin: this,
      override: MyItemsPaginationProvider._internal(
        () => create()..userId = userId,
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
  AutoDisposeNotifierProviderElement<MyItemsPagination, PagedItems>
      createElement() {
    return _MyItemsPaginationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MyItemsPaginationProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MyItemsPaginationRef on AutoDisposeNotifierProviderRef<PagedItems> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _MyItemsPaginationProviderElement
    extends AutoDisposeNotifierProviderElement<MyItemsPagination, PagedItems>
    with MyItemsPaginationRef {
  _MyItemsPaginationProviderElement(super.provider);

  @override
  String get userId => (origin as MyItemsPaginationProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
