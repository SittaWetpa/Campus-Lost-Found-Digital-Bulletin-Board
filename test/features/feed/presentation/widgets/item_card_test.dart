// WBS 2.15 — ItemCard widget tests: QR walk-in ribbon rendering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/item_card.dart';

// ── Fake data ─────────────────────────────────────────────────────────────────

final _now = DateTime(2024, 6, 1, 12);

final _walkInItem = Item(
  id: 'item-walkin-1',
  title: 'Found Wallet',
  description: 'Brown wallet found near the security office.',
  category: ItemCategory.founder,
  status: ItemStatus.active,
  location: 'Security Office',
  contact: '',
  imageUrls: [],
  userId: 'walkin',
  createdAt: _now,
  source: ItemSource.qrWalkIn,
);

final _normalItem = Item(
  id: 'item-normal-1',
  title: 'Lost Phone',
  description: 'Black phone lost in the library.',
  category: ItemCategory.seeker,
  status: ItemStatus.active,
  location: 'Library',
  contact: '0812345678',
  imageUrls: [],
  userId: 'uid-1',
  createdAt: _now,
  source: ItemSource.web,
);

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildCard(Item item, {bool isOwner = false}) => MaterialApp(
      home: Scaffold(
        body: ItemCard(
          item: item,
          isOwner: isOwner,
          onTap: () {},
        ),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ItemCard — WBS 2.15 walk-in ribbon', () {
    testWidgets(
      '06a walk-in item renders QR ribbon with correct label text',
      (tester) async {
        await tester.pumpWidget(_buildCard(_walkInItem));
        await tester.pumpAndSettle();

        expect(find.textContaining('QR WALK-IN'), findsOneWidget);
      },
    );

    testWidgets(
      '06b non-walk-in item does not render QR ribbon',
      (tester) async {
        await tester.pumpWidget(_buildCard(_normalItem));
        await tester.pumpAndSettle();

        expect(find.textContaining('QR WALK-IN'), findsNothing);
      },
    );

    testWidgets(
      '06c walk-in ribbon is rendered inside a blue container '
      '(Color 0xFF3B5BDB)',
      (tester) async {
        await tester.pumpWidget(_buildCard(_walkInItem));
        await tester.pumpAndSettle();

        final blueContainer = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) => c.color == const Color(0xFF3B5BDB));
        expect(blueContainer, isNotEmpty);
      },
    );
  });
}
