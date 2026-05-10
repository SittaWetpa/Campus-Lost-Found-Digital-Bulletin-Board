import 'dart:convert';

import 'package:campus_lost_found/features/feed/data/models/api_item_listing_model.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

abstract interface class HttpItemDatasource {
  Future<List<ApiItemListingModel>> fetchItems({
    String? category,
    String? keyword,
    int limit = 20,
  });
}

class HttpItemDatasourceImpl implements HttpItemDatasource {
  HttpItemDatasourceImpl({
    required this.baseUrl,
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String apiKey;
  final http.Client _client;

  @override
  Future<List<ApiItemListingModel>> fetchItems({
    String? category,
    String? keyword,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      if (category != null) 'category': category,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final response = await _client.get(
      uri,
      headers: {'x-api-key': apiKey},
    );

    if (response.statusCode == 401) {
      throw const ApiException('Unauthorized — invalid or missing API key.', statusCode: 401);
    }
    if (response.statusCode == 400) {
      throw const ApiException('Bad request — invalid query parameters.', statusCode: 400);
    }
    if (response.statusCode != 200) {
      throw ApiException(
        'Unexpected server error (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final body = json.decode(response.body) as List<dynamic>;
    return body
        .map((e) => ApiItemListingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
