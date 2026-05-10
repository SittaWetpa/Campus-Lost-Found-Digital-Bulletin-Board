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

  /// Active, non-sensitive Founder Posts in [categoryId] — Similar Posts panel,
  /// max [limit] results ordered by createdAt desc (WBS 2.8).
  Future<List<Item>> getRecentInCategory({
    required String categoryId,
    int limit = 5,
  });

  /// Stream of all items owned by userId — My Posts Screen (WBS 1.7).
  Stream<List<Item>> watchMyItems(String userId);

  /// Fetches the secret answer from the restricted private sub-document
  /// `items/{itemId}/private/answer`. Readable by the poster only (enforced
  /// by Firestore rules). Returns null when no answer has been stored yet.
  Future<String?> getItemSecretAnswer(String itemId);
}
