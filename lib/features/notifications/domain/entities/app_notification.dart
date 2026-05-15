enum NotificationType {
  claimRequest, // T1 — new Claim Request on your Founder Post
  foundReport, // T2 — new Found Report on your Seeker Post
  requestApproved, // T3 — your request was approved
  requestDeclined; // T4 — your request was declined (manual or auto)

  static NotificationType fromString(String value) => switch (value) {
        'claimRequest' => NotificationType.claimRequest,
        'foundReport' => NotificationType.foundReport,
        'requestApproved' => NotificationType.requestApproved,
        'requestDeclined' => NotificationType.requestDeclined,
        _ => throw ArgumentError('Unknown NotificationType: $value'),
      };
}

// Sentinel used by copyWith to distinguish "omitted" from "explicitly null".
const _absent = Object();

class AppNotification {
  final String id;
  final NotificationType type;
  final String recipientId;
  final bool isRead;
  final String itemId;
  final String itemTitle;
  // null for T3/T4 — those are self-directed (no third-party actor to show)
  final String? requesterName;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.recipientId,
    required this.isRead,
    required this.itemId,
    required this.itemTitle,
    this.requesterName,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? recipientId,
    bool? isRead,
    String? itemId,
    String? itemTitle,
    Object? requesterName = _absent,
    DateTime? createdAt,
  }) =>
      AppNotification(
        id: id ?? this.id,
        type: type ?? this.type,
        recipientId: recipientId ?? this.recipientId,
        isRead: isRead ?? this.isRead,
        itemId: itemId ?? this.itemId,
        itemTitle: itemTitle ?? this.itemTitle,
        requesterName: requesterName == _absent
            ? this.requesterName
            : requesterName as String?,
        createdAt: createdAt ?? this.createdAt,
      );
}
