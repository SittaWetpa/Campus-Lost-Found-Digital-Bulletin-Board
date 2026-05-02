// WBS 1.2 — ItemModel mapping unit tests
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lost_found/features/feed/data/models/item_model.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

void main() {
  final createdAt = DateTime(2025, 3, 15, 10, 30);
  final editedAt  = DateTime(2025, 3, 16, 9, 0);

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
        occurredAt: createdAt,
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
    test('maps editedAt', () => expect(model.editedAt, editedAt));
    test('maps claimedBy', () => expect(model.claimedBy, 'uid-claimer'));
    test('maps secretQuestion', () => expect(model.secretQuestion, 'What color is the card sleeve?'));
    test('maps secretAnswer', () => expect(model.secretAnswer, 'navy blue'));

    test('maps seeker category as "seeker"', () {
      final m = ItemModel.fromEntity(Item(
        id: 'x', title: 't', description: 'd',
        category: ItemCategory.seeker, status: ItemStatus.active,
        location: 'l', contact: 'c', imageUrls: const [],
        userId: 'u', createdAt: createdAt, occurredAt: createdAt,
      ));
      expect(m.category, 'seeker');
    });

    test('maps resolved status as "resolved"', () {
      final m = ItemModel.fromEntity(Item(
        id: 'x', title: 't', description: 'd',
        category: ItemCategory.founder, status: ItemStatus.resolved,
        location: 'l', contact: 'c', imageUrls: const [],
        userId: 'u', createdAt: createdAt, occurredAt: createdAt,
      ));
      expect(m.status, 'resolved');
    });

    test('nullable fields are null when not provided', () {
      final m = ItemModel.fromEntity(Item(
        id: 'x', title: 't', description: 'd',
        category: ItemCategory.seeker, status: ItemStatus.active,
        location: 'l', contact: 'c', imageUrls: const [],
        userId: 'u', createdAt: createdAt, occurredAt: createdAt,
      ));
      expect(m.editedAt, isNull);
      expect(m.claimedBy, isNull);
      expect(m.secretQuestion, isNull);
      expect(m.secretAnswer, isNull);
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
        occurredAt: createdAt,
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
    test('maps editedAt', () => expect(entity.editedAt, editedAt));
    test('maps claimedBy', () => expect(entity.claimedBy, 'uid-c'));
    test('maps secretQuestion', () => expect(entity.secretQuestion, 'Q?'));
    test('maps secretAnswer', () => expect(entity.secretAnswer, 'A'));

    test('maps "founder" to ItemCategory.founder', () {
      final e = ItemModel(
        id: 'x', title: 't', description: 'd',
        category: 'founder', status: 'active', location: 'l', contact: 'c',
        imageUrls: const [], userId: 'u', createdAt: createdAt, occurredAt: createdAt,
      ).toEntity();
      expect(e.category, ItemCategory.founder);
    });

    test('maps "resolved" to ItemStatus.resolved', () {
      final e = ItemModel(
        id: 'x', title: 't', description: 'd',
        category: 'seeker', status: 'resolved', location: 'l', contact: 'c',
        imageUrls: const [], userId: 'u', createdAt: createdAt, occurredAt: createdAt,
      ).toEntity();
      expect(e.status, ItemStatus.resolved);
    });

    test('nullable fields are null when not provided', () {
      final e = ItemModel(
        id: 'x', title: 't', description: 'd',
        category: 'seeker', status: 'active', location: 'l', contact: 'c',
        imageUrls: const [], userId: 'u', createdAt: createdAt, occurredAt: createdAt,
      ).toEntity();
      expect(e.editedAt, isNull);
      expect(e.claimedBy, isNull);
      expect(e.secretQuestion, isNull);
      expect(e.secretAnswer, isNull);
    });
  });

  // ── fromEntity → toEntity round-trip ──────────────────────────────────────

  group('fromEntity → toEntity round-trip — WBS 1.2', () {
    test('preserves all fields', () {
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
        occurredAt: createdAt,
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
        'occurredAt': Timestamp.fromDate(createdAt),
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

    test('old Firestore doc without source/isSensitive defaults correctly', () {
      final entity = ItemModel.fromMap('doc-old', {
        'title': 'T', 'description': 'D', 'category': 'seeker',
        'status': 'active', 'location': 'L', 'contact': 'C',
        'imageUrls': <String>[], 'userId': 'U',
        'createdAt': Timestamp.fromDate(createdAt),
        'occurredAt': Timestamp.fromDate(createdAt),
        // no 'source' or 'isSensitive' keys
      }).toEntity();

      expect(entity.source,      ItemSource.web);
      expect(entity.isSensitive, false);
    });
  });

  // ── ItemModel.toFirestore() ────────────────────────────────────────────────

  group('ItemModel.toFirestore() — WBS 1.2', () {
    test('produces correct map with all optional fields', () {
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
        occurredAt: createdAt,
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
      // createdAt and editedAt are intentionally omitted — the datasource
      // sets them via FieldValue.serverTimestamp() to guarantee
      // server-side timestamps. occurredAt is user-supplied and is in
      // the map.
      expect(map.containsKey('createdAt'), isFalse);
      expect(map.containsKey('editedAt'), isFalse);
      expect((map['occurredAt'] as Timestamp).toDate(), createdAt);
      expect(map['claimedBy'], 'uid-c');
      expect(map['secretQuestion'], 'Q');
      expect(map['secretAnswer'], 'A');
    });

    test('omits null optional fields', () {
      final map = ItemModel(
        id: 'item-004', title: 'T', description: 'D', category: 'seeker',
        status: 'active', location: 'L', contact: 'C',
        imageUrls: const [], userId: 'U', createdAt: createdAt, occurredAt: createdAt,
      ).toFirestore();

      expect(map.containsKey('editedAt'),       isFalse);
      expect(map.containsKey('claimedBy'),      isFalse);
      expect(map.containsKey('secretQuestion'), isFalse);
      expect(map.containsKey('secretAnswer'),   isFalse);
    });

    test('does not include document id in the map', () {
      final map = ItemModel(
        id: 'should-not-appear', title: 'T', description: 'D',
        category: 'seeker', status: 'active', location: 'L', contact: 'C',
        imageUrls: const [], userId: 'U', createdAt: createdAt, occurredAt: createdAt,
      ).toFirestore();
      expect(map.containsKey('id'), isFalse);
    });
  });

  // ── ItemModel.fromMap() ────────────────────────────────────────────────────
  // fromFirestore() delegates to fromMap(), so testing fromMap() covers both.

  group('ItemModel.fromMap() — WBS 1.2', () {
    test('parses all fields including optional ones', () {
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
        'occurredAt': Timestamp.fromDate(createdAt),
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
        'occurredAt': Timestamp.fromDate(createdAt),
      });

      expect(model.editedAt,       isNull);
      expect(model.claimedBy,      isNull);
      expect(model.secretQuestion, isNull);
      expect(model.secretAnswer,   isNull);
    });

    test('defaults imageUrls to empty list when key is absent', () {
      final model = ItemModel.fromMap('doc-003', {
        'title': 'T', 'description': 'D', 'category': 'seeker',
        'status': 'active', 'location': 'L', 'contact': 'C',
        'userId': 'U', 'createdAt': Timestamp.fromDate(createdAt), 'occurredAt': Timestamp.fromDate(createdAt),
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
        'occurredAt': Timestamp.fromDate(createdAt),
      }).toEntity();

      expect(entity.id,       'doc-ff');
      expect(entity.category, ItemCategory.seeker);
      expect(entity.status,   ItemStatus.active);
      expect(entity.createdAt, createdAt);
    });
  });

  // ── ItemModel.fromMap() — null-tolerance for soft-string fields ────────────
  //
  // Regression: a single Firestore doc with `description: null` (or `contact`
  // / `location`) used to make `data['x'] as String` throw a TypeError, which
  // propagated up the watchFeed() stream and showed "Failed to load items"
  // for the *entire* feed even when other docs were valid. These fields are
  // conceptually required (the post form must always set them) but the
  // parser now defaults to '' so one bad doc cannot blank the whole feed.

  group('ItemModel.fromMap() null-tolerance — WBS 1.2 regression', () {
    Map<String, dynamic> _baseDoc() => {
          'title': 'T',
          'description': 'D',
          'category': 'seeker',
          'status': 'active',
          'location': 'L',
          'contact': 'C',
          'imageUrls': <String>[],
          'userId': 'U',
          'createdAt': Timestamp.fromDate(createdAt),
          'occurredAt': Timestamp.fromDate(createdAt),
        };

    test('description: null → parses as empty string (does not throw)', () {
      final model =
          ItemModel.fromMap('doc-null-desc', _baseDoc()..['description'] = null);
      expect(model.description, '');
    });

    test('contact: null → parses as empty string (does not throw)', () {
      final model =
          ItemModel.fromMap('doc-null-contact', _baseDoc()..['contact'] = null);
      expect(model.contact, '');
    });

    test('location: null → parses as empty string (does not throw)', () {
      final model =
          ItemModel.fromMap('doc-null-loc', _baseDoc()..['location'] = null);
      expect(model.location, '');
    });

    test('all three null at once still parses without throwing', () {
      final doc = _baseDoc()
        ..['description'] = null
        ..['contact'] = null
        ..['location'] = null;
      final model = ItemModel.fromMap('doc-null-all', doc);
      expect(model.description, '');
      expect(model.contact, '');
      expect(model.location, '');
      // Strict fields are still populated.
      expect(model.title, 'T');
      expect(model.userId, 'U');
      expect(model.createdAt, createdAt);
    });

    test(
      'absent description / contact / location keys also parse as empty '
      '(consistent with null behaviour)',
      () {
        final doc = _baseDoc()
          ..remove('description')
          ..remove('contact')
          ..remove('location');
        final model = ItemModel.fromMap('doc-missing-keys', doc);
        expect(model.description, '');
        expect(model.contact, '');
        expect(model.location, '');
      },
    );
  });
}
