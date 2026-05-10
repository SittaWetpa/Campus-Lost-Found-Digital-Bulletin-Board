import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/domain/repositories/item_request_repository.dart';

class SubmitFoundReportParams {
  final String itemId;
  final String requesterId;
  final String requesterName;
  final String requesterContact;
  final String studentId;

  /// Required; must be ≥20 characters.
  final String message;

  /// Optional photo URL (already uploaded to Storage before calling this use case).
  final String? photoUrl;

  const SubmitFoundReportParams({
    required this.itemId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterContact,
    required this.studentId,
    required this.message,
    this.photoUrl,
  });
}

class SubmitFoundReportUseCase {
  final ItemRequestRepository _repository;
  const SubmitFoundReportUseCase(this._repository);

  Future<ItemRequest> call(SubmitFoundReportParams p) {
    if (p.message.trim().length < 20) {
      throw ArgumentError('Found report message must be at least 20 characters');
    }
    return _repository.submitRequest(ItemRequest(
      id: '',
      itemId: p.itemId,
      requesterId: p.requesterId,
      requesterName: p.requesterName,
      requesterContact: p.requesterContact,
      studentId: p.studentId,
      type: RequestType.found,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      message: p.message.trim(),
      photoUrl: p.photoUrl,
    ));
  }
}
