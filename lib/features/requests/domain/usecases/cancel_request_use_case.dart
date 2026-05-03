import 'package:campus_lost_found/features/requests/domain/repositories/item_request_repository.dart';

class CancelRequestUseCase {
  final ItemRequestRepository _repository;
  const CancelRequestUseCase(this._repository);

  Future<void> call({required String itemId, required String requestId}) =>
      _repository.cancelRequest(itemId: itemId, requestId: requestId);
}
