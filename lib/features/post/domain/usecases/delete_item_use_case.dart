import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';

/// WBS 2.7 — delete a post.
///
/// Caller (Detail Screen) must verify no pending requests exist first.
class DeleteItemUseCase {
  final PostRepository _repository;
  const DeleteItemUseCase(this._repository);

  Future<void> call(String itemId) => _repository.deleteItem(itemId);
}
