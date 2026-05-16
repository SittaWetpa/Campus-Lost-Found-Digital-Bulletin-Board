import 'package:firebase_core/firebase_core.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:campus_lost_found/features/notifications/domain/entities/app_notification.dart';
import 'package:campus_lost_found/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDatasource _datasource;
  const NotificationRepositoryImpl(this._datasource);

  @override
  Stream<List<AppNotification>> watchNotificationsForUser(String userId) {
    return _datasource
        .watchNotificationsForUser(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<int> watchUnreadCount(String userId) =>
      _datasource.watchUnreadCount(userId);

  @override
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    try {
      await _datasource.markAsRead(
          userId: userId, notificationId: notificationId);
    } on FirebaseException catch (e) {
      throw NotificationFailure(e.message ?? 'Failed to mark as read.');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _datasource.markAllAsRead(userId);
    } on FirebaseException catch (e) {
      throw NotificationFailure(e.message ?? 'Failed to mark all as read.');
    }
  }

  @override
  Future<void> clearReadNotifications(String userId) async {
    try {
      await _datasource.clearReadNotifications(userId);
    } on FirebaseException catch (e) {
      throw NotificationFailure(
          e.message ?? 'Failed to clear notifications.');
    }
  }

  @override
  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    try {
      await _datasource.deleteNotification(
          userId: userId, notificationId: notificationId);
    } on FirebaseException catch (e) {
      throw NotificationFailure(
          e.message ?? 'Failed to delete notification.');
    }
  }
}
