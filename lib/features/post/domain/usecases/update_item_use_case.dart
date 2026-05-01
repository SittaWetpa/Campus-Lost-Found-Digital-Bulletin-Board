import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';

/// WBS 2.6 — edit an existing post.
///
/// Data layer is responsible for setting `editedAt` via serverTimestamp.
class UpdateItemUseCase {
  final PostRepository _repository;
  const UpdateItemUseCase(this._repository);

  Future<void> call(Item item) => _repository.updateItem(item);
}
