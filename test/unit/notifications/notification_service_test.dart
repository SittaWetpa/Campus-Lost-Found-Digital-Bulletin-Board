// WBS 2.16 — NotificationService unit tests

import 'package:campus_lost_found/features/notifications/data/services/notification_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

void main() {
  group('NotificationService — WBS 2.16', () {
    // ── registerToken() ────────────────────────────────────────────────────────

    test(
      'U1 registerToken() — calls arrayUnion on users/{uid}.fcmTokens '
      'with the token returned by FirebaseMessaging.getToken()',
      () async {
        final mockMessaging = MockFirebaseMessaging();
        final fakeFirestore = FakeFirebaseFirestore();

        // doc must exist before update()
        await fakeFirestore.doc('users/uid-naree').set({'fcmTokens': []});

        when(() => mockMessaging.getToken()).thenAnswer((_) async => 'tok-abc');

        final sut = NotificationServiceImpl(
          messaging: mockMessaging,
          firestore: fakeFirestore,
        );

        await sut.registerToken('uid-naree');

        final doc = await fakeFirestore.doc('users/uid-naree').get();
        expect(doc.data()!['fcmTokens'], contains('tok-abc'));
      },
    );

    // ── unregisterToken() ──────────────────────────────────────────────────────

    test(
      'U2 unregisterToken() — calls arrayRemove on users/{uid}.fcmTokens '
      'with the current device token',
      () async {
        final mockMessaging = MockFirebaseMessaging();
        final fakeFirestore = FakeFirebaseFirestore();

        await fakeFirestore.doc('users/uid-naree').set({
          'fcmTokens': ['tok-abc', 'tok-old'],
        });

        when(() => mockMessaging.getToken()).thenAnswer((_) async => 'tok-abc');

        final sut = NotificationServiceImpl(
          messaging: mockMessaging,
          firestore: fakeFirestore,
        );

        await sut.unregisterToken('uid-naree');

        final doc = await fakeFirestore.doc('users/uid-naree').get();
        expect(doc.data()!['fcmTokens'], isNot(contains('tok-abc')));
        expect(doc.data()!['fcmTokens'], contains('tok-old'));
      },
    );
  });
}
