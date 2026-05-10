// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$storageRepositoryHash() => r'5917769b1a1e3e026cb7224c6e860ba6e5a8e02a';

/// See also [storageRepository].
@ProviderFor(storageRepository)
final storageRepositoryProvider =
    AutoDisposeProvider<StorageRepository>.internal(
  storageRepository,
  name: r'storageRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$storageRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StorageRepositoryRef = AutoDisposeProviderRef<StorageRepository>;
String _$uploadPostPhotosUseCaseHash() =>
    r'0b1927f4115a67dfcda80a08960868b866fb38b1';

/// See also [uploadPostPhotosUseCase].
@ProviderFor(uploadPostPhotosUseCase)
final uploadPostPhotosUseCaseProvider =
    AutoDisposeProvider<UploadPostPhotosUseCase>.internal(
  uploadPostPhotosUseCase,
  name: r'uploadPostPhotosUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$uploadPostPhotosUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UploadPostPhotosUseCaseRef
    = AutoDisposeProviderRef<UploadPostPhotosUseCase>;
String _$postFormNotifierHash() => r'36ad9561c3932b9c87b63f2573826f0df160d186';

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
    r'd3dc6d03fed896d916e80973837cf6abe9d82c5b';

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
