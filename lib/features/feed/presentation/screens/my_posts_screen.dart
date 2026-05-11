import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/core/theme/app_tokens.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/item_category_chip.dart';

// ── Screen ───────────────────────────────────────────────────────────────────

class MyPostsScreen extends ConsumerStatefulWidget {
  const MyPostsScreen({super.key});

  @override
  ConsumerState<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends ConsumerState<MyPostsScreen> {
  bool _activeTab = true;

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final uid = authUser?.uid ?? '';
    final itemsAsync = uid.isNotEmpty
        ? ref.watch(watchMyItemsProvider(uid))
        : const AsyncData<List<Item>>([]);

    final all = itemsAsync.valueOrNull ?? [];
    final active = all.where((i) => i.status == ItemStatus.active).toList();
    final resolved = all.where((i) => i.status == ItemStatus.resolved).toList();
    final list = _activeTab ? active : resolved;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        backgroundColor: AppTokens.bg,
        elevation: 0,
        foregroundColor: AppTokens.ink900,
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'My Posts',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
            if (itemsAsync.hasValue)
              Text(
                '${all.length} total · ${active.length} active · ${resolved.length} resolved',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppTokens.ink500,
                ),
              ),
          ],
        ),
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTokens.border),
        ),
      ),
      body: authUser == null
          ? const Center(child: Text('Not logged in.'))
          : Column(
              children: [
                // ── Tab row ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTokens.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _Tab(
                          label: 'Active',
                          count: active.length,
                          selected: _activeTab,
                          onTap: () => setState(() => _activeTab = true),
                        ),
                        _Tab(
                          label: 'Resolved',
                          count: resolved.length,
                          selected: !_activeTab,
                          onTap: () => setState(() => _activeTab = false),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── List ─────────────────────────────────────────────────────
                Expanded(
                  child: itemsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Failed to load your posts.')),
                    data: (_) => list.isEmpty
                        ? _EmptyState(
                            title:
                                _activeTab ? 'No active posts' : 'No resolved posts',
                            body: _activeTab
                                ? "You haven't posted anything yet."
                                : 'No resolved posts yet.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                            itemCount: list.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _MyPostCard(item: list[i]),
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Segmented tab ─────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppTokens.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1A3C2A0A),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppTokens.ink900 : AppTokens.ink500,
            ),
          ),
        ),
      ),
    );
  }
}

// ── My Post card — mirrors ItemCard with an inline status chip ────────────────

class _MyPostCard extends StatelessWidget {
  const _MyPostCard({required this.item});

  final Item item;

  static const _palette = [
    Color(0xFF795548), Color(0xFF2E7D32), Color(0xFF1565C0),
    Color(0xFF4527A0), Color(0xFF00695C), Color(0xFFC62828),
    Color(0xFF37474F), Color(0xFFE65100),
  ];

  Color get _thumbColor => _palette[item.id.hashCode.abs() % _palette.length];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTokens.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        side: const BorderSide(color: AppTokens.primary400, width: 1.5),
      ),
      child: InkWell(
        onTap: () => ItemDetailRoute(id: item.id).push(context),
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(item: item, color: _thumbColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _CategoryChip(category: item.category),
                        if (item.itemTaxonomy != null)
                          ItemCategoryChip(taxonomy: item.itemTaxonomy!),
                        _StatusChip(status: item.status),
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
                            style: const TextStyle(
                                fontSize: 12, color: AppTokens.ink500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time,
                            size: 13, color: AppTokens.ink500),
                        const SizedBox(width: 2),
                        Text(
                          _relativeTime(item.createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: AppTokens.ink500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item, required this.color});

  final Item item;
  final Color color;

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
          color: color,
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

// ── Chips ─────────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final ItemCategory category;

  @override
  Widget build(BuildContext context) {
    final isFounder = category == ItemCategory.founder;
    return _Chip(
      label: isFounder ? 'Found · Founder' : 'Lost · Seeker',
      bg: isFounder ? AppTokens.successBg : AppTokens.seekerBg,
      fg: isFounder ? AppTokens.success : AppTokens.seeker,
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
      ItemStatus.expired => ('EXPIRED', AppTokens.ink100, AppTokens.ink600),
    };
    return _Chip(label: label, bg: bg, fg: fg);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
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
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppTokens.ink500.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTokens.ink900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(fontSize: 13, color: AppTokens.ink500),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return '${(diff.inDays / 30).floor()}mo ago';
}
