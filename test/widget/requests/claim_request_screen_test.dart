// WBS 2.10 — ClaimRequestScreen widget tests
//
// Test cases:
//   01 — Secret Question block shown when item.secretQuestion is set and flag enabled
//   02 — Submitting without filling the answer shows "Answer is required" error
//   03 — Poster's secret answer is never displayed; answer field starts empty
//   04 — No Secret Question block when item has no secretQuestion
//   05 — Existing pending request shows AlreadySubmitted screen

import 'package:campus_lost_found/core/domain/entities/feature_flags.dart';
import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/item_request_provider.dart';
import 'package:campus_lost_found/features/requests/presentation/screens/claim_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeFeatureFlags implements FeatureFlagService {
  const _FakeFeatureFlags({this.secretQuestionEnabled = true});

  @override
  final bool secretQuestionEnabled;
  @override
  bool get sensitiveItemEnabled => true;
  @override
  String get securityOfficeContact => '02-470-9999';
  @override
  Future<void> fetchAndActivate() async {}
  @override
  DateTime get lastFetchTime => DateTime.fromMillisecondsSinceEpoch(0);
  @override
  FeatureFlags get currentFlags => FeatureFlags(
        secretQuestionEnabled: secretQuestionEnabled,
        sensitiveItemEnabled: true,
        securityOfficeContact: '02-470-9999',
        sensitiveCategories: const [
          'credit_card',
          'id_card',
          'passport',
          'key',
          'document',
        ],
      );
}

// ── Test data helpers ─────────────────────────────────────────────────────────

const _kUid = 'user-test-001';
const _kEmail = 'alice@mail.kmutt.ac.th';

const _testUser = User(
  uid: _kUid,
  email: _kEmail,
  firstName: 'Alice',
  lastName: 'Smith',
  studentId: '63070001',
  telephone: '0812345678',
  emailVerified: true,
);

Item _makeItem({String id = 'item-001', String? secretQuestion}) => Item(
      id: id,
      title: 'Black Wallet',
      description: 'Black leather wallet',
      category: ItemCategory.founder,
      status: ItemStatus.active,
      location: 'CB2',
      contact: '0800000000',
      imageUrls: const [],
      userId: 'poster-uid',
      createdAt: DateTime(2026),
      occurredAt: DateTime(2026),
      secretQuestion: secretQuestion,
    );

GoRouter _makeRouter(String itemId) => GoRouter(
      initialLocation: '/item/$itemId/claim',
      routes: [
        GoRoute(
          path: '/item/:id/claim',
          builder: (_, s) =>
              ClaimRequestScreen(itemId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/item/:itemId/request/:requestId',
          builder: (_, __) =>
              const Scaffold(body: Text('Request Detail')),
        ),
      ],
    );

Widget _buildApp({
  required Item item,
  List<ItemRequest> myRequests = const [],
  bool secretQuestionEnabled = true,
}) {
  const authUser = AuthUser(uid: _kUid, email: _kEmail);
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((_) => Stream.value(authUser)),
      currentUserProvider.overrideWith((_) => Stream.value(_testUser)),
      watchItemProvider(item.id).overrideWith((_) => Stream.value(item)),
      watchMyRequestForItemProvider(item.id, _kUid)
          .overrideWith((_) => Stream.value(myRequests)),
      featureFlagsProvider.overrideWith(
        (_) => _FakeFeatureFlags(
          secretQuestionEnabled: secretQuestionEnabled,
        ),
      ),
    ],
    child: MaterialApp.router(routerConfig: _makeRouter(item.id)),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // 01 ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'WBS 2.10-01 — Secret Question block appears when item.secretQuestion is '
    'set and secretQuestionEnabled flag is true',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          item: _makeItem(secretQuestion: 'What brand is the wallet?'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Secret Question'),
        findsOneWidget,
        reason: 'Block header "Secret Question" must be visible',
      );
      expect(
        find.text('"What brand is the wallet?"'),
        findsOneWidget,
        reason: 'Question text must appear wrapped in double quotes',
      );
      expect(
        find.textContaining('No hints.'),
        findsOneWidget,
        reason:
            'Footer "No hints. The poster will verify your answer manually." '
            'must appear inside the Secret Question block',
      );
    },
  );

  // 02 ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'WBS 2.10-02 — submitting without filling the answer shows '
    '"Answer is required" inline validation error',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          item: _makeItem(secretQuestion: 'What brand is the wallet?'),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll the submit button into view and tap without filling the answer.
      await tester.ensureVisible(find.text('Send claim request'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send claim request'));
      await tester.pumpAndSettle();

      expect(
        find.text('Answer is required'),
        findsOneWidget,
        reason:
            'Inline error must appear next to the answer field when submitted '
            'with an empty answer',
      );
    },
  );

  // 03 ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'WBS 2.10-03 — poster\'s secret answer is never displayed; '
    'all text fields start empty',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          item: _makeItem(secretQuestion: 'What brand is the wallet?'),
        ),
      );
      await tester.pumpAndSettle();

      // The form has two TextFields: description (optional) and answer.
      // Neither should be pre-filled — the poster's real answer is never
      // shown to the claimant.
      for (final el in find.byType(TextField).evaluate()) {
        final widget = el.widget as TextField;
        expect(
          widget.controller?.text ?? '',
          isEmpty,
          reason: 'No TextField should be pre-filled with the secret answer',
        );
      }
    },
  );

  // 04 ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'WBS 2.10-04 — no Secret Question block when item has no secretQuestion',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(item: _makeItem(secretQuestion: null)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Secret Question'),
        findsNothing,
        reason:
            'Block must not render when the item has no secretQuestion set',
      );
    },
  );

  // 05 ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'WBS 2.10-05 — existing pending request shows AlreadySubmitted screen '
    'with "Already submitted" heading and "View my request" button',
    (tester) async {
      final pendingRequest = ItemRequest(
        id: 'req-existing-001',
        itemId: 'item-001',
        requesterId: _kUid,
        requesterName: 'Alice Smith',
        requesterContact: '0812345678',
        studentId: '63070001',
        type: RequestType.claim,
        status: RequestStatus.pending,
        createdAt: DateTime(2026),
      );

      await tester.pumpWidget(
        _buildApp(
          item: _makeItem(),
          myRequests: [pendingRequest],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Already submitted'),
        findsOneWidget,
        reason: 'AlreadySubmitted heading must appear when a request exists',
      );
      expect(
        find.text('View my request'),
        findsOneWidget,
        reason: 'CTA button to view the existing request must be present',
      );
    },
  );
}
