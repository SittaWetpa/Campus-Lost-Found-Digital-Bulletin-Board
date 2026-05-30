// WBS 1.3 — ItemDetailScreen widget tests

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_lost_found/core/domain/entities/feature_flags.dart';
import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/screens/item_detail_screen.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/item_request_provider.dart';

// ── constants ─────────────────────────────────────────────────────────────────

const _posterUid  = 'uid-poster';
const _visitorUid = 'uid-visitor';

// ── factories ─────────────────────────────────────────────────────────────────

Item _makeItem({
  String id = 'item-001',
  String userId = _posterUid,
  ItemCategory category = ItemCategory.founder,
  ItemStatus status = ItemStatus.active,
  bool isSensitive = false,
  String? secretQuestion,
  String? secretAnswer,
  DateTime? editedAt,
}) =>
    Item(
      id: id,
      title: 'Test Item',
      description: 'A test description',
      category: category,
      status: status,
      location: 'CB2',
      contact: '0800000000',
      imageUrls: const [],
      userId: userId,
      createdAt: DateTime(2025, 1, 1),
      occurredAt: DateTime(2025, 1, 1),
      isSensitive: isSensitive,
      secretQuestion: secretQuestion,
      secretAnswer: secretAnswer,
      editedAt: editedAt,
    );

User _makeUser({String uid = _visitorUid}) => User(
      uid: uid,
      email: 'test@mail.kmutt.ac.th',
      firstName: 'Test',
      lastName: 'User',
      studentId: '64000000',
      telephone: '0800000000',
      emailVerified: true,
    );

ItemRequest _makeRequest({
  String id = 'req-001',
  String requesterId = _visitorUid,
  RequestStatus status = RequestStatus.pending,
}) =>
    ItemRequest(
      id: id,
      itemId: 'item-001',
      requesterId: requesterId,
      requesterName: 'Visitor User',
      requesterContact: '0800000001',
      studentId: '65000001',
      type: RequestType.claim,
      status: status,
      createdAt: DateTime(2025, 1, 1),
    );

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
          'credit_card', 'id_card', 'passport', 'key', 'document'
        ],
      );
}

GoRouter _makeRouter() => GoRouter(
      initialLocation: '/item/item-001',
      routes: [
        GoRoute(
          path: '/item/:id',
          builder: (_, s) =>
              ItemDetailScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/item/:itemId/request/:reqId',
          builder: (_, s) => Scaffold(
            body: Text('RequestDetail:${s.pathParameters['reqId']}'),
          ),
        ),
        GoRoute(
          path: '/post/:id/edit',
          builder: (_, __) => const Scaffold(body: Text('EditPost')),
        ),
      ],
    );

