// WBS 2.16 — Domain entities for Push Notifications
// Covers: NotificationType enum, AppNotification entity, DeviceToken entity

import 'package:campus_lost_found/features/notifications/domain/entities/app_notification.dart';
import 'package:campus_lost_found/features/notifications/domain/entities/device_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── NotificationType.fromString() ────────────────────────────────────────────

  group('NotificationType.fromString()', () {
    test('returns claimRequest for "claimRequest" (T1)', () {
      expect(
        NotificationType.fromString('claimRequest'),
        NotificationType.claimRequest,
      );
    });

    test('returns foundReport for "foundReport" (T2)', () {
      expect(
        NotificationType.fromString('foundReport'),
        NotificationType.foundReport,
      );
    });

    test('returns requestApproved for "requestApproved" (T3)', () {
      expect(
        NotificationType.fromString('requestApproved'),
        NotificationType.requestApproved,
      );
    });

    test('returns requestDeclined for "requestDeclined" (T4)', () {
      expect(
        NotificationType.fromString('requestDeclined'),
        NotificationType.requestDeclined,
      );
    });

    test('throws ArgumentError for an unrecognised value', () {
      expect(
        () => NotificationType.fromString('newMessage'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unknown NotificationType'),
          ),
        ),
      );
    });

    test('throws ArgumentError for an empty string', () {
      expect(
        () => NotificationType.fromString(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for wrong capitalisation', () {
      expect(
        () => NotificationType.fromString('ClaimRequest'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ── AppNotification constructor ───────────────────────────────────────────────

  group('AppNotification', () {
    final baseCreatedAt = DateTime(2026, 5, 15, 10, 0);

    group('T1 — claimRequest (Founder Post)', () {
      late AppNotification notif;

      setUp(() {
        notif = AppNotification(
          id: 'n-001',
          type: NotificationType.claimRequest,
          recipientId: 'uid-poster',
          isRead: false,
          itemId: 'item-001',
          itemTitle: 'Brown leather wallet',
          requesterName: 'Pun Wongsakorn',
          createdAt: baseCreatedAt,
        );
      });

      test('stores id', () => expect(notif.id, 'n-001'));
      test('stores type as claimRequest', () => expect(notif.type, NotificationType.claimRequest));
      test('stores recipientId', () => expect(notif.recipientId, 'uid-poster'));
      test('stores isRead as false', () => expect(notif.isRead, isFalse));
      test('stores itemId', () => expect(notif.itemId, 'item-001'));
      test('stores itemTitle', () => expect(notif.itemTitle, 'Brown leather wallet'));
      test('stores requesterName', () => expect(notif.requesterName, 'Pun Wongsakorn'));
      test('stores createdAt', () => expect(notif.createdAt, baseCreatedAt));
    });

    group('T3 — requestApproved (self-directed, no requesterName)', () {
      test('requesterName is null when not provided', () {
        final notif = AppNotification(
          id: 'n-002',
          type: NotificationType.requestApproved,
          recipientId: 'uid-visitor',
          isRead: false,
          itemId: 'item-001',
          itemTitle: 'Brown leather wallet',
          createdAt: baseCreatedAt,
        );
        expect(notif.requesterName, isNull);
      });

      test('requesterName is null for T4 (requestDeclined) too', () {
        final notif = AppNotification(
          id: 'n-003',
          type: NotificationType.requestDeclined,
          recipientId: 'uid-visitor',
          isRead: false,
          itemId: 'item-001',
          itemTitle: 'Brown leather wallet',
          createdAt: baseCreatedAt,
        );
        expect(notif.requesterName, isNull);
      });
    });

    group('copyWith()', () {
      late AppNotification base;

      setUp(() {
        base = AppNotification(
          id: 'n-cw',
          type: NotificationType.claimRequest,
          recipientId: 'uid-poster',
          isRead: false,
          itemId: 'item-cw',
          itemTitle: 'Laptop bag',
          requesterName: 'Alice',
          createdAt: baseCreatedAt,
        );
      });

      test('returns identical values when no fields are overridden', () {
        final copy = base.copyWith();
        expect(copy.id, base.id);
        expect(copy.type, base.type);
        expect(copy.recipientId, base.recipientId);
        expect(copy.isRead, base.isRead);
        expect(copy.itemId, base.itemId);
        expect(copy.itemTitle, base.itemTitle);
        expect(copy.requesterName, base.requesterName);
        expect(copy.createdAt, base.createdAt);
      });

      test('overrides isRead to true (mark-as-read)', () {
        final copy = base.copyWith(isRead: true);
        expect(copy.isRead, isTrue);
        expect(base.isRead, isFalse);
      });

      test('overrides type only', () {
        final copy = base.copyWith(type: NotificationType.requestApproved);
        expect(copy.type, NotificationType.requestApproved);
        expect(copy.id, base.id);
      });

      test('does not mutate the original', () {
        base.copyWith(isRead: true, itemTitle: 'Changed');
        expect(base.isRead, isFalse);
        expect(base.itemTitle, 'Laptop bag');
      });

      test('overrides requesterName to null (T3/T4 pattern)', () {
        final copy = base.copyWith(requesterName: null);
        expect(copy.requesterName, isNull);
        expect(base.requesterName, 'Alice');
      });
    });

    group('no Firebase imports in domain layer', () {
      test('AppNotification can be constructed without Firebase initialisation', () {
        final notif = AppNotification(
          id: 'pure-dart',
          type: NotificationType.foundReport,
          recipientId: 'uid-x',
          isRead: false,
          itemId: 'item-x',
          itemTitle: 'AirPods',
          createdAt: DateTime(2026),
        );
        expect(notif.id, 'pure-dart');
      });
    });
  });

  // ── DeviceToken entity ────────────────────────────────────────────────────────

  group('DeviceToken', () {
    final registeredAt = DateTime(2026, 5, 15, 9, 0);

    test('stores all fields correctly', () {
      final token = DeviceToken(
        token: 'fcm-token-abc123',
        userId: 'uid-naree',
        platform: DevicePlatform.android,
        registeredAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(token.token, 'fcm-token-abc123');
      expect(token.userId, 'uid-naree');
      expect(token.platform, DevicePlatform.android);
    });

    test('DevicePlatform.android is a valid value', () {
      expect(DevicePlatform.android, isNotNull);
    });

    test('DevicePlatform.web is a valid value', () {
      expect(DevicePlatform.web, isNotNull);
    });

    test('DevicePlatform has exactly 2 values — android and web (no iOS per CLAUDE.md)', () {
      expect(DevicePlatform.values.length, 2);
      expect(DevicePlatform.values, containsAll([DevicePlatform.android, DevicePlatform.web]));
    });

    test('stores web platform correctly', () {
      final token = DeviceToken(
        token: 'fcm-web-token-xyz',
        userId: 'uid-pun',
        platform: DevicePlatform.web,
        registeredAt: registeredAt,
      );
      expect(token.platform, DevicePlatform.web);
      expect(token.registeredAt, registeredAt);
    });

    test('DeviceToken can be constructed without Firebase initialisation', () {
      final token = DeviceToken(
        token: 'pure-dart-token',
        userId: 'uid-y',
        platform: DevicePlatform.android,
        registeredAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(token.token, 'pure-dart-token');
    });
  });
}
