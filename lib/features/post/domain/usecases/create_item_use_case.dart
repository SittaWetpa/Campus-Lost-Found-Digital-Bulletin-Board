import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';

class CreateItemUseCase {
  final PostRepository _repository;
  const CreateItemUseCase(this._repository);

  /// Caller passes an [Item] with [Item.id] set to '' — the repository
  /// ignores it and returns the Item with its Firestore-assigned ID.
  Future<Item> call(Item item) => _repository.createItem(item);
}
