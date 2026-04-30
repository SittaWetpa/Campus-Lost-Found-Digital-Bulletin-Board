import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_provider.dart';
import 'package:campus_lost_found/features/post/data/datasources/post_remote_datasource.dart';
import 'package:campus_lost_found/features/post/data/repositories/post_repository_impl.dart';
import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';
import 'package:campus_lost_found/features/post/domain/usecases/create_item_use_case.dart';
import 'package:campus_lost_found/features/post/domain/usecases/get_similar_founder_posts_use_case.dart';

part 'post_providers.g.dart';

@riverpod
PostRemoteDatasource postRemoteDatasource(PostRemoteDatasourceRef ref) =>
    PostRemoteDatasourceImpl(FirebaseFirestore.instance);

@riverpod
PostRepository postRepository(PostRepositoryRef ref) =>
    PostRepositoryImpl(ref.watch(postRemoteDatasourceProvider));

@riverpod
class PostFormNotifier extends _$PostFormNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> create(Item item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await CreateItemUseCase(ref.read(postRepositoryProvider)).call(item);
    });
  }

  Future<void> update(Item item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(postRepositoryProvider).updateItem(item);
    });
  }
}

@riverpod
class SimilarPostsNotifier extends _$SimilarPostsNotifier {
  Timer? _debounce;

  @override
  AsyncValue<List<Item>> build() {
    ref.onDispose(() => _debounce?.cancel());
    return const AsyncData([]);
  }

  void search(String title) {
    _debounce?.cancel();
    final trimmed = title.trim();
    if (trimmed.length < 3) {
      state = const AsyncData([]);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(
        () => GetSimilarFounderPostsUseCase(ref.read(itemRepositoryProvider))
            .call(trimmed),
      );
    });
  }

  void clear() {
    _debounce?.cancel();
    state = const AsyncData([]);
  }
}
