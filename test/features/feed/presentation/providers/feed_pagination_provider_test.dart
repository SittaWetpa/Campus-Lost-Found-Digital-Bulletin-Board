// R5(d) — feed pagination view-models: FeedPagination / MyItemsPagination
// load-more behaviour + mergeFeedPages dedup/ordering.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/core/constants/app_constants.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_page_repository.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_pagination_provider.dart';

Item _item(String id, {int minute = 0}) => Item(
      id: id,
      title: 'Item $id',
      description: 'desc',
      category: ItemCategory.seeker,
      status: ItemStatus.active,
      location: 'loc',
      contact: '0800000000',
      imageUrls: const [],
      userId: 'uid',
      createdAt: DateTime(2026, 1, 1).add(Duration(minutes: minute)),
      occurredAt: DateTime(2026, 1, 1),
    );

class _FakePageRepo implements ItemPageRepository {
  _FakePageRepo(this.feedPages, {this.myPages = const []});
  final List<List<Item>> feedPages; // returned per successive call
  final List<List<Item>> myPages;
  int feedCalls = 0;
  int myCalls = 0;
  DateTime? lastFeedCursor;

  @override
  Future<List<Item>> fetchFeedPage({
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  }) async {
    lastFeedCursor = startAfterCreatedAt;
    return feedCalls < feedPages.length ? feedPages[feedCalls++] : const [];
  }

  @override
  Future<List<Item>> fetchMyItemsPage({
    required String userId,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  }) async {
    return myCalls < myPages.length ? myPages[myCalls++] : const [];
  }
}

ProviderContainer _container(_FakePageRepo repo) {
  final c = ProviderContainer(
    overrides: [itemPageRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('mergeFeedPages — R5(d)', () {
    test('de-duplicates by id and sorts createdAt descending', () {
      final head = [_item('a', minute: 3), _item('b', minute: 2)];
      final older = [_item('b', minute: 2), _item('c', minute: 1)];

      final merged = mergeFeedPages(head, older);

      expect(merged.map((i) => i.id), equals(['a', 'b', 'c']));
    });
  });

  group('FeedPagination — R5(d)', () {
    test('loadMore appends the fetched page and forwards the cursor', () async {
      final repo = _FakePageRepo([
        [_item('x', minute: 5), _item('y', minute: 4)],
      ]);
      final c = _container(repo);

      final cursor = DateTime(2026, 1, 1, 0, 6);
      await c.read(feedPaginationProvider.notifier).loadMore(cursor);

      expect(c.read(feedPaginationProvider).items.map((i) => i.id),
          equals(['x', 'y']));
      expect(repo.lastFeedCursor, equals(cursor));
    });

    test('a short page marks reachedEnd and blocks further loads', () async {
      final repo = _FakePageRepo([
        [_item('x', minute: 5)], // < feedPageSize
        [_item('z', minute: 1)], // must never be requested
      ]);
      final c = _container(repo);

      await c.read(feedPaginationProvider.notifier).loadMore(DateTime(2026));
      expect(c.read(feedPaginationProvider).reachedEnd, isTrue);

      await c.read(feedPaginationProvider.notifier).loadMore(DateTime(2026));
      expect(repo.feedCalls, equals(1)); // second call short-circuited
      expect(c.read(feedPaginationProvider).items.map((i) => i.id),
          equals(['x']));
    });

    test('duplicate ids across pages are not appended twice', () async {
      // A full first page keeps reachedEnd false so a second load runs.
      final fullPage = List.generate(
        AppConstants.feedPageSize,
        (i) => _item('p$i', minute: 1000 - i),
      );
      final repo = _FakePageRepo([
        fullPage,
        [fullPage.last, _item('w', minute: 1)], // overlaps last + one new
      ]);
      final c = _container(repo);

      await c.read(feedPaginationProvider.notifier).loadMore(DateTime(2026));
      await c.read(feedPaginationProvider.notifier).loadMore(DateTime(2026));

      final ids = c.read(feedPaginationProvider).items.map((i) => i.id).toList();
      expect(ids.length, equals(AppConstants.feedPageSize + 1)); // only 'w' added
      expect(ids.contains('w'), isTrue);
      expect(ids.where((id) => id == fullPage.last.id).length, equals(1));
    });
  });

  group('MyItemsPagination — R5(d)', () {
    test('loadMore appends the fetched page for the user', () async {
      final repo = _FakePageRepo([], myPages: [
        [_item('m1', minute: 2)],
      ]);
      final c = _container(repo);

      await c
          .read(myItemsPaginationProvider('uid-1').notifier)
          .loadMore(DateTime(2026));

      expect(c.read(myItemsPaginationProvider('uid-1')).items.map((i) => i.id),
          equals(['m1']));
    });
  });
}
