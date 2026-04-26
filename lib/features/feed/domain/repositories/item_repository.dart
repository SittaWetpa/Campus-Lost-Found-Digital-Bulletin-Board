import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

abstract interface class ItemRepository {
  /// Real-time stream of Active items for the main feed.
  Stream<List<Item>> watchFeed();

  /// Real-time stream of a single item for the Detail Screen.
  Stream<Item?> watchItem(String itemId);

  /// One-shot fetch for deep-link resolution.
  Future<Item?> getItemById(String itemId);

  /// Prefix-range keyword search on title, Active items only (WBS 2.3).
  Future<List<Item>> searchItems(String keyword);

  /// Active Founder Posts matching keyword — Similar Posts panel, max 3 (WBS 2.8).
  Future<List<Item>> getSimilarFounderPosts(String keyword);

  /// Stream of all items owned by userId — My Posts Screen (WBS 1.7).
  Stream<List<Item>> watchMyItems(String userId);
}
