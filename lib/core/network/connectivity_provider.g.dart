// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectivityStatusHash() =>
    r'0fd4b0db05bdffa0319e09c0b2ff6057b62f1cfc';

/// See also [connectivityStatus].
@ProviderFor(connectivityStatus)
final connectivityStatusProvider =
    AutoDisposeStreamProvider<ConnectivityStatus>.internal(
  connectivityStatus,
  name: r'connectivityStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectivityStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ConnectivityStatusRef
    = AutoDisposeStreamProviderRef<ConnectivityStatus>;
String _$isOfflineHash() => r'830e47e4dd00b052bb98570c737af35c083a445e';

/// See also [isOffline].
@ProviderFor(isOffline)
final isOfflineProvider = AutoDisposeProvider<bool>.internal(
  isOffline,
  name: r'isOfflineProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isOfflineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsOfflineRef = AutoDisposeProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
