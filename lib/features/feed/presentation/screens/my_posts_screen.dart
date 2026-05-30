import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/core/theme/app_tokens.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_pagination_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/item_card.dart';

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
    final pagination = uid.isNotEmpty
        ? ref.watch(myItemsPaginationProvider(uid))
        : const PagedItems();

    // Merge the live first page with any startAfter-loaded older pages (R5(d)).
    final all = mergeFeedPages(itemsAsync.valueOrNull ?? const [], pagination.items);
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
                Expanded(
                  child: itemsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Failed to load your posts.')),
                    data: (_) => list.isEmpty
                        ? _EmptyState(
                            title: _activeTab
                                ? 'No active posts'
                                : 'No resolved posts',
                            body: _activeTab
                                ? "You haven't posted anything yet."
                                : 'No resolved posts yet.',
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (uid.isNotEmpty &&
                                  list.isNotEmpty &&
                                  notification.metrics.pixels >=
                                      notification.metrics.maxScrollExtent -
                                          300 &&
                                  !pagination.isLoadingMore &&
                                  !pagination.reachedEnd) {
                                ref
                                    .read(myItemsPaginationProvider(uid)
                                        .notifier)
                                    .loadMore(list.last.createdAt);
                              }
                              return false;
                            },
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 80),
                              itemCount: list.length +
                                  (pagination.isLoadingMore ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (i >= list.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ItemCard(
                                    item: list[i],
                                    isOwner: true,
                                    showStatus: true,
                                    onTap: () => ItemDetailRoute(id: list[i].id)
                                        .push(context),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

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
      child: Semantics(
        label: '$label ($count)',
        button: true,
        selected: selected,
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
      ),
    );
  }
}

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
