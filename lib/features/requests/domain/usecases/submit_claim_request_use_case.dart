import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/domain/repositories/item_request_repository.dart';

class SubmitClaimRequestParams {
  final String itemId;
  final String requesterId;
  final String requesterName;
  final String requesterContact;
  final String studentId;

  /// Optional freetext from the seeker; no minimum length.
  final String? message;

  /// WBS 2.10 — answer to the Founder Post's secret question; null if none set.
  final String? visitorAnswer;

  const SubmitClaimRequestParams({
    required this.itemId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterContact,
    required this.studentId,
    this.message,
    this.visitorAnswer,
  });
}

class SubmitClaimRequestUseCase {
  final ItemRequestRepository _repository;
  const SubmitClaimRequestUseCase(this._repository);

  Future<ItemRequest> call(SubmitClaimRequestParams p) =>
      _repository.submitRequest(ItemRequest(
        id: '',
        itemId: p.itemId,
        requesterId: p.requesterId,
        requesterName: p.requesterName,
        requesterContact: p.requesterContact,
        studentId: p.studentId,
        type: RequestType.claim,
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
        message: p.message,
        visitorAnswer: p.visitorAnswer,
      ));
}
