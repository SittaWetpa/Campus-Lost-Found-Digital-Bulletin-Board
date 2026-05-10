// WBS 2.1 — Domain Entities & Repository Interfaces
// Covers: ItemRequest entity, RequestStatus enum, RequestType enum
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── RequestStatus.fromString() ───────────────────────────────────────────

  group('RequestStatus.fromString()', () {
    test('returns pending for "pending"', () {
      expect(RequestStatus.fromString('pending'), RequestStatus.pending);
    });

    test('returns approved for "approved"', () {
      expect(RequestStatus.fromString('approved'), RequestStatus.approved);
    });

    test('returns rejected for "rejected"', () {
      expect(RequestStatus.fromString('rejected'), RequestStatus.rejected);
    });

    test('returns cancelled for "cancelled"', () {
      expect(RequestStatus.fromString('cancelled'), RequestStatus.cancelled);
    });

    test('throws ArgumentError for an unrecognised value', () {
      expect(
        () => RequestStatus.fromString('open'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unknown RequestStatus'),
          ),
        ),
      );
    });

    test('throws ArgumentError for an empty string', () {
      expect(
        () => RequestStatus.fromString(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for a value with wrong capitalisation', () {
      expect(
        () => RequestStatus.fromString('Pending'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for "returned" (old term replaced by resolved)', () {
      expect(
        () => RequestStatus.fromString('returned'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ── RequestType.fromString() ─────────────────────────────────────────────

  group('RequestType.fromString()', () {
    test('returns claim for "claim"', () {
      expect(RequestType.fromString('claim'), RequestType.claim);
    });

    test('returns found for "found"', () {
      expect(RequestType.fromString('found'), RequestType.found);
    });

    test('throws ArgumentError for an unrecognised value', () {
      expect(
        () => RequestType.fromString('report'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ── ItemRequest constructor ──────────────────────────────────────────────

  group('ItemRequest', () {
    final baseCreatedAt = DateTime(2025, 3, 20, 14, 0);

    group('required fields', () {
      late ItemRequest request;

      setUp(() {
        request = ItemRequest(
          id: 'req-001',
          itemId: 'item-001',
          requesterId: 'uid-requester',
          requesterName: 'Alice Smith',
          requesterContact: '0812345678',
          studentId: '63070001',
          type: RequestType.claim,
          message: 'I believe this is my wallet. It has my student ID inside.',
          status: RequestStatus.pending,
          createdAt: baseCreatedAt,
        );
      });

      test('stores id correctly', () {
        expect(request.id, 'req-001');
      });

      test('stores itemId correctly', () {
        expect(request.itemId, 'item-001');
      });

      test('stores requesterId correctly', () {
        expect(request.requesterId, 'uid-requester');
      });

      test('stores requesterName correctly', () {
        expect(request.requesterName, 'Alice Smith');
      });

      test('stores requesterContact correctly', () {
        expect(request.requesterContact, '0812345678');
      });

      test('stores studentId correctly (WBS 1.4)', () {
        expect(request.studentId, '63070001');
      });

      test('stores type correctly (WBS 1.4)', () {
        expect(request.type, RequestType.claim);
      });

      test('stores message correctly', () {
        expect(
          request.message,
          'I believe this is my wallet. It has my student ID inside.',
        );
      });

      test('stores status correctly', () {
        expect(request.status, RequestStatus.pending);
      });

      test('stores createdAt correctly', () {
        expect(request.createdAt, baseCreatedAt);
      });
    });

    group('visitorAnswer (WBS 2.10)', () {
      test('visitorAnswer defaults to null when not provided', () {
        final request = ItemRequest(
          id: 'req-002',
          itemId: 'item-002',
          requesterId: 'uid-002',
          requesterName: 'Bob Jones',
          requesterContact: '0823456789',
          studentId: '63070002',
          type: RequestType.claim,
          message: 'This is my item.',
          status: RequestStatus.pending,
          createdAt: baseCreatedAt,
        );
        expect(request.visitorAnswer, isNull);
      });

      test('visitorAnswer is stored when provided (Claim Request with secret question)', () {
        final request = ItemRequest(
          id: 'req-003',
          itemId: 'item-003',
          requesterId: 'uid-003',
          requesterName: 'Carol Lee',
          requesterContact: '0834567890',
          studentId: '63070003',
          type: RequestType.claim,
          message: 'I lost this item last Tuesday.',
          status: RequestStatus.pending,
          createdAt: baseCreatedAt,
          visitorAnswer: 'The brand printed inside is Fossil',
        );
        expect(request.visitorAnswer, 'The brand printed inside is Fossil');
      });

      test('visitorAnswer can be an empty string when explicitly set', () {
        final request = ItemRequest(
          id: 'req-004',
          itemId: 'item-004',
          requesterId: 'uid-004',
          requesterName: 'Dave Park',
          requesterContact: '0845678901',
          studentId: '63070004',
          type: RequestType.claim,
          message: 'I found this item.',
          status: RequestStatus.pending,
          createdAt: baseCreatedAt,
          visitorAnswer: '',
        );
        expect(request.visitorAnswer, '');
      });
    });

    group('type variants (WBS 1.4)', () {
      test('type claim — seeker asserts ownership on a Founder Post', () {
        final req = ItemRequest(
          id: 'r', itemId: 'i', requesterId: 'u', requesterName: 'N',
          requesterContact: '0800000000', studentId: '00000000',
          type: RequestType.claim,
          status: RequestStatus.pending, createdAt: baseCreatedAt,
        );
        expect(req.type, RequestType.claim);
      });

      test('type found — third party reports finding a Seeker\'s item', () {
        final req = ItemRequest(
          id: 'r', itemId: 'i', requesterId: 'u', requesterName: 'N',
          requesterContact: '0800000000', studentId: '00000000',
          type: RequestType.found,
          status: RequestStatus.pending, createdAt: baseCreatedAt,
        );
        expect(req.type, RequestType.found);
      });
    });

    group('photoUrl (WBS 2.4)', () {
      test('photoUrl defaults to null when not provided', () {
        final req = ItemRequest(
          id: 'r', itemId: 'i', requesterId: 'u', requesterName: 'N',
          requesterContact: '0800000000', studentId: '00000000',
          type: RequestType.found,
          status: RequestStatus.pending, createdAt: baseCreatedAt,
        );
        expect(req.photoUrl, isNull);
      });

      test('photoUrl is stored when provided (Found Report photo)', () {
        final req = ItemRequest(
          id: 'r', itemId: 'i', requesterId: 'u', requesterName: 'N',
          requesterContact: '0800000000', studentId: '00000000',
          type: RequestType.found,
          status: RequestStatus.pending, createdAt: baseCreatedAt,
          photoUrl: 'https://storage.example.com/photo.jpg',
        );
        expect(req.photoUrl, 'https://storage.example.com/photo.jpg');
      });
    });

    group('status transitions', () {
      ItemRequest makeRequest(RequestStatus status) => ItemRequest(
            id: 'req-status',
            itemId: 'item-status',
            requesterId: 'uid-status',
            requesterName: 'Test User',
            requesterContact: '0856789012',
            studentId: '63070005',
            type: RequestType.claim,
            message: 'Test message',
            status: status,
            createdAt: baseCreatedAt,
          );

      test('status can be pending (initial state)', () {
        expect(makeRequest(RequestStatus.pending).status, RequestStatus.pending);
      });

      test('status can be approved (after Poster approves)', () {
        expect(makeRequest(RequestStatus.approved).status, RequestStatus.approved);
      });

      test('status can be rejected (after Poster rejects)', () {
        expect(makeRequest(RequestStatus.rejected).status, RequestStatus.rejected);
      });

      test('status can be cancelled (after requester cancels, WBS 2.4)', () {
        expect(makeRequest(RequestStatus.cancelled).status, RequestStatus.cancelled);
      });
    });

    group('editedAt (WBS 2.10 / 2.17)', () {
      test('editedAt defaults to null on a new request', () {
        final request = ItemRequest(
          id: 'r', itemId: 'i', requesterId: 'u', requesterName: 'N',
          requesterContact: '0800000000', studentId: '00000000',
          type: RequestType.claim, status: RequestStatus.pending,
          createdAt: baseCreatedAt,
        );
        expect(request.editedAt, isNull);
      });

      test('editedAt is stored when provided', () {
        final edited = DateTime(2026, 1, 15, 10, 30);
        final request = ItemRequest(
          id: 'r', itemId: 'i', requesterId: 'u', requesterName: 'N',
          requesterContact: '0800000000', studentId: '00000000',
          type: RequestType.claim, status: RequestStatus.pending,
          createdAt: baseCreatedAt,
          editedAt: edited,
        );
        expect(request.editedAt, edited);
      });

      test('copyWith(editedAt: ...) returns updated value without mutating original', () {
        final base = ItemRequest(
          id: 'r', itemId: 'i', requesterId: 'u', requesterName: 'N',
          requesterContact: '0800000000', studentId: '00000000',
          type: RequestType.claim, status: RequestStatus.pending,
          createdAt: baseCreatedAt,
        );
        final edited = DateTime(2026, 3, 1, 12, 0);
        final copy = base.copyWith(editedAt: edited);
        expect(copy.editedAt, edited);
        expect(base.editedAt, isNull);
      });
    });

    group('copyWith()', () {
      late ItemRequest base;

      setUp(() {
        base = ItemRequest(
          id: 'req-cw',
          itemId: 'item-cw',
          requesterId: 'uid-cw',
          requesterName: 'Copy User',
          requesterContact: '0800000099',
          studentId: '63099999',
          type: RequestType.claim,
          status: RequestStatus.pending,
          createdAt: baseCreatedAt,
        );
      });

      test('returns an equal object when no fields are overridden', () {
        final copy = base.copyWith();
        expect(copy.id, base.id);
        expect(copy.itemId, base.itemId);
        expect(copy.requesterId, base.requesterId);
        expect(copy.requesterName, base.requesterName);
        expect(copy.requesterContact, base.requesterContact);
        expect(copy.studentId, base.studentId);
        expect(copy.type, base.type);
        expect(copy.status, base.status);
        expect(copy.createdAt, base.createdAt);
        expect(copy.message, base.message);
        expect(copy.visitorAnswer, base.visitorAnswer);
        expect(copy.photoUrl, base.photoUrl);
        expect(copy.editedAt, base.editedAt);
      });

      test('overrides status only', () {
        final copy = base.copyWith(status: RequestStatus.approved);
        expect(copy.status, RequestStatus.approved);
        expect(copy.id, base.id);
      });

      test('overrides multiple fields simultaneously', () {
        final newDate = DateTime(2025, 6, 1);
        final copy = base.copyWith(
          message: 'Updated message',
          photoUrl: 'https://storage.example.com/photo.jpg',
          createdAt: newDate,
        );
        expect(copy.message, 'Updated message');
        expect(copy.photoUrl, 'https://storage.example.com/photo.jpg');
        expect(copy.createdAt, newDate);
        expect(copy.id, base.id);
      });

      test('does not mutate the original instance', () {
        base.copyWith(status: RequestStatus.rejected);
        expect(base.status, RequestStatus.pending);
      });

      test('can set visitorAnswer via copyWith', () {
        final copy = base.copyWith(visitorAnswer: 'Blue with a scratch');
        expect(copy.visitorAnswer, 'Blue with a scratch');
        expect(base.visitorAnswer, isNull);
      });
    });

    group('no Firebase or Flutter imports in domain layer', () {
      // Confirms the entity is constructable without any Firebase initialisation.
      test('ItemRequest can be constructed without Firebase initialisation', () {
        final request = ItemRequest(
          id: 'no-firebase',
          itemId: 'item-no-firebase',
          requesterId: 'uid-no-firebase',
          requesterName: 'Pure Dart',
          requesterContact: '0000000000',
          studentId: '00000000',
          type: RequestType.claim,
          message: 'Verifies pure Dart construction',
          status: RequestStatus.pending,
          createdAt: DateTime(2025),
        );
        expect(request.id, 'no-firebase');
      });
    });
  });
}
