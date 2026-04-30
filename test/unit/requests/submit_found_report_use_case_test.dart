// WBS 1.4 — Post Form Screen / WBS 2.4 — Request System:
// SubmitFoundReportUseCase unit tests
//
// WBS 1.4 / 2.4 test cases covered here:
//   ✓ submitted request includes requesterId, requesterName, status=pending, createdAt
//   ✓ type is set to RequestType.found
//   ✓ studentId is present on the request document
//   ✓ message ≥ 20 chars invariant: throws ArgumentError below threshold
//   ✓ message is trimmed before being stored
//   ✓ optional photoUrl is passed through (max 1 photo)
//   ✓ repository is called exactly once on a valid report

import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/domain/repositories/item_request_repository.dart';
import 'package:campus_lost_found/features/requests/domain/usecases/submit_found_report_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockItemRequestRepository extends Mock
    implements ItemRequestRepository {}

// Minimal valid ItemRequest for mocktail fallback registration.
final _fallbackRequest = ItemRequest(
  id: '',
  itemId: 'item-fallback',
  requesterId: 'uid-fallback',
  requesterName: 'Fallback User',
  requesterContact: '0800000000',
  studentId: '00000000',
  type: RequestType.found,
  status: RequestStatus.pending,
  createdAt: DateTime(2024),
);

