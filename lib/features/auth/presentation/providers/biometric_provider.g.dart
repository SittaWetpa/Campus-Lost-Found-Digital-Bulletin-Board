// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometric_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$biometricDatasourceHash() =>
    r'ab9da60c7d8223928ca103ee5390e7b62f632379';

/// See also [biometricDatasource].
@ProviderFor(biometricDatasource)
final biometricDatasourceProvider =
    AutoDisposeProvider<BiometricLocalDatasource>.internal(
  biometricDatasource,
  name: r'biometricDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$biometricDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BiometricDatasourceRef
    = AutoDisposeProviderRef<BiometricLocalDatasource>;
String _$biometricRepositoryHash() =>
    r'5302b717dbc577572868f1518783f49fbfe6c4d1';

/// See also [biometricRepository].
@ProviderFor(biometricRepository)
final biometricRepositoryProvider =
    AutoDisposeProvider<BiometricRepository>.internal(
  biometricRepository,
  name: r'biometricRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$biometricRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BiometricRepositoryRef = AutoDisposeProviderRef<BiometricRepository>;
String _$biometricLockHash() => r'a626431acb8c1e53e5d6936f05d6011375bd85eb';

/// Lock state for the R1(b) resume guard. `true` means the app is locked and a
/// biometric / device-credential check is required before the UI is shown.
///
/// Copied from [BiometricLock].
@ProviderFor(BiometricLock)
final biometricLockProvider =
    AutoDisposeNotifierProvider<BiometricLock, bool>.internal(
  BiometricLock.new,
  name: r'biometricLockProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$biometricLockHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BiometricLock = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
