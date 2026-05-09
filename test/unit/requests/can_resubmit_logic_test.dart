// WBS 2.4.1 — Request Resubmit Policy: canResubmit() logic tests.

import 'package:campus_lost_found/features/requests/data/datasources/item_request_remote_datasource.dart';
import 'package:campus_lost_found/features/requests/domain/entities/resubmit_decision.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseStorage extends Mock implements FirebaseStorage {}

const _itemId = 'item-001';
const _requesterId = 'user-visitor-001';
const _otherRequester = 'user-visitor-002';

Future<void> _seedItem(
  FakeFirebaseFirestore fs, {
  String? secretQuestion,
}) async {
  await fs.collection('items').doc(_itemId).set({
    'title': 'Test post',
    'category': 'founder',
    'status': 'active',
    'userId': 'poster-001',
    if (secretQuestion != null) 'secretQuestion': secretQuestion,
  });
}

Future<void> _seedRequest(
  FakeFirebaseFirestore fs, {
  required String docId,
  required String requesterId,
  required String status,
  required DateTime createdAt,
}) async {
  await fs
      .collection('items')
      .doc(_itemId)
      .collection('requests')
      .doc(docId)
      .set({
    'requesterId': requesterId,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
  });
}

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreItemRequestDatasource datasource;

  setUp(() {
    fs = FakeFirebaseFirestore();
    datasource = FirestoreItemRequestDatasource(
      fs,
      storage: _MockFirebaseStorage(),
    );
  });

  group('canResubmit() — WBS 2.4.1', () {
    test(
      '01 allows submission when the requester has no prior history '
      '(non-Secret-Question post)',
      () async {
        await _seedItem(fs);

        final decision = await datasource.canResubmit(
          itemId: _itemId,
          requesterId: _requesterId,
        );

        expect(decision.allowed, isTrue);
        expect(decision.reason, ResubmitReason.allowed);
        expect(decision.attemptsRemaining, isNull);
      },
    );

    test(
      '02 allows submission with attemptsRemaining=2 when a Secret Question '
      'post has 1 prior rejection by this requester',
      () async {
        await _seedItem(fs, secretQuestion: 'What colour is the wallet?');
        await _seedRequest(
          fs,
          docId: 'req-old',
          requesterId: _requesterId,
          status: 'rejected',
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        );

        final decision = await datasource.canResubmit(
          itemId: _itemId,
          requesterId: _requesterId,
        );

        expect(decision.allowed, isTrue);
        expect(decision.reason, ResubmitReason.allowed);
        expect(decision.attemptsRemaining, 2);
      },
    );

    test(
      '03 returns permanentBlock when a Secret Question post has 3+ '
      'prior rejections by this requester',
      () async {
        await _seedItem(fs, secretQuestion: 'What colour is the wallet?');
        for (var i = 0; i < 3; i++) {
          await _seedRequest(
            fs,
            docId: 'req-r$i',
            requesterId: _requesterId,
            status: 'rejected',
            createdAt: DateTime.now().subtract(Duration(days: i + 2)),
          );
        }

        final decision = await datasource.canResubmit(
          itemId: _itemId,
          requesterId: _requesterId,
        );

        expect(decision.allowed, isFalse);
        expect(decision.reason, ResubmitReason.permanentBlock);
        expect(decision.attemptsRemaining, 0);
      },
    );

    test(
      '04 returns cooldown when the most-recent rejection on a non-Secret-'
      'Question post is newer than 6 hours ago',
      () async {
        await _seedItem(fs);
        final rejectedAt = DateTime.now().subtract(const Duration(hours: 2));
        await _seedRequest(
          fs,
          docId: 'req-recent',
          requesterId: _requesterId,
          status: 'rejected',
          createdAt: rejectedAt,
        );

        final decision = await datasource.canResubmit(
          itemId: _itemId,
          requesterId: _requesterId,
        );

        expect(decision.allowed, isFalse);
        expect(decision.reason, ResubmitReason.cooldown);
        expect(
          decision.retryAfter!.difference(rejectedAt).inMinutes,
          closeTo(360, 1),
        );
      },
    );

    test(
      '05 allows submission when the most-recent rejection on a non-Secret-'
      'Question post is older than 6 hours (cooldown expired)',
      () async {
        await _seedItem(fs);
        await _seedRequest(
          fs,
          docId: 'req-stale',
          requesterId: _requesterId,
          status: 'rejected',
          createdAt: DateTime.now().subtract(const Duration(hours: 7)),
        );

        final decision = await datasource.canResubmit(
          itemId: _itemId,
          requesterId: _requesterId,
        );

        expect(decision.allowed, isTrue);
        expect(decision.reason, ResubmitReason.allowed);
      },
    );

    test(
      '06 returns alreadyActive when the requester has a pending request '
      '— takes precedence over rejected-history checks',
      () async {
        await _seedItem(fs, secretQuestion: 'Q?');
        await _seedRequest(
          fs,
          docId: 'req-pending',
          requesterId: _requesterId,
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        final decision = await datasource.canResubmit(
          itemId: _itemId,
          requesterId: _requesterId,
        );

        expect(decision.allowed, isFalse);
        expect(decision.reason, ResubmitReason.alreadyActive);
      },
    );

    test(
      '07 ignores rejections by other requesters — policy is per-requester',
      () async {
        await _seedItem(fs, secretQuestion: 'Q?');
        for (var i = 0; i < 3; i++) {
          await _seedRequest(
            fs,
            docId: 'req-other-$i',
            requesterId: _otherRequester,
            status: 'rejected',
            createdAt: DateTime.now().subtract(Duration(days: i + 2)),
          );
        }

        final decision = await datasource.canResubmit(
          itemId: _itemId,
          requesterId: _requesterId,
        );

        expect(decision.allowed, isTrue);
        expect(decision.attemptsRemaining, 3);
      },
    );
  });
}
