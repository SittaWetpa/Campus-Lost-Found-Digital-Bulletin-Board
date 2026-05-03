import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/post/presentation/providers/delete_post_notifier.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(watchItemProvider(itemId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final deleteState = ref.watch(deletePostNotifierProvider);

    ref.listen<AsyncValue<void>>(deletePostNotifierProvider, (prev, next) {
      if (next is AsyncError) {
        final message = next.error is Failure
            ? (next.error as Failure).message
            : 'Failed to delete post.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else if (prev is AsyncLoading && next is AsyncData) {
        context.go(AppRoutes.feed);
      }
    });

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
        final isDeleting = deleteState is AsyncLoading;
        final editedAt = item.editedAt;

        return Scaffold(
          appBar: AppBar(
            title: Text(item.title),
            actions: [
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit post',
                  onPressed: isDeleting
                      ? null
                      : () => EditPostRoute(id: item.id).push<void>(context),
                ),
                IconButton(
                  icon: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  tooltip: 'Delete post',
                  onPressed: isDeleting
                      ? null
                      : () => _onDeleteTapped(context, ref, item.id),
                ),
              ],
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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

Future<void> _onDeleteTapped(
    BuildContext context, WidgetRef ref, String itemId) async {
  final notifier = ref.read(deletePostNotifierProvider.notifier);
  final hasPending = await notifier.hasPendingRequests(itemId);
  if (!context.mounted) return;

  if (hasPending) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cannot delete'),
        content: const Text(
            'Resolve all pending requests before deleting this post.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.myPosts);
            },
            child: const Text('View requests'),
          ),
        ],
      ),
    );
  } else {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await notifier.delete(itemId);
    }
  }
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
