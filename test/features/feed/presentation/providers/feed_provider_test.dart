// WBS 4.2 — feedItemsProvider unit test.
// Verifies that the provider's emitted state matches the stream supplied by
// an overridden fake ItemRepository, and that FeedFilter / taxonomy / search
// transforms are applied on top of that stream.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';

class _FakeItemRepository implements ItemRepository {
  _FakeItemRepository(this._controller);

  final StreamController<List<Item>> _controller;

  @override
  Stream<List<Item>> watchFeed() => _controller.stream;

  @override
  Stream<Item?> watchItem(String itemId) => const Stream.empty();

  @override
  Future<Item?> getItemById(String itemId) async => null;

  @override
  Future<List<Item>> searchItems(String keyword) async => const [];

  @override
  Future<List<Item>> getRecentInCategory({
    required String categoryId,
    int limit = 5,
  }) async => const [];

  @override
  Stream<List<Item>> watchMyItems(String userId) => const Stream.empty();

  @override
  Future<String?> getItemSecretAnswer(String itemId) async => null;
}

Item _item({
  required String id,
  required ItemCategory category,
  ItemTaxonomy? taxonomy,
  String title = 'Title',
}) {
  return Item(
    id: id,
    title: title,
    description: 'desc',
    category: category,
    status: ItemStatus.active,
    location: 'loc',
    contact: 'contact',
    imageUrls: const [],
    userId: 'u',
    createdAt: DateTime(2026, 1, 1),
    itemTaxonomy: taxonomy,
  );
}

void main() {
  group('feedItemsProvider', () {
    test('emits the same list that the fake repository stream emits', () async {
      final controller = StreamController<List<Item>>();
      final container = ProviderContainer(overrides: [
        itemRepositoryProvider.overrideWith((_) => _FakeItemRepository(controller)),
      ]);
      addTearDown(container.dispose);
      addTearDown(controller.close);

      final items = [
        _item(id: 'a', category: ItemCategory.founder),
        _item(id: 'b', category: ItemCategory.seeker),
      ];

      final sub = container.listen(feedItemsProvider, (_, __) {});
      controller.add(items);
      await Future<void>.delayed(Duration.zero);

      final state = sub.read();
      expect(state.hasValue, isTrue);
      expect(state.value!.map((i) => i.id), ['a', 'b']);
    });

    test('applies FeedFilter.found and search query on top of repo stream',
        () async {
      final controller = StreamController<List<Item>>();
      final container = ProviderContainer(overrides: [
        itemRepositoryProvider.overrideWith((_) => _FakeItemRepository(controller)),
      ]);
      addTearDown(container.dispose);
      addTearDown(controller.close);

      container.read(feedFilterNotifierProvider.notifier).select(FeedFilter.found);
      container.read(searchQueryNotifierProvider.notifier).update('wallet');

      final sub = container.listen(feedItemsProvider, (_, __) {});
      controller.add([
        _item(id: 'a', category: ItemCategory.founder, title: 'Found wallet'),
        _item(id: 'b', category: ItemCategory.founder, title: 'Found phone'),
        _item(id: 'c', category: ItemCategory.seeker, title: 'Lost wallet'),
      ]);
      await Future<void>.delayed(Duration.zero);

      final state = sub.read();
      expect(state.value!.map((i) => i.id), ['a']);
    });
  });
}
