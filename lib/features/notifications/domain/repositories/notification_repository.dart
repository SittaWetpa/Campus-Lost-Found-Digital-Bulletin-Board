import 'package:campus_lost_found/features/notifications/domain/entities/app_notification.dart';

abstract interface class NotificationRepository {
  /// Real-time stream of all notifications for [userId], ordered by createdAt desc.
  /// Used by the Notification Center screen (WBS 2.16).
  Stream<List<AppNotification>> watchNotificationsForUser(String userId);

  /// Real-time unread count — drives the badge on the bottom nav icon.
  Stream<int> watchUnreadCount(String userId);

  /// Marks a single notification as read.
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  });

  /// Marks every notification for [userId] as read.
  Future<void> markAllAsRead(String userId);

  /// Deletes all notifications where isRead == true for [userId].
  Future<void> clearReadNotifications(String userId);

  /// Deletes a single notification document.
  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  });
}
