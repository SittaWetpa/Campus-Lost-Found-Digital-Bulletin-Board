import 'package:flutter/material.dart';
import 'package:campus_lost_found/core/theme/app_tokens.dart';
import 'package:campus_lost_found/features/post/domain/entities/item_taxonomy.dart';

extension TaxonomyIcon on ItemTaxonomy {
  IconData get iconData => switch (this) {
        ItemTaxonomy.electronics => Icons.devices_outlined,
        ItemTaxonomy.bagWallet => Icons.work_outline,
        ItemTaxonomy.clothing => Icons.checkroom_outlined,
        ItemTaxonomy.stationery => Icons.menu_book_outlined,
        ItemTaxonomy.documentsCards => Icons.badge_outlined,
        ItemTaxonomy.keys => Icons.key_outlined,
        ItemTaxonomy.accessory => Icons.watch_outlined,
        ItemTaxonomy.other => Icons.inbox_outlined,
      };
}

class ItemCategoryChip extends StatelessWidget {
  const ItemCategoryChip({
    super.key,
    required this.taxonomy,
    this.withLabel = true,
  });

  final ItemTaxonomy taxonomy;
  final bool withLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: withLabel
          ? const EdgeInsets.fromLTRB(6, 3, 8, 3)
          : const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTokens.ink100,
        borderRadius: BorderRadius.circular(AppTokens.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(taxonomy.iconData, size: 12, color: AppTokens.ink700),
          if (withLabel) ...[
            const SizedBox(width: 4),
            Text(
              taxonomy.displayNameEn,
              style: const TextStyle(
                color: AppTokens.ink700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Square icon badge — overlays the bottom-right of the feed-card thumbnail.
/// Matches the prototype's `ItemCategoryBadge` (shared.jsx) which uses surface
/// background with a hairline border, rather than the pill shape used by
/// [ItemCategoryChip].
class ItemCategoryBadge extends StatelessWidget {
  const ItemCategoryBadge({
    super.key,
    required this.taxonomy,
    this.size = 24,
  });

  final ItemTaxonomy taxonomy;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(
        taxonomy.iconData,
        size: size * 0.6,
        color: AppTokens.ink700,
      ),
    );
  }
}
