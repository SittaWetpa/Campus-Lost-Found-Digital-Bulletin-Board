import 'package:campus_lost_found/features/feed/domain/entities/api_item_listing.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

abstract interface class ExternalApiRepository {
  Future<List<ApiItemListing>> fetchItems({
    ItemCategory? category,
    String? keyword,
    int limit = 20,
  });
}
