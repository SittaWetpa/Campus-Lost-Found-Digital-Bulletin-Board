// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$otpDatasourceHash() => r'2ee8ff349fad825cfd348f3300dd8383a2ce9e79';

/// See also [otpDatasource].
@ProviderFor(otpDatasource)
final otpDatasourceProvider = AutoDisposeProvider<OtpRemoteDatasource>.internal(
  otpDatasource,
  name: r'otpDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$otpDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef OtpDatasourceRef = AutoDisposeProviderRef<OtpRemoteDatasource>;
String _$otpRepositoryHash() => r'ef1d232282039aa2c64d1efc890064fe2bf33ffa';

/// See also [otpRepository].
@ProviderFor(otpRepository)
final otpRepositoryProvider = AutoDisposeProvider<OtpRepository>.internal(
  otpRepository,
  name: r'otpRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$otpRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef OtpRepositoryRef = AutoDisposeProviderRef<OtpRepository>;
String _$otpNotifierHash() => r'e0da5410f73f0bf577cb1f79e62905bc531b2b9f';

/// See also [OtpNotifier].
@ProviderFor(OtpNotifier)
final otpNotifierProvider =
    AutoDisposeNotifierProvider<OtpNotifier, AsyncValue<void>>.internal(
  OtpNotifier.new,
  name: r'otpNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$otpNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OtpNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
