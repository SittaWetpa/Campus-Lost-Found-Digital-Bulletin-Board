import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:campus_lost_found/features/post/presentation/providers/post_provider.dart';

part 'delete_post_notifier.g.dart';

@riverpod
class DeletePostNotifier extends _$DeletePostNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Returns true if the item has pending requests that block deletion.
  Future<bool> hasPendingRequests(String itemId) {
    return ref.read(postRepositoryProvider).hasPendingRequests(itemId);
  }

  /// Deletes the item document. Navigate away after state becomes AsyncData.
  Future<void> delete(String itemId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(postRepositoryProvider).deleteItem(itemId),
    );
  }
}
