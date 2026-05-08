import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

void main() {
  final now = DateTime(2025, 5, 1, 12, 0);
  final occurredAt = DateTime(2025, 4, 28, 9, 0);
  final editedAt = DateTime(2025, 4, 30, 14, 30);

  // ── ItemCategory enum ──────────────────────────────────────────────────────

  group('ItemCategory.fromString()', () {
    test('parses "seeker"', () {
      expect(ItemCategory.fromString('seeker'), ItemCategory.seeker);
    });

    test('parses "founder"', () {
      expect(ItemCategory.fromString('founder'), ItemCategory.founder);
    });

    test('throws on unknown category', () {
      expect(
        () => ItemCategory.fromString('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ── ItemStatus enum ────────────────────────────────────────────────────────

  group('ItemStatus.fromString()', () {
    test('parses "active"', () {
      expect(ItemStatus.fromString('active'), ItemStatus.active);
    });

    test('parses "resolved"', () {
      expect(ItemStatus.fromString('resolved'), ItemStatus.resolved);
    });

    // WBS 2.14 — Cloud Function sets status to 'expired' after 14 days
    test('parses "expired"', () {
      expect(ItemStatus.fromString('expired'), ItemStatus.expired);
    });

    test('byName resolves "expired" without error', () {
      expect(ItemStatus.values.byName('expired'), ItemStatus.expired);
    });

    test('throws on unknown status', () {
      expect(
        () => ItemStatus.fromString('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ── ItemSource enum ────────────────────────────────────────────────────────

  group('ItemSource.fromString()', () {
    test('parses "qr_walk_in"', () {
      expect(ItemSource.fromString('qr_walk_in'), ItemSource.qrWalkIn);
    });

    test('defaults to web for unknown or empty', () {
      expect(ItemSource.fromString('web'), ItemSource.web);
      expect(ItemSource.fromString('unknown'), ItemSource.web);
    });
  });

  // ── Item.copyWith() ────────────────────────────────────────────────────────

  group('Item.copyWith()', () {
    late Item original;

    setUp(() {
      original = Item(
        id: 'item-001',
        title: 'Lost wallet',
        description: 'Brown leather wallet with student card',
        category: ItemCategory.seeker,
        status: ItemStatus.active,
        location: 'Library floor 3',
        contact: '0812345678',
        imageUrls: const ['https://example.com/img1.jpg'],
        userId: 'user-001',
        createdAt: now,
        occurredAt: occurredAt,
        source: ItemSource.web,
        isSensitive: false,
        editedAt: editedAt,
        claimedBy: null,
        secretQuestion: null,
        secretAnswer: null,
      );
    });

    test('preserves all fields when called with no arguments', () {
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.description, original.description);
      expect(copy.category, original.category);
      expect(copy.status, original.status);
      expect(copy.location, original.location);
      expect(copy.contact, original.contact);
      expect(copy.imageUrls, original.imageUrls);
      expect(copy.userId, original.userId);
      expect(copy.createdAt, original.createdAt);
      expect(copy.occurredAt, original.occurredAt);
      expect(copy.source, original.source);
      expect(copy.isSensitive, original.isSensitive);
      expect(copy.editedAt, original.editedAt);
      expect(copy.claimedBy, original.claimedBy);
    });

    test('updates single fields', () {
      final updated = original.copyWith(
        title: 'Updated title',
        status: ItemStatus.resolved,
      );
      expect(updated.title, 'Updated title');
      expect(updated.status, ItemStatus.resolved);
      expect(updated.id, original.id);
      expect(updated.category, original.category);
    });

    test('preserves optional fields when not specified in copyWith', () {
      final copy = original.copyWith(title: 'New title');
      expect(copy.editedAt, original.editedAt);
      expect(copy.claimedBy, original.claimedBy);
      expect(copy.secretQuestion, original.secretQuestion);
    });

    test('updates complex fields like imageUrls', () {
      final newImages = [
        'https://example.com/img2.jpg',
        'https://example.com/img3.jpg'
      ];
      final updated = original.copyWith(imageUrls: newImages);
      expect(updated.imageUrls, newImages);
    });

    test('sets isSensitive flag', () {
      final sensitive = original.copyWith(isSensitive: true);
      expect(sensitive.isSensitive, true);
      expect(sensitive.id, original.id);
    });

    test('can modify all fields simultaneously', () {
      final expiresAt = DateTime(2025, 6, 1);
      final updated = original.copyWith(
        id: 'new-id',
        title: 'New title',
        description: 'New description',
        category: ItemCategory.founder,
        status: ItemStatus.resolved,
        location: 'New location',
        contact: '0987654321',
        imageUrls: const [],
        userId: 'new-user-id',
        source: ItemSource.qrWalkIn,
        isSensitive: true,
        createdAt: DateTime(2025, 1, 1),
        occurredAt: DateTime(2025, 1, 2),
        editedAt: DateTime(2025, 1, 3),
        expiresAt: expiresAt,
        claimedBy: 'claimer-id',
        secretQuestion: 'Secret?',
        secretAnswer: 'Answer',
      );
      expect(updated.id, 'new-id');
      expect(updated.title, 'New title');
      expect(updated.category, ItemCategory.founder);
      expect(updated.isSensitive, true);
      expect(updated.expiresAt, expiresAt);
      expect(updated.claimedBy, 'claimer-id');
    });
  });
}
