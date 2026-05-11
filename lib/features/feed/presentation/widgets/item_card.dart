import 'package:flutter/material.dart';
import 'package:campus_lost_found/core/theme/app_tokens.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/item_category_chip.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.isOwner,
    required this.onTap,
  });

  final Item item;
  final bool isOwner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTokens.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        side: BorderSide(
          color: isOwner ? AppTokens.primary400 : AppTokens.border,
          width: isOwner ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(isOwner ? 16 : 12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumbnail(item: item),
                  const SizedBox(width: 12),
                  Expanded(child: _Content(item: item, isOwner: isOwner)),
                ],
              ),
            ),
            if (isOwner)
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 4,
                  child: ColoredBox(color: AppTokens.primary500),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item});

  final Item item;

  static const _palette = [
    Color(0xFF795548),
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFF4527A0),
    Color(0xFF00695C),
    Color(0xFFC62828),
    Color(0xFF37474F),
    Color(0xFFE65100),
  ];

  Color get _color => _palette[item.id.hashCode.abs() % _palette.length];

  @override
  Widget build(BuildContext context) {
    final base = item.imageUrls.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.rSm),
            child: Image.network(
              item.imageUrls.first,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder,
            ),
          )
        : _placeholder;

    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(top: 0, left: 0, child: base),
          if (item.itemTaxonomy != null)
            Positioned(
              bottom: -2,
              right: -2,
              child: ItemCategoryBadge(taxonomy: item.itemTaxonomy!),
            ),
        ],
      ),
    );
  }

  Widget get _placeholder => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(AppTokens.rSm),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(6),
        child: Text(
          item.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      );
}

class _Content extends StatelessWidget {
  const _Content({required this.item, required this.isOwner});

  final Item item;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _CategoryBadge(category: item.category),
            if (item.itemTaxonomy != null)
              ItemCategoryChip(taxonomy: item.itemTaxonomy!),
            if (isOwner) const _YouBadge(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          item.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTokens.ink900,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (item.description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppTokens.ink600,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 13, color: AppTokens.ink500),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                item.location,
                style: const TextStyle(fontSize: 12, color: AppTokens.ink500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.access_time, size: 13, color: AppTokens.ink500),
            const SizedBox(width: 2),
            Text(
              _relativeTime(item.createdAt),
              style: const TextStyle(fontSize: 12, color: AppTokens.ink500),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final ItemCategory category;

  @override
  Widget build(BuildContext context) {
    final isFounder = category == ItemCategory.founder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isFounder ? AppTokens.successBg : AppTokens.seekerBg,
        borderRadius: BorderRadius.circular(AppTokens.pill),
      ),
      child: Text(
        isFounder ? 'Found · Founder' : 'Lost · Seeker',
        style: TextStyle(
          color: isFounder ? AppTokens.success : AppTokens.seeker,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.02,
        ),
      ),
    );
  }
}

class _YouBadge extends StatelessWidget {
  const _YouBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTokens.primary500,
        borderRadius: BorderRadius.circular(AppTokens.pill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 11, color: Colors.white),
          SizedBox(width: 2),
          Text(
            'YOU',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return '${(diff.inDays / 30).floor()}mo ago';
}
