enum RequestStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static RequestStatus fromString(String value) => switch (value) {
        'pending' => RequestStatus.pending,
        'approved' => RequestStatus.approved,
        'rejected' => RequestStatus.rejected,
        'cancelled' => RequestStatus.cancelled,
        _ => throw ArgumentError('Unknown RequestStatus: $value'),
      };
}

class ItemRequest {
  final String id;
  final String itemId;
  final String requesterId;
  final String requesterName;
  final String requesterContact;
  final String message;
  final RequestStatus status;
  final DateTime createdAt;

  // WBS 2.10 — visitor's answer to the Founder Post secret question
  final String? visitorAnswer;

  const ItemRequest({
    required this.id,
    required this.itemId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterContact,
    required this.message,
    required this.status,
    required this.createdAt,
    this.visitorAnswer,
  });
}
