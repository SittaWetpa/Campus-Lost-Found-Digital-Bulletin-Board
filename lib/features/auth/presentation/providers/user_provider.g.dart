// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userDatasourceHash() => r'b147a90ce325e5f51a8d9e8c401a1550d082ce8c';

/// See also [userDatasource].
@ProviderFor(userDatasource)
final userDatasourceProvider =
    AutoDisposeProvider<UserRemoteDatasource>.internal(
  userDatasource,
  name: r'userDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserDatasourceRef = AutoDisposeProviderRef<UserRemoteDatasource>;
String _$userLocalDatasourceHash() =>
    r'4979508096bb9f3ef48cf8909f89ef0b7b25ebeb';

/// See also [userLocalDatasource].
@ProviderFor(userLocalDatasource)
final userLocalDatasourceProvider =
    AutoDisposeProvider<UserLocalDatasource>.internal(
  userLocalDatasource,
  name: r'userLocalDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userLocalDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserLocalDatasourceRef = AutoDisposeProviderRef<UserLocalDatasource>;
String _$userRepositoryHash() => r'c2ffcc70c6d0c0cb48e8a6290bcbc45ccee7ba74';

/// See also [userRepository].
@ProviderFor(userRepository)
final userRepositoryProvider = AutoDisposeProvider<UserRepository>.internal(
  userRepository,
  name: r'userRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserRepositoryRef = AutoDisposeProviderRef<UserRepository>;
String _$currentUserHash() => r'59db311224483e528a45489d34290bfd0548eed6';

/// See also [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeStreamProvider<User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentUserRef = AutoDisposeStreamProviderRef<User?>;
String _$getUserByIdHash() => r'a62126074de1fa3277f7d6081acd34d1df2bac41';

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

/// See also [getUserById].
@ProviderFor(getUserById)
const getUserByIdProvider = GetUserByIdFamily();

/// See also [getUserById].
class GetUserByIdFamily extends Family<AsyncValue<User?>> {
  /// See also [getUserById].
  const GetUserByIdFamily();

  /// See also [getUserById].
  GetUserByIdProvider call(
    String uid,
  ) {
    return GetUserByIdProvider(
      uid,
    );
  }

  @override
  GetUserByIdProvider getProviderOverride(
    covariant GetUserByIdProvider provider,
  ) {
    return call(
      provider.uid,
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
  String? get name => r'getUserByIdProvider';
}

/// See also [getUserById].
class GetUserByIdProvider extends AutoDisposeFutureProvider<User?> {
  /// See also [getUserById].
  GetUserByIdProvider(
    String uid,
  ) : this._internal(
          (ref) => getUserById(
            ref as GetUserByIdRef,
            uid,
          ),
          from: getUserByIdProvider,
          name: r'getUserByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getUserByIdHash,
          dependencies: GetUserByIdFamily._dependencies,
          allTransitiveDependencies:
              GetUserByIdFamily._allTransitiveDependencies,
          uid: uid,
        );

  GetUserByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.uid,
  }) : super.internal();

  final String uid;

  @override
  Override overrideWith(
    FutureOr<User?> Function(GetUserByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetUserByIdProvider._internal(
        (ref) => create(ref as GetUserByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        uid: uid,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<User?> createElement() {
    return _GetUserByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetUserByIdProvider && other.uid == uid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GetUserByIdRef on AutoDisposeFutureProviderRef<User?> {
  /// The parameter `uid` of this provider.
  String get uid;
}

class _GetUserByIdProviderElement
    extends AutoDisposeFutureProviderElement<User?> with GetUserByIdRef {
  _GetUserByIdProviderElement(super.provider);

  @override
  String get uid => (origin as GetUserByIdProvider).uid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
