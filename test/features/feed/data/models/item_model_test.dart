// WBS 2.1 / 2.2 — ItemModel ↔ Firestore mapping.
// Direct coverage for the Timestamp ↔ DateTime conversion of `occurredAt`,
// the architect's "throw loudly on missing occurredAt" contract, and the
// full entity → toFirestore → fromFirestore → entity round-trip.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lost_found/features/feed/data/models/item_model.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  Map<String, dynamic> validFirestoreDoc({Object? occurredAt}) => {
        'title': 'Lost wallet',
        'description': 'Brown leather wallet',
        'category': 'seeker',
        'status': 'active',
        'location': 'Library',
        'contact': '0812345678',
        'imageUrls': <String>[],
        'userId': 'uid-001',
        'createdAt': Timestamp.fromDate(DateTime(2026, 4, 27, 14, 30)),
        if (occurredAt != null) 'occurredAt': occurredAt,
      };

  group('ItemModel.fromFirestore() — WBS 2.1 / 2.2', () {
    test('parses occurredAt Timestamp into a DateTime', () async {
      final occurredAt = DateTime(2026, 4, 26, 9, 15);
      final ref = await fakeFirestore.collection('items').add(
            validFirestoreDoc(occurredAt: Timestamp.fromDate(occurredAt)),
          );
      final doc = await ref.get();

      final model = ItemModel.fromFirestore(doc);

      expect(model.occurredAt, equals(occurredAt));
    });

    test('throws when occurredAt is missing — loud failure on legacy docs',
        () async {
      // Architect verdict (plan point 3): occurredAt has no defensive fallback.
      // A doc lacking the field is malformed and must throw, not silently
      // substitute DateTime.now().
      final ref = await fakeFirestore
          .collection('items')
          .add(validFirestoreDoc()); // omits occurredAt
      final doc = await ref.get();

      expect(() => ItemModel.fromFirestore(doc), throwsA(isA<TypeError>()));
    });
  });

  group('ItemModel.toFirestore() — WBS 2.1 / 2.2', () {
    test('writes occurredAt as a Firestore Timestamp, not a raw DateTime', () {
      final occurredAt = DateTime(2026, 4, 26, 9, 15);
      final model = ItemModel(
        id: 'item-001',
        title: 'Lost wallet',
        description: 'Brown leather wallet',
        category: 'seeker',
        status: 'active',
        location: 'Library',
        contact: '0812345678',
        imageUrls: const [],
        userId: 'uid-001',
        createdAt: DateTime(2026, 4, 27, 14, 30),
        occurredAt: occurredAt,
      );

      final payload = model.toFirestore();

      expect(payload['occurredAt'], isA<Timestamp>());
      expect(
        (payload['occurredAt'] as Timestamp).toDate(),
        equals(occurredAt),
      );
    });

    test(
        'does not write createdAt — datasource sets that via serverTimestamp '
        '(see item_model.dart toFirestore() doc comment)', () {
      final model = ItemModel(
        id: 'item-001',
        title: 'x',
        description: 'x',
        category: 'seeker',
        status: 'active',
        location: 'x',
        contact: 'x',
        imageUrls: const [],
        userId: 'uid-001',
        createdAt: DateTime(2026, 4, 27),
        occurredAt: DateTime(2026, 4, 26),
      );

      final payload = model.toFirestore();

      expect(payload.containsKey('createdAt'), isFalse);
    });
  });

  group('ItemModel itemCategory — WBS 2.8', () {
    test('fromMap with itemCategory parses to correct ItemTaxonomy', () {
      final data = {
        'title': 'Found iPhone',
        'description': 'Black iPhone',
        'category': 'founder',
        'status': 'active',
        'location': 'Library',
        'contact': '0812345678',
        'imageUrls': <String>[],
        'userId': 'uid-001',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'occurredAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'itemCategory': 'electronics',
      };

      final entity = ItemModel.fromMap('id-1', data).toEntity();

      expect(entity.itemTaxonomy, equals(ItemTaxonomy.electronics));
    });

    test('fromMap with missing itemCategory defaults to ItemTaxonomy.other (lazy backfill)',
        () {
      final data = {
        'title': 'Old item no category',
        'description': 'Legacy',
        'category': 'seeker',
        'status': 'active',
        'location': 'Gate',
        'contact': '0812345678',
        'imageUrls': <String>[],
        'userId': 'uid-002',
        'createdAt': Timestamp.fromDate(DateTime(2026, 4, 1)),
        'occurredAt': Timestamp.fromDate(DateTime(2026, 4, 1)),
        // no itemCategory field
      };

      final entity = ItemModel.fromMap('id-2', data).toEntity();

      expect(entity.itemTaxonomy, equals(ItemTaxonomy.other));
    });

    test('toFirestore includes itemCategory key', () {
      final model = ItemModel(
        id: 'item-001',
        title: 'Found watch',
        description: 'Silver watch',
        category: 'founder',
        status: 'active',
        location: 'Gym',
        contact: '0812345678',
        imageUrls: const [],
        userId: 'uid-001',
        createdAt: DateTime(2026, 5, 1),
        occurredAt: DateTime(2026, 5, 1),
        itemCategory: 'accessory',
      );

      final payload = model.toFirestore();

      expect(payload.containsKey('itemCategory'), isTrue);
      expect(payload['itemCategory'], equals('accessory'));
    });

    test('toFirestore falls back to "other" when itemCategory is null', () {
      final model = ItemModel(
        id: 'item-002',
        title: 'Old item',
        description: '',
        category: 'seeker',
        status: 'active',
        location: 'Gate',
        contact: '0812345678',
        imageUrls: const [],
        userId: 'uid-002',
        createdAt: DateTime(2026, 4, 1),
        occurredAt: DateTime(2026, 4, 1),
        // itemCategory not set
      );

      final payload = model.toFirestore();

      expect(payload['itemCategory'], equals('other'));
    });
  });

  group('ItemModel round-trip — WBS 2.1 / 2.2', () {
    test('entity → toFirestore → fromFirestore → entity preserves occurredAt',
        () async {
      final original = Item(
        id: 'ignored',
        title: 'Lost wallet',
        description: 'Brown leather wallet',
        category: ItemCategory.seeker,
        status: ItemStatus.active,
        location: 'Library',
        contact: '0812345678',
        imageUrls: const ['https://example.com/img.jpg'],
        userId: 'uid-001',
        createdAt: DateTime(2026, 4, 27, 14, 30),
        occurredAt: DateTime(2026, 4, 26, 9, 15),
      );

      final payload = ItemModel.fromEntity(original).toFirestore();
      // Datasource normally injects these — simulate that here so the
      // doc is well-formed for fromFirestore.
      payload['createdAt'] = Timestamp.fromDate(original.createdAt);

      final ref = await fakeFirestore.collection('items').add(payload);
      final doc = await ref.get();
      final reconstructed = ItemModel.fromFirestore(doc).toEntity();

      expect(reconstructed.occurredAt, equals(original.occurredAt));
      expect(reconstructed.title, equals(original.title));
      expect(reconstructed.category, equals(original.category));
      expect(reconstructed.status, equals(original.status));
      expect(reconstructed.userId, equals(original.userId));
      expect(reconstructed.imageUrls, equals(original.imageUrls));
    });
  });
}
