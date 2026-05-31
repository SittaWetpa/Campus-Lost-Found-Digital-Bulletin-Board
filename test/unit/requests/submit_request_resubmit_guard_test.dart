// WBS 2.4.1 — submitRequest() guard: throws ResubmitNotAllowedFailure when
// the resubmit policy denies the request.

import 'dart:io';

import 'package:campus_lost_found/features/requests/data/datasources/item_request_remote_datasource.dart';
import 'package:campus_lost_found/features/requests/data/models/item_request_model.dart';
import 'package:campus_lost_found/features/requests/data/repositories/item_request_repository_impl.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/domain/entities/resubmit_decision.dart';
import 'package:campus_lost_found/features/requests/domain/errors/resubmit_not_allowed_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatasource extends Mock implements ItemRequestRemoteDatasource {}

class _FakeFile extends Fake implements File {}

final _fallbackModel = ItemRequestModel(
  id: '',
  itemId: 'item-fallback',
  requesterId: 'uid-fallback',
  requesterName: 'Fallback',
  requesterContact: '0800000000',
  studentId: '00000000',
  type: 'claim',
  status: 'pending',
  createdAt: DateTime(2024),
);

void main() {
  late _MockDatasource datasource;
  late ItemRequestRepositoryImpl repository;

  final tRequest = ItemRequest(
    id: '',
    itemId: 'item-001',
    requesterId: 'user-001',
    requesterName: 'Alice',
    requesterContact: '0812345678',
    studentId: '63070001',
    type: RequestType.claim,
    status: RequestStatus.pending,
    createdAt: DateTime(2026, 5, 9),
  );

  setUpAll(() {
    registerFallbackValue(_FakeFile());
    registerFallbackValue(_fallbackModel);
  });

  setUp(() {
    datasource = _MockDatasource();
    repository = ItemRequestRepositoryImpl(datasource);
  });

  test(
    'WBS 2.4.1 — submitRequest throws ResubmitNotAllowedFailure carrying the '
    'denying reason and attempts/retryAfter from the decision',
    () async {
      when(
        () => datasource.canResubmit(
          itemId: any(named: 'itemId'),
          requesterId: any(named: 'requesterId'),
        ),
      ).thenAnswer((_) async => const ResubmitDecision.permanentBlock());

      await expectLater(
        () => repository.submitRequest(tRequest),
        throwsA(
          isA<ResubmitNotAllowedFailure>()
              .having((f) => f.reason, 'reason', ResubmitReason.permanentBlock)
              .having((f) => f.attemptsRemaining, 'attemptsRemaining', 0),
        ),
      );

      verifyNever(() => datasource.submitRequest(any()));
    },
  );

  test(
    'WBS 2.4.1 — submitRequest proceeds to datasource.submitRequest when the '
    'resubmit policy returns allowed',
    () async {
      when(
        () => datasource.canResubmit(
          itemId: any(named: 'itemId'),
          requesterId: any(named: 'requesterId'),
        ),
      ).thenAnswer((_) async => const ResubmitDecision.allowed());
      when(() => datasource.submitRequest(any())).thenAnswer(
        (inv) async => inv.positionalArguments[0] as ItemRequestModel,
      );

      await repository.submitRequest(tRequest);

      verify(() => datasource.submitRequest(any())).called(1);
    },
  );
}
