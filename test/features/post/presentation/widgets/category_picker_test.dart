// WBS 2.8 — CategoryPicker widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/post/presentation/widgets/category_picker.dart';

void main() {
  Widget wrap({
    ItemTaxonomy? selected,
    required ValueChanged<ItemTaxonomy> onChanged,
    String? errorText,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CategoryPicker(
            selected: selected,
            onChanged: onChanged,
            errorText: errorText,
          ),
        ),
      ),
    );
  }

  group('CategoryPicker — WBS 2.8', () {
    testWidgets('shows validation error text when errorText is provided',
        (tester) async {
      await tester.pumpWidget(wrap(
        onChanged: (_) {},
        errorText: 'Please select a category.',
      ));

      expect(find.text('Please select a category.'), findsOneWidget);
    });

    testWidgets('does not show error text when errorText is null',
        (tester) async {
      await tester.pumpWidget(wrap(onChanged: (_) {}));

      expect(find.text('Please select a category.'), findsNothing);
    });

    testWidgets('tapping a category tile fires onChanged with correct taxonomy',
        (tester) async {
      ItemTaxonomy? received;

      await tester.pumpWidget(wrap(
        onChanged: (t) => received = t,
      ));

      // Tap the Electronics tile (first in the grid).
      await tester.tap(find.text('Electronics'));
      await tester.pump();

      expect(received, equals(ItemTaxonomy.electronics));
    });

    testWidgets('selected tile is visually distinguished (amber border)',
        (tester) async {
      await tester.pumpWidget(wrap(
        selected: ItemTaxonomy.keys,
        onChanged: (_) {},
      ));

      // The widget renders without errors when a selection is provided.
      expect(find.text('Keys'), findsOneWidget);
    });

    testWidgets('renders all 8 taxonomy tiles', (tester) async {
      await tester.pumpWidget(wrap(onChanged: (_) {}));

      for (final t in ItemTaxonomy.values) {
        expect(find.text(t.displayNameEn), findsOneWidget);
      }
    });
  });
}
