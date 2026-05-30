import 'package:campus_lost_found/core/constants/app_constants.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

/// R5(d) — startAfter-based "load more" paging, segregated from the live
/// streaming [ItemRepository] so existing consumers/fakes are unaffected.
abstract interface class ItemPageRepository {
  /// Next page of active feed items older than [startAfterCreatedAt]
  /// (null fetches the first page), ordered by createdAt descending.
  Future<List<Item>> fetchFeedPage({
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  });

  /// Next page of [userId]'s items older than [startAfterCreatedAt].
  Future<List<Item>> fetchMyItemsPage({
    required String userId,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  });
}
