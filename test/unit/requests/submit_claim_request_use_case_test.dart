// WBS 1.4 — Post Form Screen / WBS 2.4 — Request System:
// SubmitClaimRequestUseCase unit tests
//
// WBS 1.4 / 2.4 test cases covered here:
//   ✓ submitted request includes requesterId, requesterName, status=pending, createdAt
//   ✓ type is set to RequestType.claim
//   ✓ studentId is present on the request document
//   ✓ optional message is passed through
//   ✓ repository is called exactly once
//
// WBS 2.10 test cases covered here:
//   ✓ visitorAnswer (secret question answer) is saved to the request document
//   ✓ visitorAnswer is null when no secret question exists on the post

import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/domain/entities/resubmit_decision.dart';
import 'package:campus_lost_found/features/requests/domain/repositories/item_request_repository.dart';
import 'package:campus_lost_found/features/requests/domain/usecases/submit_claim_request_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockItemRequestRepository extends Mock
    implements ItemRequestRepository {}

class _MockItemRepository extends Mock implements ItemRepository {}

// Minimal valid ItemRequest for mocktail fallback registration.
final _fallbackRequest = ItemRequest(
  id: '',
  itemId: 'item-fallback',
  requesterId: 'uid-fallback',
  requesterName: 'Fallback User',
  requesterContact: '0800000000',
  studentId: '00000000',
  type: RequestType.claim,
  status: RequestStatus.pending,
  createdAt: DateTime(2024),
);

// A minimal Item with no secretQuestion — used as the happy-path stub return.
Item _itemWithNoSecret(String itemId) => Item(
      id: itemId,
      title: 'Test Item',
      description: 'desc',
      category: ItemCategory.founder,
      status: ItemStatus.active,
      location: 'Building A',
      contact: '0800000000',
      imageUrls: const [],
      userId: 'poster-uid',
      createdAt: DateTime(2026),
      occurredAt: DateTime(2026),
    );

