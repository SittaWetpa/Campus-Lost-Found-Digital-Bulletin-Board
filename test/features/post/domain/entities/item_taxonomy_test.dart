// WBS 4.1 — ItemTaxonomy domain entity: pure Dart, no Firebase dependency
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/features/post/domain/entities/item_taxonomy.dart';

void main() {
  group('ItemTaxonomy — WBS 4.1 domain purity', () {
    test(
      '01a all enum values are constructible without Firebase being initialized',
      () {
        // Proves the domain entity has zero Flutter / Firebase dependency.
        // No Firebase.initializeApp() is called anywhere in this file.
        for (final taxonomy in ItemTaxonomy.values) {
          expect(taxonomy.id, isNotEmpty);
          expect(taxonomy.displayNameEn, isNotEmpty);
        }
      },
    );

    test(
      '01b fromId resolves every canonical id to the correct enum value',
      () {
        expect(ItemTaxonomy.fromId('electronics'), ItemTaxonomy.electronics);
        expect(ItemTaxonomy.fromId('bag_wallet'), ItemTaxonomy.bagWallet);
        expect(ItemTaxonomy.fromId('clothing'), ItemTaxonomy.clothing);
        expect(ItemTaxonomy.fromId('stationery'), ItemTaxonomy.stationery);
        expect(ItemTaxonomy.fromId('documents_cards'), ItemTaxonomy.documentsCards);
        expect(ItemTaxonomy.fromId('keys'), ItemTaxonomy.keys);
        expect(ItemTaxonomy.fromId('accessory'), ItemTaxonomy.accessory);
        expect(ItemTaxonomy.fromId('other'), ItemTaxonomy.other);
      },
    );

    test(
      '01c fromId falls back to ItemTaxonomy.other for any unknown id',
      () {
        expect(ItemTaxonomy.fromId('unknown_bucket'), ItemTaxonomy.other);
        expect(ItemTaxonomy.fromId(''), ItemTaxonomy.other);
        expect(ItemTaxonomy.fromId('ELECTRONICS'), ItemTaxonomy.other);
      },
    );

    test(
      '01d TaxonomyMeta extension returns non-empty placeholders and chips for every value',
      () {
        for (final taxonomy in ItemTaxonomy.values) {
          expect(
            taxonomy.titlePlaceholder,
            isNotEmpty,
            reason: '${taxonomy.id}.titlePlaceholder must not be empty',
          );
          expect(
            taxonomy.descPlaceholder,
            isNotEmpty,
            reason: '${taxonomy.id}.descPlaceholder must not be empty',
          );
          expect(
            taxonomy.chips,
            isNotEmpty,
            reason: '${taxonomy.id}.chips must not be empty',
          );
        }
      },
    );
  });
}
