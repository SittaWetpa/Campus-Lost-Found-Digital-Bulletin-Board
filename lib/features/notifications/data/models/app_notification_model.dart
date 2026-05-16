import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_lost_found/features/notifications/domain/entities/app_notification.dart';

class AppNotificationModel {
  final String id;
  final String type;
  final String recipientId;
  final bool isRead;
  final String itemId;
  final String itemTitle;
  final String? requesterName;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.recipientId,
    required this.isRead,
    required this.itemId,
    required this.itemTitle,
    required this.createdAt,
    this.requesterName,
  });

  factory AppNotificationModel.fromMap(String id, Map<String, dynamic> data) =>
      AppNotificationModel(
        id: id,
        type: data['type'] as String,
        recipientId: data['recipientId'] as String? ?? '',
        isRead: data['isRead'] as bool? ?? false,
        itemId: data['itemId'] as String? ?? '',
        itemTitle: data['itemTitle'] as String? ?? '',
        requesterName: data['requesterName'] as String?,
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  factory AppNotificationModel.fromFirestore(DocumentSnapshot doc) =>
      AppNotificationModel.fromMap(
          doc.id, doc.data() as Map<String, dynamic>);

  AppNotification toEntity() => AppNotification(
        id: id,
        type: NotificationType.fromString(type),
        recipientId: recipientId,
        isRead: isRead,
        itemId: itemId,
        itemTitle: itemTitle,
        requesterName: requesterName,
        createdAt: createdAt,
      );
}
