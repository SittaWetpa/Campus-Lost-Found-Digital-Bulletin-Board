import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

abstract interface class PostRepository {
  /// Creates item; item.id is ignored — Firestore auto-generates the ID.
  /// Returns the created Item with its server-assigned ID.
  Future<Item> createItem(Item item);

  /// Updates mutable fields. Data layer sets editedAt via serverTimestamp (WBS 2.6).
  Future<void> updateItem(Item item);

  /// Deletes item. Caller must verify no pending requests exist first (WBS 2.7).
  Future<void> deleteItem(String itemId);
}
