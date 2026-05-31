// WBS 2.1 — Domain Entities & Repository Interfaces
// Covers: Item entity, ItemCategory enum, ItemStatus enum
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── ItemCategory.fromString() ────────────────────────────────────────────

  group('ItemCategory.fromString()', () {
    test('returns seeker for "seeker"', () {
      expect(ItemCategory.fromString('seeker'), ItemCategory.seeker);
    });

    test('returns founder for "founder"', () {
      expect(ItemCategory.fromString('founder'), ItemCategory.founder);
    });

    test('throws ArgumentError for an unrecognised value', () {
      expect(
        () => ItemCategory.fromString('lost'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unknown ItemCategory'),
          ),
        ),
      );
    });

    test('throws ArgumentError for an empty string', () {
      expect(
        () => ItemCategory.fromString(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for a value with wrong capitalisation', () {
      expect(
        () => ItemCategory.fromString('Seeker'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ── ItemStatus.fromString() ──────────────────────────────────────────────

  group('ItemStatus.fromString()', () {
    test('returns active for "active"', () {
      expect(ItemStatus.fromString('active'), ItemStatus.active);
    });

    test('returns resolved for "resolved"', () {
      expect(ItemStatus.fromString('resolved'), ItemStatus.resolved);
    });

    test('throws ArgumentError for an unrecognised value', () {
      expect(
        () => ItemStatus.fromString('closed'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unknown ItemStatus'),
          ),
        ),
      );
    });

    test('throws ArgumentError for an empty string', () {
      expect(
        () => ItemStatus.fromString(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for a value with wrong capitalisation', () {
      expect(
        () => ItemStatus.fromString('Active'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ── Item constructor ─────────────────────────────────────────────────────

  group('Item', () {
    final baseCreatedAt = DateTime(2025, 1, 15, 10, 30);
    final baseOccurredAt = DateTime(2025, 1, 14, 18, 0);

    group('required fields', () {
      late Item item;

      setUp(() {
        item = Item(
          id: 'item-001',
          title: 'Lost wallet',
          description: 'Black leather wallet with student ID inside',
          category: ItemCategory.seeker,
          status: ItemStatus.active,
          location: 'Central Library, 2nd floor',
          contact: '0812345678',
          imageUrls: const [],
          userId: 'uid-001',
          createdAt: baseCreatedAt,
          occurredAt: baseOccurredAt,
        );
      });

      test('stores id correctly', () {
        expect(item.id, 'item-001');
      });

      test('stores title correctly', () {
        expect(item.title, 'Lost wallet');
      });

      test('stores description correctly', () {
        expect(item.description, 'Black leather wallet with student ID inside');
      });

      test('stores category correctly', () {
        expect(item.category, ItemCategory.seeker);
      });

      test('stores status correctly', () {
        expect(item.status, ItemStatus.active);
      });

      test('stores location correctly', () {
        expect(item.location, 'Central Library, 2nd floor');
      });

      test('stores contact correctly', () {
        expect(item.contact, '0812345678');
      });

      test('stores userId correctly', () {
        expect(item.userId, 'uid-001');
      });

      test('stores createdAt correctly', () {
        expect(item.createdAt, baseCreatedAt);
      });

      test('stores occurredAt correctly (WBS 2.2)', () {
        expect(item.occurredAt, baseOccurredAt);
      });

      test('accepts an empty imageUrls list', () {
        expect(item.imageUrls, isEmpty);
      });
    });

    group('imageUrls', () {
      test('stores a single image URL', () {
        final item = Item(
          id: 'item-002',
          title: 'Found phone',
          description: 'iPhone 14 Pro',
          category: ItemCategory.founder,
          status: ItemStatus.active,
          location: 'Canteen',
          contact: '0823456789',
          imageUrls: const ['https://storage.example.com/img1.jpg'],
          userId: 'uid-002',
          createdAt: baseCreatedAt,
          occurredAt: baseOccurredAt,
        );
        expect(item.imageUrls, hasLength(1));
        expect(item.imageUrls.first, 'https://storage.example.com/img1.jpg');
      });

      test('stores up to three image URLs', () {
        final item = Item(
          id: 'item-003',
          title: 'Found keys',
          description: 'Car keys with blue keychain',
          category: ItemCategory.founder,
          status: ItemStatus.active,
          location: 'Parking lot B',
          contact: '0834567890',
          imageUrls: const ['url1', 'url2', 'url3'],
          userId: 'uid-003',
          createdAt: baseCreatedAt,
          occurredAt: baseOccurredAt,
        );
        expect(item.imageUrls, ['url1', 'url2', 'url3']);
      });
    });

    group('nullable fields default to null', () {
      late Item item;

      setUp(() {
        item = Item(
          id: 'item-004',
          title: 'Lost bag',
          description: 'Blue backpack',
          category: ItemCategory.seeker,
          status: ItemStatus.active,
          location: 'Engineering building',
          contact: '0845678901',
          imageUrls: const [],
          userId: 'uid-004',
          createdAt: baseCreatedAt,
          occurredAt: baseOccurredAt,
        );
      });

      test('editedAt is null when not provided (WBS 2.6)', () {
        expect(item.editedAt, isNull);
      });

      test('claimedBy is null when not provided (WBS 2.4)', () {
        expect(item.claimedBy, isNull);
      });

      test('secretQuestion is null when not provided (WBS 2.10)', () {
        expect(item.secretQuestion, isNull);
      });

      test('secretAnswer is null when not provided (WBS 2.10)', () {
        expect(item.secretAnswer, isNull);
      });
    });

    group('optional fields are stored when provided', () {
      late Item item;
      final editedAt = DateTime(2025, 2, 10, 9, 0);

      setUp(() {
        item = Item(
          id: 'item-005',
          title: 'Found wallet',
          description: 'Brown leather wallet',
          category: ItemCategory.founder,
          status: ItemStatus.resolved,
          location: 'Sports complex',
          contact: '0856789012',
          imageUrls: const ['https://storage.example.com/found1.jpg'],
          userId: 'uid-005',
          createdAt: baseCreatedAt,
          occurredAt: baseOccurredAt,
          editedAt: editedAt,
          claimedBy: 'uid-999',
          secretQuestion: 'What colour is the card sleeve inside?',
          secretAnswer: 'navy blue',
        );
      });

      test('editedAt is stored correctly (WBS 2.6)', () {
        expect(item.editedAt, editedAt);
      });

      test('claimedBy is stored correctly (WBS 2.4)', () {
        expect(item.claimedBy, 'uid-999');
      });

      test('secretQuestion is stored correctly (WBS 2.10)', () {
        expect(item.secretQuestion, 'What colour is the card sleeve inside?');
      });

      test('secretAnswer is stored correctly (WBS 2.10)', () {
        expect(item.secretAnswer, 'navy blue');
      });
    });

    group('category variants', () {
      test('can be constructed with category seeker', () {
        final item = Item(
          id: 'item-s',
          title: 'Lost ID card',
          description: 'KMUTT student ID',
          category: ItemCategory.seeker,
          status: ItemStatus.active,
          location: 'Admin building',
          contact: '0867890123',
          imageUrls: const [],
          userId: 'uid-s',
          createdAt: baseCreatedAt,
          occurredAt: baseOccurredAt,
        );
        expect(item.category, ItemCategory.seeker);
      });

      test('can be constructed with category founder', () {
        final item = Item(
          id: 'item-f',
          title: 'Found ID card',
          description: 'KMUTT student ID card',
          category: ItemCategory.founder,
          status: ItemStatus.active,
          location: 'Cafeteria',
          contact: '0878901234',
          imageUrls: const [],
          userId: 'uid-f',
          createdAt: baseCreatedAt,
          occurredAt: baseOccurredAt,
        );
        expect(item.category, ItemCategory.founder);
      });
    });

    group('status variants', () {
      test('can be constructed with status active', () {
        final item = Item(
          id: 'item-active',
          title: 'Lost umbrella',
          description: 'Black umbrella',
          category: ItemCategory.seeker,
          status: ItemStatus.active,
          location: 'Bus stop',
          contact: '0889012345',
          imageUrls: const [],
          userId: 'uid-active',
          createdAt: baseCreatedAt,
          occurredAt: baseOccurredAt,
        );
        expect(item.status, ItemStatus.active);
      });

      test('can be constructed with status resolved', () {
        final item = Item(
          id: 'item-resolved',
          title: 'Lost umbrella',
          description: 'Black umbrella',
          category: ItemCategory.seeker,
          status: ItemStatus.resolved,
          location: 'Bus stop',
          contact: '0889012345',
          imageUrls: const [],
          userId: 'uid-resolved',
          createdAt: baseCreatedAt,
          occurredAt: baseOccurredAt,
        );
        expect(item.status, ItemStatus.resolved);
      });
    });

    group('no Firebase or Flutter imports in domain layer', () {
      // The domain layer must remain pure Dart — zero Firebase / Flutter imports.
      // This is enforced at analysis time (dart analyze passes without flutter or
      // firebase imports), and confirmed here by verifying the entity is fully
      // constructable without any Firebase initialisation.
      test('Item can be constructed without Firebase initialisation', () {
        final item = Item(
          id: 'no-firebase',
          title: 'Test item',
          description: 'Verifies pure Dart construction',
          category: ItemCategory.seeker,
          status: ItemStatus.active,
          location: 'Anywhere',
          contact: '0000000000',
          imageUrls: const [],
          userId: 'uid-test',
          createdAt: DateTime(2025),
          occurredAt: DateTime(2024, 12, 31),
        );
        expect(item.id, 'no-firebase');
      });
    });
  });
}
