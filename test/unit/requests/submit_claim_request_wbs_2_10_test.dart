// WBS 2.10 — SubmitClaimRequestUseCase validation guards
//
// Tests the two enforcement rules added to the use case:
//   Rule A — canResubmit() returns !allowed → throws ResubmitNotAllowedFailure
//            before any item fetch or submitRequest call.
//   Rule B — item.secretQuestion set + visitorAnswer blank/null
//            → throws SecretAnswerRequiredFailure.
//            item.secretQuestion null → proceeds without throwing.

import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/domain/entities/resubmit_decision.dart';
import 'package:campus_lost_found/features/requests/domain/errors/resubmit_not_allowed_failure.dart';
import 'package:campus_lost_found/features/requests/domain/errors/secret_answer_required_failure.dart';
import 'package:campus_lost_found/features/requests/domain/repositories/item_request_repository.dart';
import 'package:campus_lost_found/features/requests/domain/usecases/submit_claim_request_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockItemRequestRepository extends Mock implements ItemRequestRepository {}

class _MockItemRepository extends Mock implements ItemRepository {}

final _fallbackRequest = ItemRequest(
  id: '',
  itemId: 'item-fallback',
  requesterId: 'uid-fallback',
  requesterName: 'Fallback',
  requesterContact: '0800000000',
  studentId: '00000000',
  type: RequestType.claim,
  status: RequestStatus.pending,
  createdAt: DateTime(2024),
);

Item _makeItem({String? secretQuestion}) => Item(
      id: 'item-001',
      title: 'Wallet',
      description: 'Black wallet',
      category: ItemCategory.founder,
      status: ItemStatus.active,
      location: 'Building A',
      contact: '0800000000',
      imageUrls: const [],
      userId: 'poster-uid',
      createdAt: DateTime(2026),
      occurredAt: DateTime(2026),
      secretQuestion: secretQuestion,
    );

void main() {
  late _MockItemRequestRepository requestRepo;
  late _MockItemRepository itemRepo;
  late SubmitClaimRequestUseCase useCase;

  final tBaseParams = SubmitClaimRequestParams(
    itemId: 'item-001',
    requesterId: 'user-seeker-001',
    requesterName: 'Alice Smith',
    requesterContact: '0812345678',
    studentId: '63070001',
  );

  setUpAll(() => registerFallbackValue(_fallbackRequest));

  setUp(() {
    requestRepo = _MockItemRequestRepository();
    itemRepo = _MockItemRepository();
    useCase = SubmitClaimRequestUseCase(requestRepo, itemRepo);
  });

  // ── Rule A ────────────────────────────────────────────────────────────────

  test(
    'WBS 2.10 Rule A — throws ResubmitNotAllowedFailure when canResubmit() '
    'returns alreadyActive, without calling watchItem or submitRequest',
    () async {
      when(() => requestRepo.canResubmit(
            itemId: any(named: 'itemId'),
            requesterId: any(named: 'requesterId'),
          )).thenAnswer((_) async => const ResubmitDecision.alreadyActive());

      await expectLater(
        () => useCase(tBaseParams),
        throwsA(
          isA<ResubmitNotAllowedFailure>().having(
            (f) => f.reason,
            'reason',
            ResubmitReason.alreadyActive,
          ),
        ),
      );

      verifyNever(() => itemRepo.watchItem(any()));
      verifyNever(() => requestRepo.submitRequest(any()));
    },
  );

  // ── Rule B — secretQuestion set, no answer ────────────────────────────────

  test(
    'WBS 2.10 Rule B — throws SecretAnswerRequiredFailure when '
    'item.secretQuestion is set and visitorAnswer is null',
    () async {
      when(() => requestRepo.canResubmit(
            itemId: any(named: 'itemId'),
            requesterId: any(named: 'requesterId'),
          )).thenAnswer((_) async => const ResubmitDecision.allowed());
      when(() => itemRepo.watchItem('item-001'))
          .thenAnswer((_) => Stream.value(_makeItem(secretQuestion: 'What brand?')));

      await expectLater(
        () => useCase(tBaseParams.copyWith(visitorAnswer: null)),
        throwsA(isA<SecretAnswerRequiredFailure>()),
      );

      verifyNever(() => requestRepo.submitRequest(any()));
    },
  );

  test(
    'WBS 2.10 Rule B — throws SecretAnswerRequiredFailure when '
    'item.secretQuestion is set and visitorAnswer is blank whitespace',
    () async {
      when(() => requestRepo.canResubmit(
            itemId: any(named: 'itemId'),
            requesterId: any(named: 'requesterId'),
          )).thenAnswer((_) async => const ResubmitDecision.allowed());
      when(() => itemRepo.watchItem('item-001'))
          .thenAnswer((_) => Stream.value(_makeItem(secretQuestion: 'What brand?')));

      await expectLater(
        () => useCase(tBaseParams.copyWith(visitorAnswer: '   ')),
        throwsA(isA<SecretAnswerRequiredFailure>()),
      );

      verifyNever(() => requestRepo.submitRequest(any()));
    },
  );

  // ── Rule B — no secretQuestion, no answer → succeeds ─────────────────────

  test(
    'WBS 2.10 Rule B — proceeds to submitRequest when item.secretQuestion '
    'is null and visitorAnswer is null (no question, no answer required)',
    () async {
      when(() => requestRepo.canResubmit(
            itemId: any(named: 'itemId'),
            requesterId: any(named: 'requesterId'),
          )).thenAnswer((_) async => const ResubmitDecision.allowed());
      when(() => itemRepo.watchItem('item-001'))
          .thenAnswer((_) => Stream.value(_makeItem(secretQuestion: null)));
      when(() => requestRepo.submitRequest(any())).thenAnswer((inv) async =>
          inv.positionalArguments[0] as ItemRequest);

      await useCase(tBaseParams.copyWith(visitorAnswer: null));

      verify(() => requestRepo.submitRequest(any())).called(1);
    },
  );
}

// ---------------------------------------------------------------------------
// Helper: SubmitClaimRequestParams.copyWith — not on the domain class itself;
// defined locally to keep tests readable.
// ---------------------------------------------------------------------------
extension _ParamsCopyWith on SubmitClaimRequestParams {
  SubmitClaimRequestParams copyWith({String? visitorAnswer}) =>
      SubmitClaimRequestParams(
        itemId: itemId,
        requesterId: requesterId,
        requesterName: requesterName,
        requesterContact: requesterContact,
        studentId: studentId,
        message: message,
        visitorAnswer: visitorAnswer,
      );
}
