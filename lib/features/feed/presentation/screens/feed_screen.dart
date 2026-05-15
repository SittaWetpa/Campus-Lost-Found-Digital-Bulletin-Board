import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/core/theme/app_tokens.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/item_card.dart';
import 'package:campus_lost_found/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_lost_found/features/post/domain/entities/item_taxonomy.dart';
import 'package:campus_lost_found/shared/widgets/offline_banner.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedItemsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final currentAuthUser = ref.watch(authStateProvider).valueOrNull;
    final filter = ref.watch(feedFilterNotifierProvider);
    final taxonomy = ref.watch(taxonomyFilterNotifierProvider);

    final itemCount = feedAsync.valueOrNull?.length ?? 0;
    final firstName = currentUser?.firstName ?? '';

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OfflineBanner(),
            _Header(
              firstName: firstName,
              itemCount: itemCount,
              taxonomy: taxonomy,
            ),
            const _SearchBar(),
            _FilterRow(current: filter, taxonomy: taxonomy),
            Expanded(
              child: feedAsync.when(
                data: (items) => items.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ItemCard(
                              item: item,
                              isOwner: item.userId == currentAuthUser?.uid,
                              onTap: () =>
                                  ItemDetailRoute(id: item.id).push(context),
                            ),
                          );
                        },
                      ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (_, __) => const Center(
                  child: Text('Failed to load items. Please try again.'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.post),
        backgroundColor: AppTokens.primary500,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NotificationBellButton extends ConsumerWidget {
  const _NotificationBellButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread =
        ref.watch(myUnreadNotificationCountProvider).valueOrNull ?? 0;
    final bell = IconButton(
      icon: const Icon(Icons.notifications_outlined),
      color: AppTokens.ink700,
      onPressed: () => context.push(AppRoutes.notifications),
      tooltip: 'Notifications',
    );
    if (unread == 0) return bell;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        bell,
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: AppTokens.seeker,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTokens.bg, width: 1.5),
            ),
            child: Text(
              unread > 99 ? '99+' : '$unread',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.firstName,
    required this.itemCount,
    required this.taxonomy,
  });

  final String firstName;
  final int itemCount;
  final ItemTaxonomy? taxonomy;

  @override
  Widget build(BuildContext context) {
    final categoryLabel = taxonomy?.displayNameEn.toLowerCase() ?? 'active';
    final plural = itemCount == 1 ? 'post' : 'posts';
    final subtitle = firstName.isNotEmpty
        ? 'Hi $firstName, $itemCount $categoryLabel $plural'
        : '$itemCount $categoryLabel $plural';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bulletin',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTokens.ink900,
                      ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTokens.ink500,
                  ),
                ),
              ],
            ),
          ),
          const _NotificationBellButton(),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted),
            color: AppTokens.ink700,
            onPressed: () => context.push(AppRoutes.myPosts),
            tooltip: 'My Posts',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: AppTokens.ink700,
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: _controller,
        onChanged: (value) =>
            ref.read(searchQueryNotifierProvider.notifier).update(value),
        decoration: InputDecoration(
          hintText: 'Search items, places…',
          hintStyle: const TextStyle(color: AppTokens.ink500, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppTokens.ink500),
          suffixIcon: ValueListenableBuilder(
            valueListenable: _controller,
            builder: (_, value, __) => value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    color: AppTokens.ink500,
                    onPressed: () {
                      _controller.clear();
                      ref
                          .read(searchQueryNotifierProvider.notifier)
                          .update('');
                    },
                  )
                : const SizedBox.shrink(),
          ),
          filled: true,
          fillColor: AppTokens.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTokens.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTokens.primary500),
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.current, required this.taxonomy});

  final FeedFilter current;
  final ItemTaxonomy? taxonomy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _Tab(label: 'All', filter: FeedFilter.all, current: current),
          const SizedBox(width: 6),
          _Tab(label: 'Found', filter: FeedFilter.found, current: current),
          const SizedBox(width: 6),
          _Tab(label: 'Lost', filter: FeedFilter.lost, current: current),
          const Spacer(),
          _CategoryFilterPill(taxonomy: taxonomy),
        ],
      ),
    );
  }
}

class _Tab extends ConsumerWidget {
  const _Tab({
    required this.label,
    required this.filter,
    required this.current,
  });

  final String label;
  final FeedFilter filter;
  final FeedFilter current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = filter == current;
    return GestureDetector(
      onTap: () =>
          ref.read(feedFilterNotifierProvider.notifier).select(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTokens.primary500 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.pill),
          border: Border.all(
            color: selected ? AppTokens.primary500 : AppTokens.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTokens.ink700,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterPill extends ConsumerWidget {
  const _CategoryFilterPill({required this.taxonomy});

  final ItemTaxonomy? taxonomy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFilter = taxonomy != null;
    final pillColor = hasFilter ? AppTokens.ink800 : Colors.transparent;
    final borderColor = hasFilter ? AppTokens.ink800 : AppTokens.border;
    final fgColor = hasFilter ? Colors.white : AppTokens.ink700;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(AppTokens.pill),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.horizontal(
                left: const Radius.circular(AppTokens.pill),
                right: hasFilter ? Radius.zero : const Radius.circular(AppTokens.pill),
              ),
              onTap: () => _showCategoryPicker(context, taxonomy),
              child: Padding(
                padding: EdgeInsets.fromLTRB(11, 6, hasFilter ? 6 : 8, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasFilter) ...[
                      Icon(taxonomy!.iconData, size: 13, color: fgColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      hasFilter ? taxonomy!.displayNameEn : 'Category',
                      style: TextStyle(
                        color: fgColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    if (!hasFilter) ...[
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: AppTokens.ink600,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (hasFilter)
              InkWell(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(AppTokens.pill),
                ),
                onTap: () =>
                    ref.read(taxonomyFilterNotifierProvider.notifier).clear(),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(4, 6, 9, 6),
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryPicker(
    BuildContext context,
    ItemTaxonomy? current,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _CategoryPickerSheet(current: current),
    );
  }
}

class _CategoryPickerSheet extends ConsumerWidget {
  const _CategoryPickerSheet({required this.current});

  final ItemTaxonomy? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Filter by category',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        color: AppTokens.ink900,
                      ),
                ),
                const Spacer(),
                if (current != null)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTokens.seeker,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      ref
                          .read(taxonomyFilterNotifierProvider.notifier)
                          .clear();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.4,
              children: ItemTaxonomy.values.map((cat) {
                final selected = cat == current;
                return InkWell(
                  borderRadius: BorderRadius.circular(AppTokens.rSm),
                  onTap: () {
                    ref
                        .read(taxonomyFilterNotifierProvider.notifier)
                        .select(cat);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTokens.primary100
                          : AppTokens.surface,
                      border: Border.all(
                        color:
                            selected ? AppTokens.primary500 : AppTokens.border,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.rSm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          cat.iconData,
                          size: 16,
                          color: selected
                              ? AppTokens.primary600
                              : AppTokens.ink700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat.displayNameEn,
                            style: TextStyle(
                              color: selected
                                  ? AppTokens.primary600
                                  : AppTokens.ink700,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppTokens.ink500),
          const SizedBox(height: 16),
          const Text(
            'No items found',
            style: TextStyle(
              fontSize: 16,
              color: AppTokens.ink700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Be the first to post a lost or found item.',
            style: TextStyle(fontSize: 13, color: AppTokens.ink500),
          ),
        ],
      ),
    );
  }
}
