// D4 Evidence — Golden tests.
//
// These produce reference PNG snapshots of self-contained, deterministic
// presentation widgets so visual regressions surface in review. The widgets
// chosen take no Riverpod providers and load no network images, which keeps
// the goldens stable across machines.
//
// Regenerate the reference images after an intentional visual change:
//   flutter test --update-goldens test/golden/widget_golden_test.dart
//
// Reference images live in test/golden/goldens/.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/item_card.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/item_category_chip.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/sensitive_banner.dart';

final _fixedDate = DateTime(2024, 6, 1, 12);

final _walkInItem = Item(
  id: 'item-walkin-1',
  title: 'Found Wallet',
  description: 'Brown wallet found near the security office.',
  category: ItemCategory.founder,
  status: ItemStatus.active,
  location: 'Security Office',
  contact: '',
  imageUrls: const [],
  userId: 'walkin',
  createdAt: _fixedDate,
  source: ItemSource.qrWalkIn,
);

final _seekerItem = Item(
  id: 'item-normal-1',
  title: 'Lost Phone',
  description: 'Black phone lost in the library.',
  category: ItemCategory.seeker,
  status: ItemStatus.active,
  location: 'Library',
  contact: '0812345678',
  imageUrls: const [],
  userId: 'uid-1',
  createdAt: _fixedDate,
  source: ItemSource.web,
);

// Wraps a widget in a fixed-width painted surface so the golden is stable.
Widget _surface(Widget child, {double width = 360}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Scaffold(
    backgroundColor: const Color(0xFFFFFDF7),
    body: Center(
      child: SizedBox(
        width: width,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);

void main() {
  group('Golden — SensitiveBanner', () {
    testWidgets('renders the sensitive-item warning banner', (tester) async {
      await tester.pumpWidget(_surface(const SensitiveBanner()));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SensitiveBanner),
        matchesGoldenFile('goldens/sensitive_banner.png'),
      );
    });
  });

  group('Golden — ItemCategoryChip', () {
    testWidgets('electronics chip with label', (tester) async {
      await tester.pumpWidget(
        _surface(
          const Align(
            alignment: Alignment.centerLeft,
            child: ItemCategoryChip(taxonomy: ItemTaxonomy.electronics),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ItemCategoryChip),
        matchesGoldenFile('goldens/category_chip_electronics.png'),
      );
    });

    testWidgets('keys chip with label', (tester) async {
      await tester.pumpWidget(
        _surface(
          const Align(
            alignment: Alignment.centerLeft,
            child: ItemCategoryChip(taxonomy: ItemTaxonomy.keys),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ItemCategoryChip),
        matchesGoldenFile('goldens/category_chip_keys.png'),
      );
    });
  });

  group('Golden — ItemCard', () {
    testWidgets('seeker post card', (tester) async {
      await tester.pumpWidget(
        _surface(ItemCard(item: _seekerItem, isOwner: false, onTap: () {})),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ItemCard),
        matchesGoldenFile('goldens/item_card_seeker.png'),
      );
    });

    testWidgets('founder walk-in card with QR ribbon', (tester) async {
      // Wider surface: the test-only Ahem font renders the "QR WALK-IN" ribbon
      // label much wider than the real font, so 360 px overflows the ribbon row.
      await tester.pumpWidget(
        _surface(
          ItemCard(item: _walkInItem, isOwner: false, onTap: () {}),
          width: 620,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ItemCard),
        matchesGoldenFile('goldens/item_card_walkin.png'),
      );
    });
  });
}
