// WBS 5.1 — NotificationsScreen accessibility widget tests
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/notifications/domain/entities/app_notification.dart';
import 'package:campus_lost_found/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_lost_found/features/notifications/presentation/screens/notifications_screen.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeNotificationActionNotifier extends NotificationActionNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> clearRead() async {}

  @override
  Future<void> delete(String notificationId) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _kUid = 'uid-notif-001';

AppNotification _makeNotification({
  String id = 'notif-001',
  NotificationType type = NotificationType.claimRequest,
  bool isRead = false,
}) =>
    AppNotification(
      id: id,
      type: type,
      recipientId: _kUid,
      isRead: isRead,
      itemId: 'item-001',
      itemTitle: 'Blue Wallet',
      requesterName: 'Alice',
      createdAt: DateTime(2026, 1, 1),
    );

GoRouter _makeRouter() => GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/item/:id',
          builder: (_, s) =>
              Scaffold(body: Text('Detail:${s.pathParameters['id']}')),
        ),
      ],
    );

Widget _buildApp({List<AppNotification> notifications = const []}) {
  const authUser = AuthUser(uid: _kUid, email: 'alice@mail.kmutt.ac.th');
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((_) => Stream.value(authUser)),
      myNotificationsProvider.overrideWith(
        (_) => Stream.value(notifications),
      ),
      myUnreadNotificationCountProvider.overrideWith(
        (_) => Stream.value(
          notifications.where((n) => !n.isRead).length,
        ),
      ),
      notificationActionNotifierProvider
          .overrideWith(_FakeNotificationActionNotifier.new),
    ],
    child: MaterialApp.router(routerConfig: _makeRouter()),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('NotificationsScreen — WBS 5.1', () {
    testWidgets(
      '01 empty list shows "No notifications yet." message',
      (tester) async {
        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        expect(find.text('No notifications yet.'), findsOneWidget);
      },
    );

    testWidgets(
      '02 notification tile rendered for a claimRequest notification',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(notifications: [_makeNotification()]),
        );
        await tester.pumpAndSettle();

        expect(find.text('New Claim Request'), findsOneWidget);
      },
    );

    testWidgets(
      'meets accessibility guidelines (tap target size, labels, contrast)',
      (tester) async {
        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      },
    );
  });
}
