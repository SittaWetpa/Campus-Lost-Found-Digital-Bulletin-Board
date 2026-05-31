import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:campus_lost_found/core/constants/app_constants.dart';
import 'package:campus_lost_found/core/services/sync_metadata_datasource.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_local_datasource.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_remote_datasource.dart';
import 'package:campus_lost_found/features/feed/data/repositories/item_repository_impl.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_page_repository.dart';

part 'feed_pagination_provider.g.dart';

/// R5(d) — startAfter paging. Constructed independently of [itemRepositoryProvider]
/// so test fakes that override the live repo do not need to also implement
/// [ItemPageRepository].
@riverpod
ItemPageRepository itemPageRepository(ItemPageRepositoryRef ref) {
  return ItemRepositoryImpl(
    FirestoreItemDatasource(FirebaseFirestore.instance),
    HiveItemLocalDatasource(Hive.box<Map>('items_box')),
    ref.watch(syncMetadataProvider),
  );
}

/// Accumulated "load more" pages plus paging flags (R5(d)).
class PagedItems {
  final List<Item> items;
  final bool isLoadingMore;
  final bool reachedEnd;

  const PagedItems({
    this.items = const [],
    this.isLoadingMore = false,
    this.reachedEnd = false,
  });

  PagedItems copyWith({
    List<Item>? items,
    bool? isLoadingMore,
    bool? reachedEnd,
  }) =>
      PagedItems(
        items: items ?? this.items,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        reachedEnd: reachedEnd ?? this.reachedEnd,
      );
}

/// Older feed pages appended below the live first page (R5(d)).
///
/// [loadMore] takes the createdAt of the last currently-shown item as the
/// startAfter cursor. Duplicates against the live head are removed by
/// [mergeFeedPages] downstream, so this notifier need not hold the head.
@riverpod
class FeedPagination extends _$FeedPagination {
  @override
  PagedItems build() => const PagedItems();

  Future<void> loadMore(DateTime startAfterCreatedAt) async {
    if (state.isLoadingMore || state.reachedEnd) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await ref
          .read(itemPageRepositoryProvider)
          .fetchFeedPage(startAfterCreatedAt: startAfterCreatedAt);
      final seen = {for (final i in state.items) i.id};
      final fresh = page.where((i) => !seen.contains(i.id)).toList();
      state = state.copyWith(
        items: [...state.items, ...fresh],
        isLoadingMore: false,
        reachedEnd: page.length < AppConstants.feedPageSize,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

/// Older My-Posts pages appended below the live first page (R5(d)).
@riverpod
class MyItemsPagination extends _$MyItemsPagination {
  @override
  PagedItems build(String userId) => const PagedItems();

  Future<void> loadMore(DateTime startAfterCreatedAt) async {
    if (state.isLoadingMore || state.reachedEnd) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await ref.read(itemPageRepositoryProvider).fetchMyItemsPage(
            userId: userId,
            startAfterCreatedAt: startAfterCreatedAt,
          );
      final seen = {for (final i in state.items) i.id};
      final fresh = page.where((i) => !seen.contains(i.id)).toList();
      state = state.copyWith(
        items: [...state.items, ...fresh],
        isLoadingMore: false,
        reachedEnd: page.length < AppConstants.feedPageSize,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

/// Merges the live first page with accumulated older pages, de-duplicating by
/// id and keeping createdAt-descending order (R5(d)).
List<Item> mergeFeedPages(List<Item> head, List<Item> older) {
  final seen = <String>{};
  final merged = <Item>[];
  for (final item in [...head, ...older]) {
    if (seen.add(item.id)) merged.add(item);
  }
  merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return merged;
}
