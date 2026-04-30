// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postRemoteDatasourceHash() =>
    r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';

/// See also [postRemoteDatasource].
@ProviderFor(postRemoteDatasource)
final postRemoteDatasourceProvider =
    AutoDisposeProvider<PostRemoteDatasource>.internal(
  postRemoteDatasource,
  name: r'postRemoteDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postRemoteDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PostRemoteDatasourceRef = AutoDisposeProviderRef<PostRemoteDatasource>;
String _$postRepositoryHash() => r'b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0';

/// See also [postRepository].
@ProviderFor(postRepository)
final postRepositoryProvider =
    AutoDisposeProvider<PostRepository>.internal(
  postRepository,
  name: r'postRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PostRepositoryRef = AutoDisposeProviderRef<PostRepository>;
String _$postFormNotifierHash() =>
    r'c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0';

/// See also [PostFormNotifier].
@ProviderFor(PostFormNotifier)
final postFormNotifierProvider =
    AutoDisposeNotifierProvider<PostFormNotifier, AsyncValue<void>>.internal(
  PostFormNotifier.new,
  name: r'postFormNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postFormNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PostFormNotifier = AutoDisposeNotifier<AsyncValue<void>>;
String _$similarPostsNotifierHash() =>
    r'd1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0';

/// See also [SimilarPostsNotifier].
@ProviderFor(SimilarPostsNotifier)
final similarPostsNotifierProvider = AutoDisposeNotifierProvider<
    SimilarPostsNotifier, AsyncValue<List<Item>>>.internal(
  SimilarPostsNotifier.new,
  name: r'similarPostsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$similarPostsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SimilarPostsNotifier = AutoDisposeNotifier<AsyncValue<List<Item>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
