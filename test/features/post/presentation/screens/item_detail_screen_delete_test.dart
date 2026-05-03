// WBS 2.7 — ItemDetailScreen delete flow widget tests
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/screens/item_detail_screen.dart';
import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';
import 'package:campus_lost_found/features/post/presentation/providers/post_provider.dart';

// ─── fakes ───────────────────────────────────────────────────────────────────

class _FakePostRepository extends Fake implements PostRepository {
  final bool pendingResult;
  _FakePostRepository({required this.pendingResult});

  @override
  Future<bool> hasPendingRequests(String itemId) async => pendingResult;

  @override
  Future<void> deleteItem(String itemId) async {}

  @override
  Future<Item> createItem(Item item) async => item;

  @override
  Future<void> updateItem(Item item) async {}
}

// ─── fixtures ────────────────────────────────────────────────────────────────

const _itemId = 'item-xyz';
const _ownerId = 'user-owner';

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
);

final _fakeOwner = User(
  uid: _ownerId,
  email: 'owner@mail.kmutt.ac.th',
  firstName: 'Own',
  lastName: 'Er',
  studentId: '64000001',
  telephone: '081-000-0001',
  emailVerified: true,
);

// ─── helper ──────────────────────────────────────────────────────────────────

Widget _buildScreen({required bool hasPendingRequests}) {
  return ProviderScope(
    overrides: [
      watchItemProvider(_itemId)
          .overrideWith((ref) => Stream.value(_fakeItem)),
      currentUserProvider
          .overrideWith((ref) => Stream.value(_fakeOwner)),
      postRepositoryProvider.overrideWith(
        (_) => _FakePostRepository(pendingResult: hasPendingRequests),
      ),
    ],
    child: const MaterialApp(home: ItemDetailScreen(itemId: _itemId)),
  );
}

// ─── tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ItemDetailScreen delete flow — WBS 2.7', () {
    testWidgets(
      '01 tapping delete with pending requests shows warning dialog',
      (tester) async {
        await tester.pumpWidget(_buildScreen(hasPendingRequests: true));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.text('Cannot delete'), findsOneWidget);
        expect(find.text('View requests'), findsOneWidget);
        expect(find.text('Delete post?'), findsNothing);
      },
    );

    testWidgets(
      '02 tapping delete with no pending requests shows confirmation dialog',
      (tester) async {
        await tester.pumpWidget(_buildScreen(hasPendingRequests: false));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.text('Delete post?'), findsOneWidget);
        expect(find.text('Cannot delete'), findsNothing);
      },
    );
  });
}
