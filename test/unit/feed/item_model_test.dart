// WBS 1.2 — ItemModel mapping unit tests
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lost_found/features/feed/data/models/item_model.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

void main() {
  final createdAt  = DateTime(2025, 3, 15, 10, 30);
  final occurredAt = DateTime(2025, 3, 15, 9, 0);
  final editedAt   = DateTime(2025, 3, 16, 9, 0);

  // ── ItemModel.fromEntity() ─────────────────────────────────────────────────

  group('ItemModel.fromEntity() — WBS 1.2', () {
    late Item item;
    late ItemModel model;

    setUp(() {
      item = Item(
        id: 'item-001',
        title: 'Brown leather wallet',
        description: 'Found near CB2',
        category: ItemCategory.founder,
        status: ItemStatus.active,
        location: 'CB2, 2nd floor hallway',
        contact: '0812345678',
        imageUrls: const ['https://example.com/img1.jpg'],
        userId: 'uid-poster',
        createdAt: createdAt,
        occurredAt: occurredAt,
        editedAt: editedAt,
        claimedBy: 'uid-claimer',
        secretQuestion: 'What color is the card sleeve?',
        secretAnswer: 'navy blue',
      );
      model = ItemModel.fromEntity(item);
    });

    test('maps id', () => expect(model.id, 'item-001'));
    test('maps title', () => expect(model.title, 'Brown leather wallet'));
    test('maps description', () => expect(model.description, 'Found near CB2'));
    test('maps founder category as "founder"', () => expect(model.category, 'founder'));
    test('maps active status as "active"', () => expect(model.status, 'active'));
    test('maps location', () => expect(model.location, 'CB2, 2nd floor hallway'));
    test('maps contact', () => expect(model.contact, '0812345678'));
    test('maps imageUrls', () => expect(model.imageUrls, ['https://example.com/img1.jpg']));
    test('maps userId', () => expect(model.userId, 'uid-poster'));
    test('maps createdAt', () => expect(model.createdAt, createdAt));
    test('maps occurredAt (WBS 1.4)', () => expect(model.occurredAt, occurredAt));
    test('maps editedAt', () => expect(model.editedAt, editedAt));
    test('maps claimedBy', () => expect(model.claimedBy, 'uid-claimer'));
    test('maps secretQuestion', () => expect(model.secretQuestion, 'What color is the card sleeve?'));
    test('maps secretAnswer', () => expect(model.secretAnswer, 'navy blue'));

    test('maps seeker category as "seeker"', () {
      final m = ItemModel.fromEntity(Item(
        id: 'x', title: 't', description: 'd',
        category: ItemCategory.seeker, status: ItemStatus.active,
        location: 'l', contact: 'c', imageUrls: const [],
        userId: 'u', createdAt: createdAt, occurredAt: occurredAt,
      ));
      expect(m.category, 'seeker');
    });

    test('maps resolved status as "resolved"', () {
      final m = ItemModel.fromEntity(Item(
        id: 'x', title: 't', description: 'd',
        category: ItemCategory.founder, status: ItemStatus.resolved,
        location: 'l', contact: 'c', imageUrls: const [],
        userId: 'u', createdAt: createdAt, occurredAt: occurredAt,
      ));
      expect(m.status, 'resolved');
    });

    test('nullable fields are null when not provided', () {
      final m = ItemModel.fromEntity(Item(
        id: 'x', title: 't', description: 'd',
        category: ItemCategory.seeker, status: ItemStatus.active,
        location: 'l', contact: 'c', imageUrls: const [],
        userId: 'u', createdAt: createdAt, occurredAt: occurredAt,
      ));
      expect(m.editedAt, isNull);
      expect(m.expiresAt, isNull);
      expect(m.claimedBy, isNull);
      expect(m.secretQuestion, isNull);
      expect(m.secretAnswer, isNull);
    });

    test('maps null description for sensitive item (WBS 2.14)', () {
      final m = ItemModel.fromEntity(Item(
        id: 'x', title: 'ID card', description: null,
        category: ItemCategory.founder, status: ItemStatus.active,
        location: 'ECC', contact: null, imageUrls: const [],
        userId: 'u', createdAt: createdAt, occurredAt: occurredAt,
        isSensitive: true,
      ));
      expect(m.description, isNull);
      expect(m.contact, isNull);
      expect(m.isSensitive, isTrue);
    });
  });

  // ── ItemModel.toEntity() ───────────────────────────────────────────────────

  group('ItemModel.toEntity() — WBS 1.2', () {
    late ItemModel model;
    late Item entity;

    setUp(() {
      model = ItemModel(
        id: 'item-002',
        title: 'Dorm keys',
        description: 'Green lanyard',
        category: 'seeker',
        status: 'active',
        location: 'Bus stop → Dorm 2',
        contact: '0823456789',
        imageUrls: const [],
        userId: 'uid-seeker',
        createdAt: createdAt,
        occurredAt: occurredAt,
        editedAt: editedAt,
        claimedBy: 'uid-c',
        secretQuestion: 'Q?',
        secretAnswer: 'A',
      );
      entity = model.toEntity();
    });

    test('maps id', () => expect(entity.id, 'item-002'));
    test('maps title', () => expect(entity.title, 'Dorm keys'));
    test('maps description', () => expect(entity.description, 'Green lanyard'));
    test('maps "seeker" to ItemCategory.seeker', () =>
        expect(entity.category, ItemCategory.seeker));
    test('maps "active" to ItemStatus.active', () =>
        expect(entity.status, ItemStatus.active));
    test('maps location', () => expect(entity.location, 'Bus stop → Dorm 2'));
    test('maps contact', () => expect(entity.contact, '0823456789'));
    test('maps userId', () => expect(entity.userId, 'uid-seeker'));
    test('maps createdAt', () => expect(entity.createdAt, createdAt));
    test('maps occurredAt (WBS 1.4)', () => expect(entity.occurredAt, occurredAt));
    test('maps editedAt', () => expect(entity.editedAt, editedAt));
    test('maps claimedBy', () => expect(entity.claimedBy, 'uid-c'));
    test('maps secretQuestion', () => expect(entity.secretQuestion, 'Q?'));
    test('maps secretAnswer', () => expect(entity.secretAnswer, 'A'));

    test('maps "founder" to ItemCategory.founder', () {
      final e = ItemModel(
        id: 'x', title: 't', description: 'd',
        category: 'founder', status: 'active', location: 'l', contact: 'c',
        imageUrls: const [], userId: 'u', createdAt: createdAt,
        occurredAt: occurredAt,
      ).toEntity();
      expect(e.category, ItemCategory.founder);
    });

    test('maps "resolved" to ItemStatus.resolved', () {
      final e = ItemModel(
        id: 'x', title: 't', description: 'd',
        category: 'seeker', status: 'resolved', location: 'l', contact: 'c',
        imageUrls: const [], userId: 'u', createdAt: createdAt,
        occurredAt: occurredAt,
      ).toEntity();
      expect(e.status, ItemStatus.resolved);
    });

    test('nullable fields are null when not provided', () {
      final e = ItemModel(
        id: 'x', title: 't', description: 'd',
        category: 'seeker', status: 'active', location: 'l', contact: 'c',
        imageUrls: const [], userId: 'u', createdAt: createdAt,
        occurredAt: occurredAt,
      ).toEntity();
      expect(e.editedAt, isNull);
      expect(e.expiresAt, isNull);
      expect(e.claimedBy, isNull);
      expect(e.secretQuestion, isNull);
      expect(e.secretAnswer, isNull);
    });
  });

  // ── fromEntity → toEntity round-trip ──────────────────────────────────────

  group('fromEntity → toEntity round-trip — WBS 1.2', () {
    test('preserves all fields including occurredAt and expiresAt', () {
      final expiresAt = DateTime(2025, 3, 29);
      final original = Item(
        id: 'rt-001',
        title: 'AirPods case',
        description: 'White case, small scratch',
        category: ItemCategory.seeker,
        status: ItemStatus.active,
        location: 'LIB-1 reading room',
        contact: '0834567890',
        imageUrls: const ['https://example.com/rt.jpg'],
        userId: 'uid-rt',
        createdAt: createdAt,
        occurredAt: occurredAt,
        expiresAt: expiresAt,
        editedAt: editedAt,
        claimedBy: 'uid-claim',
        secretQuestion: 'Q?',
        secretAnswer: 'A',
      );
      final rt = ItemModel.fromEntity(original).toEntity();

      expect(rt.id,             original.id);
      expect(rt.title,          original.title);
      expect(rt.description,    original.description);
      expect(rt.category,       original.category);
      expect(rt.status,         original.status);
      expect(rt.location,       original.location);
      expect(rt.contact,        original.contact);
      expect(rt.imageUrls,      original.imageUrls);
      expect(rt.userId,         original.userId);
      expect(rt.createdAt,      original.createdAt);
      expect(rt.occurredAt,     original.occurredAt);
      expect(rt.expiresAt,      original.expiresAt);
      expect(rt.editedAt,       original.editedAt);
      expect(rt.claimedBy,      original.claimedBy);
      expect(rt.secretQuestion, original.secretQuestion);
      expect(rt.secretAnswer,   original.secretAnswer);
    });

    // WBS 2.15 / isSensitive — entity round-trip
    test('qr_walk_in source round-trips through model', () {
      final model = ItemModel.fromMap('doc-qr', {
        'title': 'T', 'description': 'D', 'category': 'founder',
        'status': 'active', 'location': 'L', 'contact': 'C',
        'imageUrls': <String>[], 'userId': 'U',
        'createdAt': Timestamp.fromDate(createdAt),
        'occurredAt': Timestamp.fromDate(occurredAt),
        'source': 'qr_walk_in',
        'isSensitive': true,
      });
      final entity = model.toEntity();
      expect(entity.source,      ItemSource.qrWalkIn);
      expect(entity.isSensitive, true);

      final map = ItemModel.fromEntity(entity).toFirestore();
      expect(map['source'],      'qr_walk_in');
      expect(map['isSensitive'], true);
    });

    test('old Firestore doc without source/isSensitive/occurredAt defaults correctly', () {
      final entity = ItemModel.fromMap('doc-old', {
        'title': 'T', 'description': 'D', 'category': 'seeker',
        'status': 'active', 'location': 'L', 'contact': 'C',
        'imageUrls': <String>[], 'userId': 'U',
        'createdAt': Timestamp.fromDate(createdAt),
        // no 'source', 'isSensitive', or 'occurredAt' keys
      }).toEntity();

      expect(entity.source,      ItemSource.web);
      expect(entity.isSensitive, false);
      // Legacy docs fall back to createdAt for occurredAt.
      expect(entity.occurredAt,  createdAt);
    });
  });

  // ── ItemModel.toFirestore() ────────────────────────────────────────────────

  group('ItemModel.toFirestore() — WBS 1.2', () {
    test('produces correct map with all optional fields', () {
      final expiresAt = DateTime(2025, 3, 29);
      final map = ItemModel(
        id: 'item-003',
        title: 'Umbrella',
        description: 'Navy blue',
        category: 'founder',
        status: 'active',
        location: 'Campus shuttle bus',
        contact: '0845678901',
        imageUrls: const ['url1', 'url2'],
        userId: 'uid-003',
        source: 'qr_walk_in',
        isSensitive: true,
        createdAt: createdAt,
        occurredAt: occurredAt,
        expiresAt: expiresAt,
        editedAt: editedAt,
        claimedBy: 'uid-c',
        secretQuestion: 'Q',
        secretAnswer: 'A',
      ).toFirestore();

      expect(map['title'], 'Umbrella');
      expect(map['description'], 'Navy blue');
      expect(map['category'], 'founder');
      expect(map['status'], 'active');
      expect(map['location'], 'Campus shuttle bus');
      expect(map['contact'], '0845678901');
      expect(map['imageUrls'], ['url1', 'url2']);
      expect(map['userId'], 'uid-003');
      expect(map['source'], 'qr_walk_in');
      expect(map['isSensitive'], true);
      expect((map['createdAt']  as Timestamp).toDate(), createdAt);
      expect((map['occurredAt'] as Timestamp).toDate(), occurredAt);
      expect((map['expiresAt']  as Timestamp).toDate(), expiresAt);
      expect((map['editedAt']   as Timestamp).toDate(), editedAt);
      expect(map['claimedBy'], 'uid-c');
      expect(map['secretQuestion'], 'Q');
      expect(map['secretAnswer'], 'A');
    });

    test('omits null optional fields', () {
      final map = ItemModel(
        id: 'item-004', title: 'T', description: 'D', category: 'seeker',
        status: 'active', location: 'L', contact: 'C',
        imageUrls: const [], userId: 'U', createdAt: createdAt,
        occurredAt: occurredAt,
      ).toFirestore();

      expect(map.containsKey('expiresAt'),     isFalse);
      expect(map.containsKey('editedAt'),      isFalse);
      expect(map.containsKey('claimedBy'),     isFalse);
      expect(map.containsKey('secretQuestion'), isFalse);
      expect(map.containsKey('secretAnswer'),  isFalse);
    });

    test('does not include document id in the map', () {
      final map = ItemModel(
        id: 'should-not-appear', title: 'T', description: 'D',
        category: 'seeker', status: 'active', location: 'L', contact: 'C',
        imageUrls: const [], userId: 'U', createdAt: createdAt,
        occurredAt: occurredAt,
      ).toFirestore();
      expect(map.containsKey('id'), isFalse);
    });
  });

  // ── ItemModel.fromMap() ────────────────────────────────────────────────────
  // fromFirestore() delegates to fromMap(), so testing fromMap() covers both.

  group('ItemModel.fromMap() — WBS 1.2', () {
    test('parses all fields including occurredAt and optional ones', () {
      final model = ItemModel.fromMap('doc-001', {
        'title': 'Brown leather wallet',
        'description': 'Found near CB2',
        'category': 'founder',
        'status': 'active',
        'location': 'CB2, 2nd floor hallway',
        'contact': '0812345678',
        'imageUrls': ['https://example.com/img1.jpg'],
        'userId': 'uid-poster',
        'createdAt': Timestamp.fromDate(createdAt),
        'occurredAt': Timestamp.fromDate(occurredAt),
        'editedAt': Timestamp.fromDate(editedAt),
        'claimedBy': 'uid-claimer',
        'secretQuestion': 'What color?',
        'secretAnswer': 'blue',
      });

      expect(model.id,             'doc-001');
      expect(model.title,          'Brown leather wallet');
      expect(model.description,    'Found near CB2');
      expect(model.category,       'founder');
      expect(model.status,         'active');
      expect(model.location,       'CB2, 2nd floor hallway');
      expect(model.contact,        '0812345678');
      expect(model.imageUrls,      ['https://example.com/img1.jpg']);
      expect(model.userId,         'uid-poster');
      expect(model.createdAt,      createdAt);
      expect(model.occurredAt,     occurredAt);
      expect(model.editedAt,       editedAt);
      expect(model.claimedBy,      'uid-claimer');
      expect(model.secretQuestion, 'What color?');
      expect(model.secretAnswer,   'blue');
    });

    test('parses absent optional fields as null', () {
      final model = ItemModel.fromMap('doc-002', {
        'title': 'T', 'description': 'D', 'category': 'seeker',
        'status': 'active', 'location': 'L', 'contact': 'C',
        'imageUrls': <String>[], 'userId': 'U',
        'createdAt': Timestamp.fromDate(createdAt),
        'occurredAt': Timestamp.fromDate(occurredAt),
      });

      expect(model.editedAt,       isNull);
      expect(model.expiresAt,      isNull);
      expect(model.claimedBy,      isNull);
      expect(model.secretQuestion, isNull);
      expect(model.secretAnswer,   isNull);
    });

    test('defaults imageUrls to empty list when key is absent', () {
      final model = ItemModel.fromMap('doc-003', {
        'title': 'T', 'description': 'D', 'category': 'seeker',
        'status': 'active', 'location': 'L', 'contact': 'C',
        'userId': 'U', 'createdAt': Timestamp.fromDate(createdAt),
      });
      expect(model.imageUrls, isEmpty);
    });

    test('toEntity() after fromMap() converts enums correctly', () {
      final entity = ItemModel.fromMap('doc-ff', {
        'title': 'Keys', 'description': 'Green lanyard',
        'category': 'seeker', 'status': 'active',
        'location': 'Bus stop', 'contact': '0823456789',
        'imageUrls': <String>[], 'userId': 'uid-seeker',
        'createdAt': Timestamp.fromDate(createdAt),
        'occurredAt': Timestamp.fromDate(occurredAt),
      }).toEntity();

      expect(entity.id,        'doc-ff');
      expect(entity.category,  ItemCategory.seeker);
      expect(entity.status,    ItemStatus.active);
      expect(entity.createdAt, createdAt);
      expect(entity.occurredAt, occurredAt);
    });

    test('occurredAt falls back to createdAt when absent (legacy document)', () {
      final model = ItemModel.fromMap('doc-legacy', {
        'title': 'T', 'description': 'D', 'category': 'seeker',
        'status': 'active', 'location': 'L', 'contact': 'C',
        'imageUrls': <String>[], 'userId': 'U',
        'createdAt': Timestamp.fromDate(createdAt),
        // no 'occurredAt' key
      });
      expect(model.occurredAt, createdAt);
    });
  });
}
