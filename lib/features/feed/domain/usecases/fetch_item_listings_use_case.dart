import 'package:campus_lost_found/features/feed/domain/entities/api_item_listing.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/external_api_repository.dart';

class FetchItemListingsUseCase {
  const FetchItemListingsUseCase(this._repository);

  final ExternalApiRepository _repository;

  Future<List<ApiItemListing>> call({
    ItemCategory? category,
    String? keyword,
    int limit = 20,
  }) =>
      _repository.fetchItems(category: category, keyword: keyword, limit: limit);
}
