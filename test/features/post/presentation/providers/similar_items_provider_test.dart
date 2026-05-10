// WBS 2.8 — SimilarItemsNotifier provider tests.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/post/presentation/providers/similar_items_provider.dart';

class MockItemRepository extends Mock implements ItemRepository {}

void main() {
  late MockItemRepository mockRepo;

  setUp(() {
    mockRepo = MockItemRepository();
    registerFallbackValue(ItemTaxonomy.other);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  }

  group('SimilarItemsNotifier — WBS 2.8', () {
    test('initial state is AsyncData with empty list', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(similarItemsNotifierProvider);

      expect(state, equals(const AsyncData<List<Item>>([])));
    });

    test('load() calls getRecentInCategory with the correct categoryId',
        () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      when(() => mockRepo.getRecentInCategory(
            categoryId: any(named: 'categoryId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => []);

      await container
          .read(similarItemsNotifierProvider.notifier)
          .load(ItemTaxonomy.electronics);

      verify(() => mockRepo.getRecentInCategory(
            categoryId: 'electronics',
            limit: any(named: 'limit'),
          )).called(1);
    });

    test('clear() resets state to AsyncData with empty list', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      when(() => mockRepo.getRecentInCategory(
            categoryId: any(named: 'categoryId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => []);

      await container
          .read(similarItemsNotifierProvider.notifier)
          .load(ItemTaxonomy.electronics);

      container.read(similarItemsNotifierProvider.notifier).clear();

      expect(
        container.read(similarItemsNotifierProvider),
        equals(const AsyncData<List<Item>>([])),
      );
    });

    test('load() returns items from repository', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final fakeItem = Item(
        id: 'item-1',
        title: 'Found iPhone',
        description: '',
        category: ItemCategory.founder,
        status: ItemStatus.active,
        location: 'Library',
        contact: '0812345678',
        imageUrls: const [],
        userId: 'user-1',
        createdAt: DateTime(2026, 5, 1),
        occurredAt: DateTime(2026, 5, 1),
        itemTaxonomy: ItemTaxonomy.electronics,
      );

      when(() => mockRepo.getRecentInCategory(
            categoryId: 'electronics',
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [fakeItem]);

      await container
          .read(similarItemsNotifierProvider.notifier)
          .load(ItemTaxonomy.electronics);

      final state = container.read(similarItemsNotifierProvider);
      expect(state.value, equals([fakeItem]));
    });
  });
}
