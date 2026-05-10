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

enum RequestType {
  claim, // ClaimRequestScreen — seeker asserts ownership
  found; // FoundReportScreen — third party reports finding a seeker's item

  static RequestType fromString(String value) => switch (value) {
        'claim' => RequestType.claim,
        'found' => RequestType.found,
        _ => throw ArgumentError('Unknown RequestType: $value'),
      };
}

class ItemRequest {
  final String id;
  final String itemId;
  final String requesterId;
  final String requesterName;
  final String requesterContact;
  final String studentId;
  final RequestType type;
  final RequestStatus status;
  final DateTime createdAt;

  // Optional for claim requests; required (≥20 chars) for found reports
  final String? message;

  // WBS 2.10 — visitor's answer to the Founder Post secret question
  final String? visitorAnswer;

  // Photo attached by FoundReportScreen to help verify the item
  final String? photoUrl;

  // WBS 2.4 / 2.17 — null on new requests; set when requester edits a pending request
  final DateTime? editedAt;

  const ItemRequest({
    required this.id,
    required this.itemId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterContact,
    required this.studentId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.message,
    this.visitorAnswer,
    this.photoUrl,
    this.editedAt,
  });

  ItemRequest copyWith({
    String? id,
    String? itemId,
    String? requesterId,
    String? requesterName,
    String? requesterContact,
    String? studentId,
    RequestType? type,
    RequestStatus? status,
    DateTime? createdAt,
    String? message,
    String? visitorAnswer,
    String? photoUrl,
    DateTime? editedAt,
  }) =>
      ItemRequest(
        id: id ?? this.id,
        itemId: itemId ?? this.itemId,
        requesterId: requesterId ?? this.requesterId,
        requesterName: requesterName ?? this.requesterName,
        requesterContact: requesterContact ?? this.requesterContact,
        studentId: studentId ?? this.studentId,
        type: type ?? this.type,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        message: message ?? this.message,
        visitorAnswer: visitorAnswer ?? this.visitorAnswer,
        photoUrl: photoUrl ?? this.photoUrl,
        editedAt: editedAt ?? this.editedAt,
      );
}
