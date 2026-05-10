import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/domain/errors/resubmit_not_allowed_failure.dart';
import 'package:campus_lost_found/features/requests/domain/errors/secret_answer_required_failure.dart';
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
  final ItemRequestRepository _requestRepository;
  final ItemRepository _itemRepository;

  const SubmitClaimRequestUseCase(
    this._requestRepository,
    this._itemRepository,
  );

  Future<ItemRequest> call(SubmitClaimRequestParams p) async {
    // Rule A — one active request per post (WBS 2.4.1)
    final decision = await _requestRepository.canResubmit(
      itemId: p.itemId,
      requesterId: p.requesterId,
    );
    if (!decision.allowed) {
      throw ResubmitNotAllowedFailure(
        reason: decision.reason,
        message: decision.reason.name,
        attemptsRemaining: decision.attemptsRemaining,
        retryAfter: decision.retryAfter,
      );
    }

    // Rule B — visitorAnswer required when secretQuestion is set (WBS 2.10)
    final item = await _itemRepository.watchItem(p.itemId).first;
    if (item != null &&
        item.secretQuestion != null &&
        item.secretQuestion!.isNotEmpty &&
        (p.visitorAnswer == null || p.visitorAnswer!.trim().isEmpty)) {
      throw const SecretAnswerRequiredFailure();
    }

    return _requestRepository.submitRequest(ItemRequest(
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
}
