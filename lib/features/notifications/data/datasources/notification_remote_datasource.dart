import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_lost_found/features/notifications/data/models/app_notification_model.dart';

abstract interface class NotificationRemoteDatasource {
  Stream<List<AppNotificationModel>> watchNotificationsForUser(String userId);
  Stream<int> watchUnreadCount(String userId);
  Future<void> markAsRead({required String userId, required String notificationId});
  Future<void> markAllAsRead(String userId);
  Future<void> clearReadNotifications(String userId);
  Future<void> deleteNotification({required String userId, required String notificationId});
}

class FirestoreNotificationDatasource implements NotificationRemoteDatasource {
  final FirebaseFirestore _firestore;

  FirestoreNotificationDatasource(this._firestore);

  CollectionReference<Map<String, dynamic>> _coll(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  @override
  Stream<List<AppNotificationModel>> watchNotificationsForUser(String userId) {
    return _coll(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(AppNotificationModel.fromFirestore).toList());
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return _coll(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.size);
  }

  @override
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await _coll(userId).doc(notificationId).update({'isRead': true});
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final unread =
        await _coll(userId).where('isRead', isEqualTo: false).get();
    if (unread.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Future<void> clearReadNotifications(String userId) async {
    final read = await _coll(userId).where('isRead', isEqualTo: true).get();
    if (read.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in read.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    await _coll(userId).doc(notificationId).delete();
  }
}
