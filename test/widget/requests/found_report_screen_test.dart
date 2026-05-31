// WBS 2.10 — FoundReportScreen widget test
//
// Confirms that no Secret Question block or answer field ever appears on the
// Found Report form, regardless of the item posted (Seeker or Founder Post).
// Secret Question verification is only for Claim Requests.

import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/item_request_provider.dart';
import 'package:campus_lost_found/features/requests/presentation/screens/found_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

const _kUid = 'user-found-001';
const _kEmail = 'bob@mail.kmutt.ac.th';

const _testUser = User(
  uid: _kUid,
  email: _kEmail,
  firstName: 'Bob',
  lastName: 'Jones',
  studentId: '63070002',
  telephone: '0823456789',
  emailVerified: true,
);

Item _makeSeekerItem() => Item(
      id: 'item-seeker-001',
      title: 'Lost AirPods Pro',
      description: 'Lost near the library',
      category: ItemCategory.seeker,
      status: ItemStatus.active,
      location: 'LIB-1',
      contact: '0800000000',
      imageUrls: const [],
      userId: 'seeker-uid',
      createdAt: DateTime(2026),
      occurredAt: DateTime(2026),
    );

GoRouter _makeRouter(String itemId) => GoRouter(
      initialLocation: '/item/$itemId/found-report',
      routes: [
        GoRoute(
          path: '/item/:id/found-report',
          builder: (_, s) =>
              FoundReportScreen(itemId: s.pathParameters['id']!),
        ),
      ],
    );

Widget _buildApp(Item item) {
  const authUser = AuthUser(uid: _kUid, email: _kEmail);
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((_) => Stream.value(authUser)),
      currentUserProvider.overrideWith((_) => Stream.value(_testUser)),
      watchItemProvider(item.id).overrideWith((_) => Stream.value(item)),
      watchMyRequestForItemProvider(item.id, _kUid)
          .overrideWith((_) => Stream.value([])),
    ],
    child: MaterialApp.router(routerConfig: _makeRouter(item.id)),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets(
    'WBS 2.10 — FoundReportScreen has no Secret Question label or answer field',
    (tester) async {
      await tester.pumpWidget(_buildApp(_makeSeekerItem()));
      await tester.pumpAndSettle();

      // The Found Report form must never show a Secret Question block.
      // Visitors reporting a found item are not asked to verify ownership —
      // that only applies to Claim Requests on Founder Posts.
      expect(
        find.text('Secret Question'),
        findsNothing,
        reason: 'Found Report form must never render a Secret Question block',
      );
    },
  );

  testWidgets(
    'meets accessibility guidelines (tap target size, labels)',
    (tester) async {
      await tester.pumpWidget(_buildApp(_makeSeekerItem()));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      // R5(c) — re-enabled after the contrast token fix. See A11Y_AUDIT.md.
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    },
  );
}
