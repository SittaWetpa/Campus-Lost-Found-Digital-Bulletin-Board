// WBS 2.7 — ItemDetailScreen delete flow widget tests
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/core/domain/entities/feature_flags.dart';
import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/screens/item_detail_screen.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/item_request_provider.dart';

// ─── fake feature flags ───────────────────────────────────────────────────────

class _FakeFeatureFlags implements FeatureFlagService {
  const _FakeFeatureFlags();

  @override
  bool get secretQuestionEnabled => true;
  @override
  bool get sensitiveItemEnabled => true;
  @override
  String get securityOfficeContact => '02-470-9999';
  @override
  Future<void> fetchAndActivate() async {}
  @override
  DateTime get lastFetchTime => DateTime.fromMillisecondsSinceEpoch(0);
  @override
  FeatureFlags get currentFlags => FeatureFlags.defaults;
}

// ─── fixtures ────────────────────────────────────────────────────────────────

const _itemId = 'item-xyz';
const _ownerId = 'user-owner';

final _authUser = AuthUser(uid: _ownerId, email: 'owner@mail.kmutt.ac.th');

final _fakeItem = Item(
  id: _itemId,
  title: 'Lost Keys',
  description: 'Key ring with KMUTT card',
  category: ItemCategory.seeker,
  status: ItemStatus.active,
  location: 'Canteen',
  contact: '081-000-0001',
  imageUrls: const [],
  userId: _ownerId,
  createdAt: DateTime(2026, 5, 1),
  occurredAt: DateTime(2026, 5, 1),
);

final _pendingRequest = ItemRequest(
  id: 'req-001',
  itemId: _itemId,
  requesterId: 'user-other',
  requesterName: 'Other User',
  requesterContact: '081-000-0002',
  studentId: '64000002',
  type: RequestType.claim,
  status: RequestStatus.pending,
  createdAt: DateTime(2026, 5, 1),
);

// ─── helper ──────────────────────────────────────────────────────────────────

Widget _buildScreen({required List<ItemRequest> requests}) {
  return ProviderScope(
    overrides: [
      watchItemProvider(_itemId)
          .overrideWith((ref) => Stream.value(_fakeItem)),
      authStateProvider
          .overrideWith((ref) => Stream.value(_authUser)),
      watchRequestsForItemProvider(_itemId)
          .overrideWith((ref) => Stream.value(requests)),
      featureFlagsProvider.overrideWith((_) => const _FakeFeatureFlags()),
      // Poster display — null is acceptable; _PosterRow handles it gracefully.
      getUserByIdProvider(_ownerId)
          .overrideWith((ref) async => null),
    ],
    child: const MaterialApp(home: ItemDetailScreen(id: _itemId)),
  );
}

// ─── tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ItemDetailScreen delete flow — WBS 2.7', () {
    testWidgets(
      '01 tapping delete with pending requests shows warning dialog',
      (tester) async {
        await tester.pumpWidget(_buildScreen(requests: [_pendingRequest]));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.text('Resolve requests first'), findsOneWidget);
        expect(find.text('Delete this post?'), findsNothing);
      },
    );

    testWidgets(
      '02 tapping delete with no pending requests shows confirmation dialog',
      (tester) async {
        await tester.pumpWidget(_buildScreen(requests: const []));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.text('Delete this post?'), findsOneWidget);
        expect(find.text('Resolve requests first'), findsNothing);
      },
    );
  });
}
