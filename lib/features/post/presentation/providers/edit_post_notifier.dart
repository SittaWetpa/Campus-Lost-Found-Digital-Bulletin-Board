import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:campus_lost_found/core/services/storage_service.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/post/presentation/providers/post_provider.dart';
import 'package:campus_lost_found/features/post/presentation/widgets/post_form_widget.dart';

part 'edit_post_notifier.g.dart';

@riverpod
class EditPostNotifier extends _$EditPostNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> save({
    required Item original,
    required ItemFormData formData,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final storage = ref.read(storageServiceProvider);

      // 1. Delete removed images from Storage.
      for (final url in formData.removedImageUrls) {
        await storage.deleteImageByUrl(url);
      }

      // 2. Upload new images and collect their download URLs.
      final newUrls = <String>[];
      for (final file in formData.newImageFiles) {
        final url =
            await storage.uploadImage(file, 'items/${original.id}');
        newUrls.add(url);
      }

      // 3. Build the updated entity (editedAt is set server-side by datasource).
      final updated = Item(
        id: original.id,
        userId: original.userId,
        createdAt: original.createdAt,
        status: original.status,
        claimedBy: original.claimedBy,
        secretQuestion: original.secretQuestion,
        secretAnswer: original.secretAnswer,
        title: formData.title,
        description: formData.description,
        category: formData.category,
        location: formData.location,
        occurredAt: formData.occurredAt ?? original.occurredAt,
        contact: formData.contact,
        imageUrls: [...formData.keptImageUrls, ...newUrls],
      );

      // 4. Persist via repository (datasource stamps editedAt via serverTimestamp).
      await ref.read(postRepositoryProvider).updateItem(updated);
    });
  }
}
