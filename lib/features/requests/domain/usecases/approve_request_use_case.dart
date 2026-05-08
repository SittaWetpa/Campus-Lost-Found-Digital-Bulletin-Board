import 'package:campus_lost_found/features/requests/domain/repositories/item_request_repository.dart';

class ApproveRequestParams {
  final String itemId;
  final String requestId;
  final String requesterId;

  const ApproveRequestParams({
    required this.itemId,
    required this.requestId,
    required this.requesterId,
  });
}

class ApproveRequestUseCase {
  final ItemRequestRepository _repository;
  const ApproveRequestUseCase(this._repository);

  Future<void> call(ApproveRequestParams p) => _repository.approveRequest(
        itemId: p.itemId,
        requestId: p.requestId,
        requesterId: p.requesterId,
      );
}
