import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(watchItemProvider(itemId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return itemAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading…')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (item) {
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Post not found.')),
          );
        }

        final isOwner = currentUser?.uid == item.userId;
        final editedAt = item.editedAt;

        return Scaffold(
          appBar: AppBar(
            title: Text(item.title),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit post',
                  onPressed: () =>
                      EditPostRoute(id: item.id).push<void>(context),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Category badge
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(
                    item.category.name == 'seeker'
                        ? 'Seeker Post'
                        : 'Founder Post',
                  ),
                ),
              ),
              // Edited timestamp — only shown when editedAt is present
              if (editedAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.edit, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Edited · ${_relativeTime(editedAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              // TODO(WBS 1.3): full item details — description, location,
              // images, contact, and request/claim button.
            ],
          ),
        );
      },
    );
  }
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
