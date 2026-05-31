import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:campus_lost_found/core/theme/app_tokens.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/item_category_chip.dart';

// Walk-in ribbon — blue stripe shown at the top of QR-submitted cards
class _WalkInRibbon extends StatelessWidget {
  const _WalkInRibbon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF3B5BDB),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: const Row(
        children: [
          Icon(Icons.qr_code, size: 12, color: Colors.white),
          SizedBox(width: 6),
          Text(
            'QR WALK-IN · HANDED IN AT SECURITY OFFICE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.isOwner,
    required this.onTap,
    this.showStatus = false,
  });

  final Item item;
  final bool isOwner;
  final VoidCallback onTap;

  /// When true, shows the item's status (Active/Resolved/Expired) as a chip.
  /// Used by MyPostsScreen; Feed does not show status.
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final isWalkIn = item.source == ItemSource.qrWalkIn;
    final isSensitive = item.isSensitive;

    final Color cardColor;
    final Color borderColor;
    final double borderWidth;

    if (isOwner) {
      cardColor = AppTokens.primary100;
      borderColor = AppTokens.primary400;
      borderWidth = 1.5;
    } else if (isSensitive) {
      cardColor = AppTokens.warnBg;
      borderColor = AppTokens.warnBorder;
      borderWidth = 1;
    } else if (isWalkIn) {
      cardColor = const Color(0xFFEEF2FF);
      borderColor = const Color(0xFFC7D2FE);
      borderWidth = 1;
    } else {
      cardColor = AppTokens.surface;
      borderColor = AppTokens.border;
      borderWidth = 1;
    }

    return Card(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isWalkIn) const _WalkInRibbon(),
                Padding(
                  padding: EdgeInsets.fromLTRB(isOwner ? 16 : 12, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Thumbnail(item: item),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Content(
                          item: item,
                          isOwner: isOwner,
                          showStatus: showStatus,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
    if (item.isSensitive) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFD4C8A8),
          borderRadius: BorderRadius.circular(AppTokens.rSm),
        ),
        alignment: Alignment.center,
        child: const Text('🔒', style: TextStyle(fontSize: 28)),
      );
    }

    final base = item.imageUrls.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.rSm),
            child: CachedNetworkImage(
              imageUrl: item.imageUrls.first,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _placeholder,
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
  const _Content({
    required this.item,
    required this.isOwner,
    required this.showStatus,
  });

  final Item item;
  final bool isOwner;
  final bool showStatus;

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
            if (item.isSensitive) const _SensitiveChip(),
            if (showStatus) _StatusChip(status: item.status),
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
        const SizedBox(height: 2),
        if (item.isSensitive)
          const Text(
            'Contact Security Office to retrieve',
            style: TextStyle(
              fontSize: 13,
              color: AppTokens.warn,
              fontStyle: FontStyle.italic,
            ),
          )
        else if (item.description.isNotEmpty)
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

class _SensitiveChip extends StatelessWidget {
  const _SensitiveChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppTokens.warnBg,
        borderRadius: BorderRadius.circular(AppTokens.pill),
      ),
      child: const Text(
        'SENSITIVE',
        style: TextStyle(
          color: AppTokens.warn,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      ItemStatus.active => ('ACTIVE', AppTokens.successBg, AppTokens.success),
      ItemStatus.resolved => ('RESOLVED', AppTokens.warnBg, AppTokens.warn),
      ItemStatus.expired =>
        ('EXPIRED', AppTokens.ink100, const Color(0xFF5C5242)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
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
