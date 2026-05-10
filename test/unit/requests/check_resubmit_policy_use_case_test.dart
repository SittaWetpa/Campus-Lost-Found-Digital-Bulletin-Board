// WBS 2.4.1 — CheckResubmitPolicyUseCase delegation test.

import 'package:campus_lost_found/features/requests/domain/entities/resubmit_decision.dart';
import 'package:campus_lost_found/features/requests/domain/repositories/item_request_repository.dart';
import 'package:campus_lost_found/features/requests/domain/usecases/check_resubmit_policy_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ItemRequestRepository {}

void main() {
  late _MockRepository repository;
  late CheckResubmitPolicyUseCase useCase;

  setUp(() {
    repository = _MockRepository();
    useCase = CheckResubmitPolicyUseCase(repository);
  });

  test(
    'WBS 2.4.1 — delegates to repository.canResubmit with the supplied args '
    'and returns its decision unchanged',
    () async {
      const expected = ResubmitDecision.permanentBlock();
      when(
        () => repository.canResubmit(
          itemId: any(named: 'itemId'),
          requesterId: any(named: 'requesterId'),
        ),
      ).thenAnswer((_) async => expected);

      final result = await useCase(
        itemId: 'item-42',
        requesterId: 'user-7',
      );

      expect(result, same(expected));
      verify(
        () => repository.canResubmit(
          itemId: 'item-42',
          requesterId: 'user-7',
        ),
      ).called(1);
    },
  );
}
