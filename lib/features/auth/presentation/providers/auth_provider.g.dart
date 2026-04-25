// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authDatasourceHash() => r'e178851d50ad84289cc682f49f0cfa1f86e0929d';

/// See also [authDatasource].
@ProviderFor(authDatasource)
final authDatasourceProvider =
    AutoDisposeProvider<AuthRemoteDatasource>.internal(
  authDatasource,
  name: r'authDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AuthDatasourceRef = AutoDisposeProviderRef<AuthRemoteDatasource>;
String _$authRepositoryHash() => r'7cf9142352cad31969f4876085e8844c468f1879';

/// See also [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = AutoDisposeProvider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AuthRepositoryRef = AutoDisposeProviderRef<AuthRepository>;
String _$authStateHash() => r'9fbda1359f06380dfb4f0d0154ff81e13acb7474';

/// See also [authState].
@ProviderFor(authState)
final authStateProvider = AutoDisposeStreamProvider<AuthUser?>.internal(
  authState,
  name: r'authStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AuthStateRef = AutoDisposeStreamProviderRef<AuthUser?>;
String _$loginNotifierHash() => r'9ec29edee4ae8d7babc5bcbe09b8d565c3b00968';

/// See also [LoginNotifier].
@ProviderFor(LoginNotifier)
final loginNotifierProvider =
    AutoDisposeNotifierProvider<LoginNotifier, AsyncValue<void>>.internal(
  LoginNotifier.new,
  name: r'loginNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$loginNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LoginNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
