import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:campus_lost_found/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:campus_lost_found/features/notifications/domain/entities/app_notification.dart';
import 'package:campus_lost_found/features/notifications/domain/repositories/notification_repository.dart';

part 'notification_providers.g.dart';

@riverpod
NotificationRemoteDatasource notificationDatasource(
  NotificationDatasourceRef ref,
) {
  return FirestoreNotificationDatasource(FirebaseFirestore.instance);
}

@riverpod
NotificationRepository notificationRepository(
  NotificationRepositoryRef ref,
) {
  return NotificationRepositoryImpl(ref.watch(notificationDatasourceProvider));
}

/// Notifications for the currently signed-in user, ordered by createdAt desc.
@riverpod
Stream<List<AppNotification>> myNotifications(MyNotificationsRef ref) async* {
  final authUser = await ref.watch(authStateProvider.future);
  if (authUser == null) {
    yield const [];
    return;
  }
  yield* ref
      .watch(notificationRepositoryProvider)
      .watchNotificationsForUser(authUser.uid);
}

/// Unread count for the currently signed-in user — drives the nav badge.
@riverpod
Stream<int> myUnreadNotificationCount(
  MyUnreadNotificationCountRef ref,
) async* {
  final authUser = await ref.watch(authStateProvider.future);
  if (authUser == null) {
    yield 0;
    return;
  }
  yield* ref
      .watch(notificationRepositoryProvider)
      .watchUnreadCount(authUser.uid);
}

@riverpod
class NotificationActionNotifier extends _$NotificationActionNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> markAsRead(String notificationId) async {
    final uid = await _currentUid();
    if (uid == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(notificationRepositoryProvider)
          .markAsRead(userId: uid, notificationId: notificationId),
    );
  }

  Future<void> markAllAsRead() async {
    final uid = await _currentUid();
    if (uid == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationRepositoryProvider).markAllAsRead(uid),
    );
  }

  Future<void> clearRead() async {
    final uid = await _currentUid();
    if (uid == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () =>
          ref.read(notificationRepositoryProvider).clearReadNotifications(uid),
    );
  }

  Future<void> delete(String notificationId) async {
    final uid = await _currentUid();
    if (uid == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(notificationRepositoryProvider)
          .deleteNotification(userId: uid, notificationId: notificationId),
    );
  }

  Future<String?> _currentUid() async {
    final authUser = await ref.read(authStateProvider.future);
    return authUser?.uid;
  }
}