ItemRequest _stubResponse(ItemRequest req) => ItemRequest(
      id: 'req-server-002',
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

void main() {
  late _MockItemRequestRepository repository;
  late SubmitFoundReportUseCase useCase;

  // A valid Found Report — description is ≥ 20 chars.
  final tValidParams = SubmitFoundReportParams(
    itemId: 'item-seeker-001',
    requesterId: 'user-finder-001',
    requesterName: 'Bob Jones',
    requesterContact: '0898765432',
    studentId: '63070002',
    message: 'White AirPods Pro case with a tiny scratch on the hinge — '
        'I found them by the printer in LIB-1.',
    photoUrl: 'https://storage.example.com/found-photo.jpg',
  );

  setUpAll(() => registerFallbackValue(_fallbackRequest));

  setUp(() {
    repository = _MockItemRequestRepository();
    useCase = SubmitFoundReportUseCase(repository);
    when(() => repository.submitRequest(any()))
        .thenAnswer((inv) async => _stubResponse(
              inv.positionalArguments[0] as ItemRequest,
            ));
  });

  // ── WBS 1.4 — message length invariant (domain-enforced) ──────────────────

  group('message length invariant (≥ 20 characters)', () {
    test(
      'WBS 1.4 — throws ArgumentError for empty message',
      () {
        final params = SubmitFoundReportParams(
          itemId: 'item-seeker-001',
          requesterId: 'user-finder-001',
          requesterName: 'Bob Jones',
          requesterContact: '0898765432',
          studentId: '63070002',
          message: '',
        );

        expect(() => useCase(params), throwsArgumentError);
        verifyNever(() => repository.submitRequest(any()));
      },
    );

    test(
      'WBS 1.4 — throws ArgumentError for message that is exactly 19 characters '
      '(one below the minimum)',
      () {
        final params = SubmitFoundReportParams(
          itemId: 'item-seeker-001',
          requesterId: 'user-finder-001',
          requesterName: 'Bob Jones',
          requesterContact: '0898765432',
          studentId: '63070002',
          message: 'a' * 19,
        );

        expect(() => useCase(params), throwsArgumentError);
        verifyNever(() => repository.submitRequest(any()));
      },
    );

    test(
      'WBS 1.4 — throws ArgumentError when message is all whitespace '
      '(trimmed length < 20)',
      () {
        final params = SubmitFoundReportParams(
          itemId: 'item-seeker-001',
          requesterId: 'user-finder-001',
          requesterName: 'Bob Jones',
          requesterContact: '0898765432',
          studentId: '63070002',
          message: ' ' * 25,
        );

        expect(() => useCase(params), throwsArgumentError);
        verifyNever(() => repository.submitRequest(any()));
      },
    );

    test(
      'WBS 1.4 — succeeds when message is exactly 20 characters (boundary)',
      () async {
        final params = SubmitFoundReportParams(
          itemId: 'item-seeker-001',
          requesterId: 'user-finder-001',
          requesterName: 'Bob Jones',
          requesterContact: '0898765432',
          studentId: '63070002',
          message: 'a' * 20,
        );

        await expectLater(useCase(params), completes);
        verify(() => repository.submitRequest(any())).called(1);
      },
    );

    test(
      'WBS 1.4 — succeeds when trimmed message is exactly 20 characters',
      () async {
        final params = SubmitFoundReportParams(
          itemId: 'item-seeker-001',
          requesterId: 'user-finder-001',
          requesterName: 'Bob Jones',
          requesterContact: '0898765432',
          studentId: '63070002',
          message: '  ${'a' * 20}  ',
        );

        await expectLater(useCase(params), completes);
      },
    );

    test(
      'WBS 1.4 — succeeds for a realistic description longer than 20 characters',
      () async {
        await expectLater(useCase(tValidParams), completes);
      },
    );
  });

  // ── WBS 2.4 — core submission contract ────────────────────────────────────

  test(
    'WBS 2.4 — submitRequest() is called exactly once on the repository',
    () async {
      await useCase(tValidParams);

      verify(() => repository.submitRequest(any())).called(1);
    },
  );

  test(
    'WBS 2.4 — submitted request has type = found and status = pending',
    () async {
      await useCase(tValidParams);

      final captured = verify(() => repository.submitRequest(captureAny()))
          .captured
          .single as ItemRequest;
      expect(captured.type, RequestType.found);
      expect(captured.status, RequestStatus.pending);
    },
  );

  test(
    'WBS 2.4 — submitted request carries all required identity fields '
    '(requesterId, requesterName, requesterContact, studentId, itemId)',
    () async {
      await useCase(tValidParams);

      final captured = verify(() => repository.submitRequest(captureAny()))
          .captured
          .single as ItemRequest;
      expect(captured.requesterId, tValidParams.requesterId);
      expect(captured.requesterName, tValidParams.requesterName);
      expect(captured.requesterContact, tValidParams.requesterContact);
      expect(captured.studentId, tValidParams.studentId);
      expect(captured.itemId, tValidParams.itemId);
    },
  );

  test(
    'WBS 2.4 — submitted request id is empty string '
    '(repository assigns the real Firestore ID)',
    () async {
      await useCase(tValidParams);

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
      final result = await useCase(tValidParams);

      expect(result.id, 'req-server-002');
    },
  );

  // ── Message trimming ───────────────────────────────────────────────────────

  test(
    'WBS 1.4 — message is trimmed before being stored in the request document',
    () async {
      final paramsWithPadding = SubmitFoundReportParams(
        itemId: 'item-seeker-001',
        requesterId: 'user-finder-001',
        requesterName: 'Bob Jones',
        requesterContact: '0898765432',
        studentId: '63070002',
        message: '  AirPods Pro with scratch — found near printer in LIB-1.  ',
      );

      await useCase(paramsWithPadding);

      final captured = verify(() => repository.submitRequest(captureAny()))
          .captured
          .single as ItemRequest;
      expect(captured.message,
          'AirPods Pro with scratch — found near printer in LIB-1.');
    },
  );

  // ── Optional photo ─────────────────────────────────────────────────────────

  test(
    'WBS 2.4 — optional photoUrl is passed through to the request document',
    () async {
      await useCase(tValidParams);

      final captured = verify(() => repository.submitRequest(captureAny()))
          .captured
          .single as ItemRequest;
      expect(captured.photoUrl,
          'https://storage.example.com/found-photo.jpg');
    },
  );

  test(
    'WBS 2.4 — photoUrl is null when no photo is attached to the Found Report',
    () async {
      final paramsNoPhoto = SubmitFoundReportParams(
        itemId: 'item-seeker-001',
        requesterId: 'user-finder-001',
        requesterName: 'Bob Jones',
        requesterContact: '0898765432',
        studentId: '63070002',
        message: 'Found AirPods Pro near the printer in LIB-1.',
      );

      await useCase(paramsNoPhoto);

      final captured = verify(() => repository.submitRequest(captureAny()))
          .captured
          .single as ItemRequest;
      expect(captured.photoUrl, isNull);
    },
  );

  // ── visitorAnswer is always null for Found Reports ─────────────────────────

  test(
    'WBS 2.10 — visitorAnswer is always null on Found Reports '
    '(secret question only applies to Claim Requests)',
    () async {
      await useCase(tValidParams);

      final captured = verify(() => repository.submitRequest(captureAny()))
          .captured
          .single as ItemRequest;
      expect(captured.visitorAnswer, isNull);
    },
  );
}
