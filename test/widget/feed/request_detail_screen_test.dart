// WBS 1.3 — RequestDetailScreen widget tests

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
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/item_request_provider.dart';
import 'package:campus_lost_found/features/requests/presentation/screens/request_detail_screen.dart';

// ── constants ─────────────────────────────────────────────────────────────────

const _posterUid  = 'uid-poster';
const _visitorUid = 'uid-visitor';

// ── factories ─────────────────────────────────────────────────────────────────

Item _makeItem({
  bool isSensitive = false,
  String? secretQuestion,
  String? secretAnswer,
}) =>
    Item(
      id: 'item-001',
      title: 'Blue Wallet',
      description: 'Found near cafeteria',
      category: ItemCategory.founder,
      status: ItemStatus.active,
      location: 'CB2',
      contact: '0800000000',
      imageUrls: const [],
      userId: _posterUid,
      createdAt: DateTime(2025, 1, 1),
      occurredAt: DateTime(2025, 1, 1),
      isSensitive: isSensitive,
      secretQuestion: secretQuestion,
      secretAnswer: secretAnswer,
    );

ItemRequest _makeRequest({
  String requesterId = _visitorUid,
  RequestType type = RequestType.claim,
  RequestStatus status = RequestStatus.pending,
  String? visitorAnswer,
  String? message,
}) =>
    ItemRequest(
      id: 'req-001',
      itemId: 'item-001',
      requesterId: requesterId,
      requesterName: 'Alice Smith',
      requesterContact: '0812345678',
      studentId: '63070001',
      type: type,
      status: status,
      createdAt: DateTime(2025, 1, 1),
      visitorAnswer: visitorAnswer,
      message: message,
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

GoRouter _makeRouter({required String currentUserId}) => GoRouter(
      initialLocation: '/item/item-001/request/req-001',
      routes: [
        GoRoute(
          path: '/item/:itemId/request/:reqId',
          builder: (_, s) => RequestDetailScreen(
            itemId: s.pathParameters['itemId']!,
            reqId: s.pathParameters['reqId']!,
          ),
        ),
      ],
    );

Widget _buildApp({
  required Item item,
  required ItemRequest request,
  required String currentUserId,
  bool secretQuestionEnabled = true,
}) {
  final user     = _makeUser(uid: currentUserId);
  final authUser = AuthUser(uid: currentUserId, email: user.email);

  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((_) => Stream.value(authUser)),
      currentUserProvider.overrideWith((_) => Stream.value(user)),
      watchItemProvider(item.id).overrideWith((_) => Stream.value(item)),
      watchSingleRequestProvider(item.id, request.id)
          .overrideWith((_) => Stream.value(request)),
      getItemSecretAnswerProvider(item.id)
          .overrideWith((_) async => item.secretAnswer),
      featureFlagsProvider.overrideWith(
        (_) => _FakeFeatureFlags(secretQuestionEnabled: secretQuestionEnabled),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: _makeRouter(currentUserId: currentUserId),
    ),
  );
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('RequestDetailScreen — WBS 1.3', () {
    testWidgets(
      '01 Poster with secret question and secretQuestionEnabled=true — '
      'Verification section shows question, expected answer, visitor answer',
      (tester) async {
        final item = _makeItem(
          secretQuestion: 'What brand is the wallet?',
          secretAnswer: 'Fossil',
        );
        final request = _makeRequest(
          requesterId: _visitorUid,
          visitorAnswer: 'Fossil',
        );

        await tester.pumpWidget(
          _buildApp(item: item, request: request, currentUserId: _posterUid),
        );
        await tester.pumpAndSettle();

        expect(find.text('VERIFICATION'),                  findsOneWidget);
        expect(find.textContaining('What brand'),          findsOneWidget);
        expect(find.text('Fossil'),                        findsWidgets);
      },
    );

    testWidgets(
      '02 Poster with secretQuestionEnabled=false — '
      'Verification section hidden',
      (tester) async {
        final item    = _makeItem(secretQuestion: 'What brand?');
        final request = _makeRequest(visitorAnswer: 'Fossil');

        await tester.pumpWidget(
          _buildApp(
            item: item,
            request: request,
            currentUserId: _posterUid,
            secretQuestionEnabled: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('VERIFICATION'), findsNothing);
      },
    );

    testWidgets(
      '03 Poster viewing pending request — Approve and Reject buttons visible',
      (tester) async {
        final item    = _makeItem();
        final request = _makeRequest(requesterId: _visitorUid);

        await tester.pumpWidget(
          _buildApp(item: item, request: request, currentUserId: _posterUid),
        );
        await tester.pumpAndSettle();

        expect(find.text('Approve'), findsOneWidget);
        expect(find.text('Reject'),  findsOneWidget);
        expect(find.text('Cancel my request'), findsNothing);
      },
    );

    testWidgets(
      '04 Requester viewing own pending request — '
      'Cancel button visible, Approve/Reject hidden',
      (tester) async {
        final item    = _makeItem();
        final request = _makeRequest(requesterId: _visitorUid);

        await tester.pumpWidget(
          _buildApp(item: item, request: request, currentUserId: _visitorUid),
        );
        await tester.pumpAndSettle();

        expect(find.text('Cancel my request'), findsOneWidget);
        expect(find.text('Approve'),           findsNothing);
        expect(find.text('Reject'),            findsNothing);
      },
    );

    testWidgets(
      '05 Approved request — no action buttons shown',
      (tester) async {
        final item    = _makeItem();
        final request = _makeRequest(status: RequestStatus.approved);

        await tester.pumpWidget(
          _buildApp(item: item, request: request, currentUserId: _posterUid),
        );
        await tester.pumpAndSettle();

        expect(find.text('Approve'),           findsNothing);
        expect(find.text('Reject'),            findsNothing);
        expect(find.text('Cancel my request'), findsNothing);
      },
    );
  });
}
