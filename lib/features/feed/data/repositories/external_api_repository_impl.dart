import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/feed/data/datasources/http_item_datasource.dart';
import 'package:campus_lost_found/features/feed/domain/entities/api_item_listing.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/external_api_repository.dart';

class ExternalApiRepositoryImpl implements ExternalApiRepository {
  const ExternalApiRepositoryImpl(this._datasource);

  final HttpItemDatasource _datasource;

  @override
  Future<List<ApiItemListing>> fetchItems({
    ItemCategory? category,
    String? keyword,
    int limit = 20,
  }) async {
    try {
      final models = await _datasource.fetchItems(
        category: category?.name,
        keyword: keyword,
        limit: limit,
      );
      return models.map((m) => m.toEntity()).toList();
    } on ApiException catch (e) {
      throw ServerFailure(e.message);
    } catch (_) {
      throw const ServerFailure('Failed to fetch items from external API.');
    }
  }
}
