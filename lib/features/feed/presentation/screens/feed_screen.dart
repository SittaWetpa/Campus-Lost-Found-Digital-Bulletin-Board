import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/item_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedItemsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final currentAuthUser = ref.watch(authStateProvider).valueOrNull;
    final filter = ref.watch(feedFilterNotifierProvider);

    final itemCount = feedAsync.valueOrNull?.length ?? 0;
    final firstName = currentUser?.firstName ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(firstName: firstName, itemCount: itemCount),
            _SearchBar(),
            _FilterTabs(current: filter),
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
                            padding: const EdgeInsets.only(bottom: 8),
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
        backgroundColor: const Color(0xFFCA8A04),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.firstName, required this.itemCount});

  final String firstName;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final subtitle = firstName.isNotEmpty
        ? 'Hi $firstName, $itemCount active posts'
        : '$itemCount active posts';

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
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted),
            onPressed: () => context.push(AppRoutes.myPosts),
            tooltip: 'My Posts',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        readOnly: true,
        onTap: () {},
        decoration: InputDecoration(
          hintText: 'Search items, places...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _FilterTabs extends ConsumerWidget {
  const _FilterTabs({required this.current});

  final FeedFilter current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _Tab(
            label: 'All',
            filter: FeedFilter.all,
            current: current,
          ),
          const SizedBox(width: 8),
          _Tab(
            label: 'Found',
            filter: FeedFilter.found,
            current: current,
          ),
          const SizedBox(width: 8),
          _Tab(
            label: 'Lost',
            filter: FeedFilter.lost,
            current: current,
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFCA8A04) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
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
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to post a lost or found item.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