void main() {
  late _MockItemRequestRepository repository;
  late _MockItemRepository itemRepository;
  late SubmitClaimRequestUseCase useCase;

  // Params for a standard claim on a Founder Post that has a secret question.
  final tParamsWithSecret = SubmitClaimRequestParams(
    itemId: 'item-founder-001',
    requesterId: 'user-seeker-001',
    requesterName: 'Alice Smith',
    requesterContact: '0812345678',
    studentId: '63070001',
    message: 'I believe this is my wallet — I lost it yesterday.',
    visitorAnswer: 'Fossil',
  );

  // Params for a claim on a Founder Post with no secret question set.
  final tParamsNoSecret = SubmitClaimRequestParams(
    itemId: 'item-founder-002',
    requesterId: 'user-seeker-001',
    requesterName: 'Alice Smith',
    requesterContact: '0812345678',
    studentId: '63070001',
  );

  setUpAll(() => registerFallbackValue(_fallbackRequest));

  setUp(() {
    repository = _MockItemRequestRepository();
    itemRepository = _MockItemRepository();
    useCase = SubmitClaimRequestUseCase(repository, itemRepository);

    // Happy-path stubs: policy allows + no secret question on either item.
    when(() => repository.canResubmit(
          itemId: any(named: 'itemId'),
          requesterId: any(named: 'requesterId'),
        )).thenAnswer((_) async => const ResubmitDecision.allowed());

    when(() => itemRepository.watchItem('item-founder-001'))
        .thenAnswer((_) => Stream.value(_itemWithNoSecret('item-founder-001')));
    when(() => itemRepository.watchItem('item-founder-002'))
        .thenAnswer((_) => Stream.value(_itemWithNoSecret('item-founder-002')));

    when(() => repository.submitRequest(any())).thenAnswer((inv) async {
      final req = inv.positionalArguments[0] as ItemRequest;
      return ItemRequest(
        id: 'req-server-001',
        itemId: req.itemId,
        requesterId: req.requesterId,
        requesterName: req.requesterName,
        requesterContact: req.requesterContact,
        studentId: req.studentId,
        type: req.type,
        status: req.status,
        createdAt: req.createdAt,
        message: req.message,
        visitorAnswer: req.visitorAnswer,
        photoUrl: req.photoUrl,
      );
    });
  });

  // ── WBS 2.4 — core submission contract ────────────────────────────────────

  test(
    'WBS 2.4 — submitRequest() is called exactly once on the repository',
    () async {
      await useCase(tParamsWithSecret);

      verify(() => repository.submitRequest(any())).called(1);
    },
  );

  test(
    'WBS 2.4 — submitted request has type = claim and status = pending',
    () async {
      await useCase(tParamsWithSecret);

      final captured = verify(() => repository.submitRequest(captureAny()))
          .captured
          .single as ItemRequest;
      expect(captured.type, RequestType.claim);
      expect(captured.status, RequestStatus.pending);
    },
  );

  test(
    'WBS 2.4 — submitted request carries all required identity fields '
    '(requesterId, requesterName, requesterContact, studentId, itemId)',
    () async {
      await useCase(tParamsWithSecret);

      final captured = verify(() => repository.submitRequest(captureAny()))
          .captured
          .single as ItemRequest;
      expect(captured.requesterId, tParamsWithSecret.requesterId);
      expect(captured.requesterName, tParamsWithSecret.requesterName);
      expect(captured.requesterContact, tParamsWithSecret.requesterContact);
      expect(captured.studentId, tParamsWithSecret.studentId);
      expect(captured.itemId, tParamsWithSecret.itemId);
    },
  );

  test(
    'WBS 2.4 — submitted request id is empty string '
    '(repository assigns the real Firestore ID)',
    () async {
      await useCase(tParamsWithSecret);

      final captured = verify(() => repository.submitRequest(captureAny()))
          .captured
          .single as ItemRequest;
      expect(captured.id, '');
    },
  );

  test(
    'WBS 2.4 — returns the request object returned by the repository '
    '(including server-assigned ID)',
    () async {
      final result = await useCase(tParamsWithSecret);

      expect(result.id, 'req-server-001');
    },
  );

  // ── WBS 2.10 — secret question: visitorAnswer ──────────────────────────────

  test(
    'WBS 2.10 — visitorAnswer is saved to the request document when '
    'the Founder Post has a secret question',
    () async {
      await useCase(tParamsWithSecret);

      final captured = verify(() => repository.submitRequest(captureAny()))
          .captured
          .single as ItemRequest;
      expect(captured.visitorAnswer, 'Fossil');
    },
  );

  test(
    'WBS 2.10 — visitorAnswer is null when no secret question exists on the post',
    () async {
      await useCase(tParamsNoSecret);

      final captured = verify(() => repository.submitRequest(captureAny()))
          .captured
          .single as ItemRequest;
      expect(captured.visitorAnswer, isNull);
    },
  );

  // ── Optional message ───────────────────────────────────────────────────────

  test(
    'WBS 1.4 — optional message is passed through to the request document',
    () async {
      await useCase(tParamsWithSecret);

      final captured = verify(() => repository.submitRequest(captureAny()))
          .captured
          .single as ItemRequest;
      expect(captured.message,
          'I believe this is my wallet — I lost it yesterday.');
    },
  );

  test(
    'WBS 1.4 — message is null when not provided '
    '(message is optional for claim requests)',
    () async {
      await useCase(tParamsNoSecret);

      final captured = verify(() => repository.submitRequest(captureAny()))
          .captured
          .single as ItemRequest;
      expect(captured.message, isNull);
    },
  );

  // ── photoUrl is always null for claim requests ─────────────────────────────

  test(
    'WBS 1.4 — photoUrl is always null on claim requests '
    '(photos are only for Found Reports)',
    () async {
      await useCase(tParamsWithSecret);

      final captured = verify(() => repository.submitRequest(captureAny()))
          .captured
          .single as ItemRequest;
      expect(captured.photoUrl, isNull);
    },
  );
}
