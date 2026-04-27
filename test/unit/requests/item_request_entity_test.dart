// WBS 2.1 — Domain Entities & Repository Interfaces
// Covers: ItemRequest entity, RequestStatus enum
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
          message: 'I found this item.',
          status: RequestStatus.pending,
          createdAt: baseCreatedAt,
          visitorAnswer: '',
        );
        expect(request.visitorAnswer, '');
      });
    });

    group('status transitions', () {
      ItemRequest makeRequest(RequestStatus status) => ItemRequest(
            id: 'req-status',
            itemId: 'item-status',
            requesterId: 'uid-status',
            requesterName: 'Test User',
            requesterContact: '0856789012',
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

    group('no Firebase or Flutter imports in domain layer', () {
      // Confirms the entity is constructable without any Firebase initialisation.
      test('ItemRequest can be constructed without Firebase initialisation', () {
        final request = ItemRequest(
          id: 'no-firebase',
          itemId: 'item-no-firebase',
          requesterId: 'uid-no-firebase',
          requesterName: 'Pure Dart',
          requesterContact: '0000000000',
          message: 'Verifies pure Dart construction',
          status: RequestStatus.pending,
          createdAt: DateTime(2025),
        );
        expect(request.id, 'no-firebase');
      });
    });
  });
}
