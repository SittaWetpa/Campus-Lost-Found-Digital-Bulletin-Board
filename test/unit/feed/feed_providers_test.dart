// WBS 1.2 — Feed providers unit tests (filter + feed items)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';

// ── fakes ─────────────────────────────────────────────────────────────────────

class _FakeItemRepository implements ItemRepository {
  final List<Item> items;
  const _FakeItemRepository(this.items);

  @override
  Stream<List<Item>> watchFeed() => Stream.value(items);

  @override
  Stream<Item?> watchItem(String id) => Stream.value(null);

  @override
  Future<Item?> getItemById(String id) async => null;

  @override
  Future<List<Item>> searchItems(String keyword) async => [];

  @override
  Future<List<Item>> getSimilarFounderPosts(String keyword) async => [];

  @override
  Stream<List<Item>> watchMyItems(String userId) => Stream.value([]);

  @override
  Future<String?> getItemSecretAnswer(String itemId) async => null;
}

// ── helpers ───────────────────────────────────────────────────────────────────

Item _makeItem({required String id, required ItemCategory category}) => Item(
      id: id,
      title: 'Item $id',
      description: 'Desc',
      category: category,
      status: ItemStatus.active,
      location: 'Location',
      contact: '0800000000',
      imageUrls: const [],
      userId: 'uid',
      createdAt: DateTime(2025),
      occurredAt: DateTime(2025),
    );

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── FeedFilterNotifier ─────────────────────────────────────────────────────

  group('FeedFilterNotifier — WBS 1.2', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('initial state is FeedFilter.all', () {
      expect(container.read(feedFilterNotifierProvider), FeedFilter.all);
    });

    test('select(found) updates state to FeedFilter.found', () {
      container.read(feedFilterNotifierProvider.notifier).select(FeedFilter.found);
      expect(container.read(feedFilterNotifierProvider), FeedFilter.found);
    });

    test('select(lost) updates state to FeedFilter.lost', () {
      container.read(feedFilterNotifierProvider.notifier).select(FeedFilter.lost);
      expect(container.read(feedFilterNotifierProvider), FeedFilter.lost);
    });

    test('select(all) resets state back to FeedFilter.all', () {
      container.read(feedFilterNotifierProvider.notifier).select(FeedFilter.found);
      container.read(feedFilterNotifierProvider.notifier).select(FeedFilter.all);
      expect(container.read(feedFilterNotifierProvider), FeedFilter.all);
    });
  });

  // ── feedItemsProvider ──────────────────────────────────────────────────────

  group('feedItemsProvider — WBS 1.2', () {
    final founder = _makeItem(id: 'f1', category: ItemCategory.founder);
    final seeker  = _makeItem(id: 's1', category: ItemCategory.seeker);

    ProviderContainer makeContainer([List<Item>? items]) => ProviderContainer(
          overrides: [
            itemRepositoryProvider.overrideWith(
              (_) => _FakeItemRepository(items ?? [founder, seeker]),
            ),
          ],
        );

    test('FeedFilter.all emits all items', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      final items = await c.read(feedItemsProvider.future);
      expect(items, hasLength(2));
    });

    test('FeedFilter.found emits only ItemCategory.founder items', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      c.read(feedFilterNotifierProvider.notifier).select(FeedFilter.found);
      final items = await c.read(feedItemsProvider.future);

      expect(items, hasLength(1));
      expect(items.first.id, 'f1');
      expect(items.first.category, ItemCategory.founder);
    });

    test('FeedFilter.lost emits only ItemCategory.seeker items', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      c.read(feedFilterNotifierProvider.notifier).select(FeedFilter.lost);
      final items = await c.read(feedItemsProvider.future);

      expect(items, hasLength(1));
      expect(items.first.id, 's1');
      expect(items.first.category, ItemCategory.seeker);
    });

    test('FeedFilter.found returns empty list when no founder items exist', () async {
      final c = makeContainer([seeker]);
      addTearDown(c.dispose);

      c.read(feedFilterNotifierProvider.notifier).select(FeedFilter.found);
      final items = await c.read(feedItemsProvider.future);
      expect(items, isEmpty);
    });

    test('FeedFilter.lost returns empty list when no seeker items exist', () async {
      final c = makeContainer([founder]);
      addTearDown(c.dispose);

      c.read(feedFilterNotifierProvider.notifier).select(FeedFilter.lost);
      final items = await c.read(feedItemsProvider.future);
      expect(items, isEmpty);
    });

    test('empty repository emits empty list for every filter', () async {
      for (final filter in FeedFilter.values) {
        final c = makeContainer([]);
        addTearDown(c.dispose);

        c.read(feedFilterNotifierProvider.notifier).select(filter);
        final items = await c.read(feedItemsProvider.future);
        expect(items, isEmpty, reason: 'filter=$filter should produce empty list');
      }
    });
  });
}
