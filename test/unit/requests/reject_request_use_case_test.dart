// WBS 1.3 — Item Detail Screen / WBS 2.4 — Request System:
// RejectRequestUseCase unit tests

import 'package:campus_lost_found/features/requests/domain/repositories/item_request_repository.dart';
import 'package:campus_lost_found/features/requests/domain/usecases/reject_request_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockItemRequestRepository extends Mock
    implements ItemRequestRepository {}

void main() {
  late _MockItemRequestRepository repository;
  late RejectRequestUseCase useCase;

  setUp(() {
    repository = _MockItemRequestRepository();
    useCase = RejectRequestUseCase(repository);
    when(
      () => repository.rejectRequest(
        itemId: any(named: 'itemId'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) async {});
  });

  test(
    'WBS 1.3 — rejectRequest() is called exactly once with correct params',
    () async {
      await useCase(itemId: 'item-001', requestId: 'req-001');

      verify(
        () => repository.rejectRequest(
          itemId: 'item-001',
          requestId: 'req-001',
        ),
      ).called(1);
    },
  );

  test(
    'WBS 1.3 — returns normally when repository succeeds',
    () async {
      await expectLater(
        useCase(itemId: 'item-001', requestId: 'req-001'),
        completes,
      );
    },
  );

  test(
    'WBS 1.3 — propagates exception when repository throws',
    () async {
      when(
        () => repository.rejectRequest(
          itemId: any(named: 'itemId'),
          requestId: any(named: 'requestId'),
        ),
      ).thenAnswer((_) => Future.error(Exception('Firestore error')));

      await expectLater(
        useCase(itemId: 'item-001', requestId: 'req-001'),
        throwsA(isA<Exception>()),
      );
    },
  );
}
