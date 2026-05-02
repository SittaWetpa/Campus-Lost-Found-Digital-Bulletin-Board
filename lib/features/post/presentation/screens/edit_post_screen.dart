import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/post/presentation/providers/edit_post_notifier.dart';
import 'package:campus_lost_found/features/post/presentation/widgets/post_form_widget.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  final String itemId;
  const EditPostScreen({super.key, required this.itemId});

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  // Stores the item snapshot used to pre-populate the form.
  // Cached so Firestore stream updates don't reset the form mid-edit.
  Item? _original;

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(watchItemProvider(widget.itemId));

    itemAsync.whenData((item) {
      if (item != null && _original == null) {
        _original = item;
      }
    });

    final saveState = ref.watch(editPostNotifierProvider);

    ref.listen<AsyncValue<void>>(editPostNotifierProvider, (prev, next) {
      if (next is AsyncError) {
        final message = next.error is Failure
            ? (next.error as Failure).message
            : 'Failed to update post.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else if (prev is AsyncLoading && next is AsyncData) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Post updated.')));
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Post')),
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Post not found.'));
          }
          final original = _original ?? item;
          return PostFormWidget(
            initialItem: original,
            isSaving: saveState is AsyncLoading,
            onSave: (formData) => ref
                .read(editPostNotifierProvider.notifier)
                .save(original: original, formData: formData),
          );
        },
      ),
    );
  }
}