Widget _buildApp({
  required Item item,
  required String currentUserId,
  List<ItemRequest> requests = const [],
  bool secretQuestionEnabled = true,
}) {
  final user     = _makeUser(uid: currentUserId);
  final authUser = AuthUser(uid: currentUserId, email: user.email);
  final poster   = _makeUser(uid: _posterUid);

  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((_) => Stream.value(authUser)),
      currentUserProvider.overrideWith((_) => Stream.value(user)),
      watchItemProvider(item.id).overrideWith((_) => Stream.value(item)),
      getUserByIdProvider(item.userId).overrideWith((_) async => poster),
      watchRequestsForItemProvider(item.id)
          .overrideWith((_) => Stream.value(requests)),
      watchMyRequestForItemProvider(item.id, currentUserId)
          .overrideWith((_) => Stream.value(requests)),
      featureFlagsProvider.overrideWith(
        (_) => _FakeFeatureFlags(secretQuestionEnabled: secretQuestionEnabled),
      ),
    ],
    child: MaterialApp.router(routerConfig: _makeRouter()),
  );
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ItemDetailScreen — WBS 1.3', () {
    testWidgets(
      '01 Poster on active item — edit and delete icons visible, '
      'claim button hidden',
      (tester) async {
        final item = _makeItem(userId: _posterUid);

        await tester.pumpWidget(
          _buildApp(item: item, currentUserId: _posterUid),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.edit_outlined),   findsOneWidget);
        expect(find.byIcon(Icons.delete_outline),  findsOneWidget);
        expect(find.text('Submit Claim Request'),  findsNothing);
        expect(find.text('Submit Found Report'),   findsNothing);
      },
    );

    testWidgets(
      '02 Visitor on Founder Post — Claim Request button visible, '
      'requests inbox hidden',
      (tester) async {
        final item = _makeItem(
          userId: _posterUid,
          category: ItemCategory.founder,
        );

        await tester.pumpWidget(
          _buildApp(item: item, currentUserId: _visitorUid),
        );
        await tester.pumpAndSettle();

        expect(find.text('Submit Claim Request'), findsOneWidget);
        expect(find.text('Requests inbox'),       findsNothing);
        expect(find.byIcon(Icons.edit_outlined),  findsNothing);
      },
    );

    testWidgets(
      '03 Visitor on Founder Post with isSensitive=true — '
      'SensitiveBanner shown, claim button replaced by security CTA',
      (tester) async {
        final item = _makeItem(
          userId: _posterUid,
          category: ItemCategory.founder,
          isSensitive: true,
        );

        await tester.pumpWidget(
          _buildApp(item: item, currentUserId: _visitorUid),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('cannot be claimed through the app'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Contact Security Office'),
          findsWidgets,
        );
        expect(find.text('Submit Claim Request'), findsNothing);
      },
    );

    testWidgets(
      '04 Poster on sensitive active item — '
      '"Mark as resolved" button visible',
      (tester) async {
        final item = _makeItem(
          userId: _posterUid,
          isSensitive: true,
        );

        await tester.pumpWidget(
          _buildApp(item: item, currentUserId: _posterUid),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Mark as resolved'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '05 secret_question_enabled=false — secret question notice hidden',
      (tester) async {
        final item = _makeItem(
          userId: _posterUid,
          category: ItemCategory.founder,
          secretQuestion: 'What brand is the wallet?',
        );

        await tester.pumpWidget(
          _buildApp(
            item: item,
            currentUserId: _visitorUid,
            secretQuestionEnabled: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('protected by a secret question'),
          findsNothing,
        );
      },
    );

    testWidgets(
      '06 Visitor with existing request — '
      '"View my request" button shown, no claim button',
      (tester) async {
        final item = _makeItem(
          userId: _posterUid,
          category: ItemCategory.founder,
        );
        final myRequest = _makeRequest(requesterId: _visitorUid);

        await tester.pumpWidget(
          _buildApp(
            item: item,
            currentUserId: _visitorUid,
            requests: [myRequest],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('View my request'),       findsOneWidget);
        expect(find.text('Submit Claim Request'),  findsNothing);
      },
    );

    testWidgets(
      '07 Visitor on Seeker Post — '
      '"Submit Found Report" button visible, Claim Request hidden',
      (tester) async {
        final item = _makeItem(
          userId: _posterUid,
          category: ItemCategory.seeker,
        );

        await tester.pumpWidget(
          _buildApp(item: item, currentUserId: _visitorUid),
        );
        await tester.pumpAndSettle();

        expect(find.text('Submit Found Report'),   findsOneWidget);
        expect(find.text('Submit Claim Request'),  findsNothing);
        expect(find.byIcon(Icons.edit_outlined),   findsNothing);
        expect(find.byIcon(Icons.delete_outline),  findsNothing);
      },
    );

    testWidgets(
      '08 Item with editedAt present — "Edited · [time]" label rendered',
      (tester) async {
        final item = _makeItem(
          userId: _posterUid,
          editedAt: DateTime(2025, 6, 1),
        );

        await tester.pumpWidget(
          _buildApp(item: item, currentUserId: _posterUid),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Edited ·'), findsOneWidget);
      },
    );

    testWidgets(
      '09 WBS 2.4 — Poster taps delete with pending requests — '
      '"Resolve requests first" warning dialog shown, Delete button absent',
      (tester) async {
        final item           = _makeItem(userId: _posterUid);
        final pendingRequest = _makeRequest(requesterId: _visitorUid);

        await tester.pumpWidget(
          _buildApp(
            item: item,
            currentUserId: _posterUid,
            requests: [pendingRequest],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.text('Resolve requests first'), findsOneWidget);
        expect(find.text('Delete'), findsNothing);
      },
    );

    testWidgets(
      'meets accessibility guidelines (tap target size, labels)',
      (tester) async {
        final item = _makeItem(userId: _visitorUid);
        await tester.pumpWidget(
          _buildApp(item: item, currentUserId: _visitorUid),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        // R5(c) — re-enabled after the contrast token fix (metadata → ink600).
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      },
    );
  });
}
