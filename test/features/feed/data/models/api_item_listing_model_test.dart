// WBS 2.9 — ApiItemListingModel JSON parsing tests.
//
// Verifies that the public REST API response shape is deserialized correctly,
// including sensitive-item masking and the occurredAt fallback for legacy docs.

import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lost_found/features/feed/data/models/api_item_listing_model.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

Map<String, dynamic> _baseJson({
  bool isSensitive = false,
  String? occurredAt = '2024-06-10T09:00:00.000Z',
  String? expiresAt,
  String? itemCategory = 'wallet',
}) =>
    {
      'id': 'item-001',
      'title': 'Lost wallet',
      'category': 'seeker',
      'status': 'active',
      'description': isSensitive ? '' : 'Brown leather wallet',
      'location': 'Main library',
      'contact': isSensitive ? '' : '0812345678',
      'imageUrls': isSensitive ? <dynamic>[] : <dynamic>['https://example.com/img.jpg'],
      'isSensitive': isSensitive,
      'createdAt': '2024-06-10T10:00:00.000Z',
      'occurredAt': occurredAt,
      'expiresAt': expiresAt,
      'itemCategory': itemCategory,
    };

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ApiItemListingModel.fromJson() — WBS 2.9', () {
    test('parses all non-nullable fields from a full response', () {
      final model = ApiItemListingModel.fromJson(_baseJson());

      expect(model.id, 'item-001');
      expect(model.title, 'Lost wallet');
      expect(model.category, 'seeker');
      expect(model.status, 'active');
      expect(model.description, 'Brown leather wallet');
      expect(model.location, 'Main library');
      expect(model.contact, '0812345678');
      expect(model.imageUrls, ['https://example.com/img.jpg']);
      expect(model.isSensitive, false);
      expect(model.createdAt, DateTime.parse('2024-06-10T10:00:00.000Z'));
      expect(model.occurredAt, DateTime.parse('2024-06-10T09:00:00.000Z'));
      expect(model.expiresAt, isNull);
      expect(model.itemCategory, 'wallet');
    });

    test('sensitive item: description and contact are empty strings, imageUrls is empty', () {
      final model = ApiItemListingModel.fromJson(_baseJson(isSensitive: true));

      expect(model.isSensitive, true);
      expect(model.description, '');
      expect(model.contact, '');
      expect(model.imageUrls, isEmpty);
    });

    test('falls back to createdAt when occurredAt is null (pre-WBS 2.2 docs)', () {
      final model = ApiItemListingModel.fromJson(_baseJson(occurredAt: null));

      expect(model.occurredAt, DateTime.parse('2024-06-10T10:00:00.000Z'));
    });

    test('parses non-null expiresAt as DateTime', () {
      final model = ApiItemListingModel.fromJson(
        _baseJson(expiresAt: '2024-06-24T10:00:00.000Z'),
      );

      expect(model.expiresAt, DateTime.parse('2024-06-24T10:00:00.000Z'));
    });

    test('expiresAt is null when absent from response', () {
      final model = ApiItemListingModel.fromJson(_baseJson(expiresAt: null));

      expect(model.expiresAt, isNull);
    });

    test('itemCategory is null when absent from response (pre-WBS 2.8 docs)', () {
      final json = Map<String, dynamic>.from(_baseJson())..remove('itemCategory');
      final model = ApiItemListingModel.fromJson(json);

      expect(model.itemCategory, isNull);
    });

    test('imageUrls defaults to empty list when key is absent', () {
      final json = Map<String, dynamic>.from(_baseJson())..remove('imageUrls');
      final model = ApiItemListingModel.fromJson(json);

      expect(model.imageUrls, isEmpty);
    });
  });

  group('ApiItemListingModel.toEntity() — WBS 2.9', () {
    test('maps category string "seeker" to ItemCategory.seeker', () {
      final entity = ApiItemListingModel.fromJson(_baseJson()).toEntity();

      expect(entity.category, ItemCategory.seeker);
    });

    test('maps category string "founder" to ItemCategory.founder', () {
      final json = Map<String, dynamic>.from(_baseJson())..['category'] = 'founder';
      final entity = ApiItemListingModel.fromJson(json).toEntity();

      expect(entity.category, ItemCategory.founder);
    });

    test('maps status string "active" to ItemStatus.active', () {
      final entity = ApiItemListingModel.fromJson(_baseJson()).toEntity();

      expect(entity.status, ItemStatus.active);
    });

    test('all entity fields match the parsed model values', () {
      final model = ApiItemListingModel.fromJson(
        _baseJson(expiresAt: '2024-06-24T10:00:00.000Z'),
      );
      final entity = model.toEntity();

      expect(entity.id, model.id);
      expect(entity.title, model.title);
      expect(entity.description, model.description);
      expect(entity.location, model.location);
      expect(entity.contact, model.contact);
      expect(entity.imageUrls, model.imageUrls);
      expect(entity.isSensitive, model.isSensitive);
      expect(entity.createdAt, model.createdAt);
      expect(entity.occurredAt, model.occurredAt);
      expect(entity.expiresAt, model.expiresAt);
      expect(entity.itemCategory, model.itemCategory);
    });
  });
}
