// WBS 1.3 — Item Detail Screen / WBS 2.4 — Request System:
// ApproveRequestUseCase unit tests

import 'package:campus_lost_found/features/requests/domain/repositories/item_request_repository.dart';
import 'package:campus_lost_found/features/requests/domain/usecases/approve_request_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockItemRequestRepository extends Mock
    implements ItemRequestRepository {}

void main() {
  late _MockItemRequestRepository repository;
  late ApproveRequestUseCase useCase;

  setUp(() {
    repository = _MockItemRequestRepository();
    useCase = ApproveRequestUseCase(repository);
    when(
      () => repository.approveRequest(
        itemId: any(named: 'itemId'),
        requestId: any(named: 'requestId'),
        requesterId: any(named: 'requesterId'),
      ),
    ).thenAnswer((_) async {});
  });

  test(
    'WBS 1.3 — approveRequest() is called exactly once with correct params',
    () async {
      await useCase(
        const ApproveRequestParams(
          itemId: 'item-001',
          requestId: 'req-001',
          requesterId: 'user-001',
        ),
      );

      verify(
        () => repository.approveRequest(
          itemId: 'item-001',
          requestId: 'req-001',
          requesterId: 'user-001',
        ),
      ).called(1);
    },
  );

  test(
    'WBS 1.3 — returns normally when repository succeeds',
    () async {
      await expectLater(
        useCase(
          const ApproveRequestParams(
            itemId: 'item-001',
            requestId: 'req-001',
            requesterId: 'user-001',
          ),
        ),
        completes,
      );
    },
  );

  test(
    'WBS 1.3 — propagates exception when repository throws',
    () async {
      when(
        () => repository.approveRequest(
          itemId: any(named: 'itemId'),
          requestId: any(named: 'requestId'),
          requesterId: any(named: 'requesterId'),
        ),
      ).thenAnswer((_) => Future.error(Exception('Firestore error')));

      await expectLater(
        useCase(
          const ApproveRequestParams(
            itemId: 'item-001',
            requestId: 'req-001',
            requesterId: 'user-001',
          ),
        ),
        throwsA(isA<Exception>()),
      );
    },
  );
}
