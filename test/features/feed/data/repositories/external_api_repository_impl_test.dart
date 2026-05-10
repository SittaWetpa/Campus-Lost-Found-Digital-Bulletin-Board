// WBS 2.9 — ExternalApiRepositoryImpl unit tests.
//
// Verifies: entity mapping from datasource models, query parameter forwarding,
// and ApiException → ServerFailure translation for all HTTP error codes.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/feed/data/datasources/http_item_datasource.dart';
import 'package:campus_lost_found/features/feed/data/models/api_item_listing_model.dart';
import 'package:campus_lost_found/features/feed/data/repositories/external_api_repository_impl.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

class _MockDatasource extends Mock implements HttpItemDatasource {}

// ── helpers ───────────────────────────────────────────────────────────────────

ApiItemListingModel _fakeModel({
  String id = 'item-001',
  String category = 'seeker',
  bool isSensitive = false,
}) =>
    ApiItemListingModel(
      id: id,
      title: 'Test item',
      category: category,
      status: 'active',
      description: isSensitive ? '' : 'desc',
      location: 'Library',
      contact: isSensitive ? '' : '0800000000',
      imageUrls: isSensitive ? const [] : const ['https://example.com/img.jpg'],
      isSensitive: isSensitive,
      createdAt: DateTime(2024),
      occurredAt: DateTime(2024),
    );

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockDatasource mockDatasource;
  late ExternalApiRepositoryImpl sut;

  setUp(() {
    mockDatasource = _MockDatasource();
    sut = ExternalApiRepositoryImpl(mockDatasource);
  });

  group('fetchItems() — entity mapping — WBS 2.9', () {
    test('returns entities mapped from datasource models', () async {
      when(() => mockDatasource.fetchItems(
            category: null,
            keyword: null,
            limit: 20,
          )).thenAnswer((_) async => [_fakeModel(), _fakeModel(id: 'item-002')]);

      final result = await sut.fetchItems();

      expect(result.length, 2);
      expect(result[0].id, 'item-001');
      expect(result[1].id, 'item-002');
    });

    test('maps category string to ItemCategory enum', () async {
      when(() => mockDatasource.fetchItems(
            category: null,
            keyword: null,
            limit: 20,
          )).thenAnswer((_) async => [
            _fakeModel(category: 'founder'),
            _fakeModel(id: 'item-002', category: 'seeker'),
          ]);

      final result = await sut.fetchItems();

      expect(result[0].category, ItemCategory.founder);
      expect(result[1].category, ItemCategory.seeker);
    });

    test('returns empty list when datasource returns empty', () async {
      when(() => mockDatasource.fetchItems(
            category: null,
            keyword: null,
            limit: 20,
          )).thenAnswer((_) async => []);

      final result = await sut.fetchItems();

      expect(result, isEmpty);
    });
  });

  group('fetchItems() — parameter forwarding — WBS 2.9', () {
    test('passes category.name string to datasource', () async {
      when(() => mockDatasource.fetchItems(
            category: 'founder',
            keyword: null,
            limit: 20,
          )).thenAnswer((_) async => [_fakeModel(category: 'founder')]);

      await sut.fetchItems(category: ItemCategory.founder);

      verify(() => mockDatasource.fetchItems(
            category: 'founder',
            keyword: null,
            limit: 20,
          )).called(1);
    });

    test('passes keyword to datasource', () async {
      when(() => mockDatasource.fetchItems(
            category: null,
            keyword: 'wallet',
            limit: 20,
          )).thenAnswer((_) async => []);

      await sut.fetchItems(keyword: 'wallet');

      verify(() => mockDatasource.fetchItems(
            category: null,
            keyword: 'wallet',
            limit: 20,
          )).called(1);
    });

    test('passes custom limit to datasource', () async {
      when(() => mockDatasource.fetchItems(
            category: null,
            keyword: null,
            limit: 50,
          )).thenAnswer((_) async => []);

      await sut.fetchItems(limit: 50);

      verify(() => mockDatasource.fetchItems(
            category: null,
            keyword: null,
            limit: 50,
          )).called(1);
    });
  });

  group('fetchItems() — error handling — WBS 2.9', () {
    test('throws ServerFailure with the ApiException message on 401', () {
      when(() => mockDatasource.fetchItems(
            category: any(named: 'category'),
            keyword: any(named: 'keyword'),
            limit: any(named: 'limit'),
          )).thenThrow(
        const ApiException(
          'Unauthorized — invalid or missing API key.',
          statusCode: 401,
        ),
      );

      expect(
        () => sut.fetchItems(),
        throwsA(
          isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Unauthorized — invalid or missing API key.',
          ),
        ),
      );
    });

    test('throws ServerFailure with the ApiException message on 400', () {
      when(() => mockDatasource.fetchItems(
            category: any(named: 'category'),
            keyword: any(named: 'keyword'),
            limit: any(named: 'limit'),
          )).thenThrow(
        const ApiException(
          'Bad request — invalid query parameters.',
          statusCode: 400,
        ),
      );

      expect(
        () => sut.fetchItems(),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('throws ServerFailure with generic message on unexpected exception', () {
      when(() => mockDatasource.fetchItems(
            category: any(named: 'category'),
            keyword: any(named: 'keyword'),
            limit: any(named: 'limit'),
          )).thenThrow(Exception('network timeout'));

      expect(
        () => sut.fetchItems(),
        throwsA(
          isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Failed to fetch items from external API.',
          ),
        ),
      );
    });
  });
}
