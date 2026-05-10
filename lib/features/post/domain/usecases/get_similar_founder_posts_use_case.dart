import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';

class GetSimilarFounderPostsUseCase {
  final ItemRepository _repository;
  const GetSimilarFounderPostsUseCase(this._repository);

  /// Returns up to 3 active Founder Posts whose title matches [keyword].
  /// The caller (PostFormScreen) enforces the ≥3-char / 500 ms debounce guard.
  Future<List<Item>> call(String keyword) =>
      _repository.getSimilarFounderPosts(keyword);
}
