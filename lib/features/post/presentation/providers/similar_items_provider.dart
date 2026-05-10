import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/post/domain/entities/item_taxonomy.dart';

part 'similar_items_provider.g.dart';

@riverpod
class SimilarItemsNotifier extends _$SimilarItemsNotifier {
  @override
  AsyncValue<List<Item>> build() => const AsyncData([]);

  Future<void> load(ItemTaxonomy taxonomy) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(itemRepositoryProvider)
          .getRecentInCategory(categoryId: taxonomy.id),
    );
  }

  void clear() => state = const AsyncData([]);
}
