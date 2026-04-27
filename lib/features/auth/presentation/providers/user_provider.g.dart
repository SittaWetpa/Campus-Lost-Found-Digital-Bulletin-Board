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
String _$userRepositoryHash() => r'59b1c71fca47ffec56376199eb28a4ed84a09f7c';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
