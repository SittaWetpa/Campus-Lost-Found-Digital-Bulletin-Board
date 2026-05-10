// WBS 2.9 — FetchItemListingsUseCase unit tests.
//
// Verifies that the use case delegates faithfully to ExternalApiRepository
// and passes all query parameters through unchanged.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:campus_lost_found/features/feed/domain/entities/api_item_listing.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/external_api_repository.dart';
import 'package:campus_lost_found/features/feed/domain/usecases/fetch_item_listings_use_case.dart';

class _MockRepository extends Mock implements ExternalApiRepository {}

// ── helpers ───────────────────────────────────────────────────────────────────

ApiItemListing _fakeListing({
  String id = 'item-001',
  ItemCategory category = ItemCategory.seeker,
}) =>
    ApiItemListing(
      id: id,
      title: 'Test item',
      category: category,
      status: ItemStatus.active,
      description: 'desc',
      location: 'Library',
      contact: '0800000000',
      imageUrls: const [],
      isSensitive: false,
      createdAt: DateTime(2024),
      occurredAt: DateTime(2024),
    );

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockRepository mockRepository;
  late FetchItemListingsUseCase sut;

  setUp(() {
    mockRepository = _MockRepository();
    sut = FetchItemListingsUseCase(mockRepository);
  });

  group('FetchItemListingsUseCase — WBS 2.9', () {
    test('returns items from repository with default parameters', () async {
      final items = [_fakeListing(), _fakeListing(id: 'item-002')];
      when(() => mockRepository.fetchItems(
            category: null,
            keyword: null,
            limit: 20,
          )).thenAnswer((_) async => items);

      final result = await sut.call();

      expect(result, items);
    });

    test('passes category=founder to repository', () async {
      final items = [_fakeListing(category: ItemCategory.founder)];
      when(() => mockRepository.fetchItems(
            category: ItemCategory.founder,
            keyword: null,
            limit: 20,
          )).thenAnswer((_) async => items);

      final result = await sut.call(category: ItemCategory.founder);

      expect(result.first.category, ItemCategory.founder);
      verify(() => mockRepository.fetchItems(
            category: ItemCategory.founder,
            keyword: null,
            limit: 20,
          )).called(1);
    });

    test('passes keyword to repository', () async {
      when(() => mockRepository.fetchItems(
            category: null,
            keyword: 'wallet',
            limit: 20,
          )).thenAnswer((_) async => [_fakeListing()]);

      await sut.call(keyword: 'wallet');

      verify(() => mockRepository.fetchItems(
            category: null,
            keyword: 'wallet',
            limit: 20,
          )).called(1);
    });

    test('passes custom limit to repository', () async {
      when(() => mockRepository.fetchItems(
            category: null,
            keyword: null,
            limit: 5,
          )).thenAnswer((_) async => []);

      await sut.call(limit: 5);

      verify(() => mockRepository.fetchItems(
            category: null,
            keyword: null,
            limit: 5,
          )).called(1);
    });

    test('returns empty list when repository returns empty', () async {
      when(() => mockRepository.fetchItems(
            category: null,
            keyword: null,
            limit: 20,
          )).thenAnswer((_) async => []);

      final result = await sut.call();

      expect(result, isEmpty);
    });

    test('propagates exception from repository without swallowing it', () {
      when(() => mockRepository.fetchItems(
            category: null,
            keyword: null,
            limit: 20,
          )).thenThrow(Exception('upstream error'));

      expect(() => sut.call(), throwsException);
    });
  });
}
