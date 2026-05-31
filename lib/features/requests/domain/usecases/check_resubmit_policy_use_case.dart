import 'package:campus_lost_found/features/requests/domain/entities/resubmit_decision.dart';
import 'package:campus_lost_found/features/requests/domain/repositories/item_request_repository.dart';

class CheckResubmitPolicyUseCase {
  final ItemRequestRepository _repository;
  const CheckResubmitPolicyUseCase(this._repository);

  Future<ResubmitDecision> call({
    required String itemId,
    required String requesterId,
  }) =>
      _repository.canResubmit(itemId: itemId, requesterId: requesterId);
}
