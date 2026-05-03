import 'package:campus_lost_found/features/requests/domain/repositories/item_request_repository.dart';

class RejectRequestUseCase {
  final ItemRequestRepository _repository;
  const RejectRequestUseCase(this._repository);

  Future<void> call({required String itemId, required String requestId}) =>
      _repository.rejectRequest(itemId: itemId, requestId: requestId);
}
