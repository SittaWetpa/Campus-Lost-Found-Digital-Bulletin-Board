import 'package:campus_lost_found/features/feed/domain/entities/api_item_listing.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

class ApiItemListingModel {
  const ApiItemListingModel({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.description,
    required this.location,
    required this.contact,
    required this.imageUrls,
    required this.isSensitive,
    required this.createdAt,
    required this.occurredAt,
    this.expiresAt,
    this.itemCategory,
  });

  final String id;
  final String title;
  final String category;
  final String status;
  final String description;
  final String location;
  final String contact;
  final List<String> imageUrls;
  final bool isSensitive;
  final DateTime createdAt;
  final DateTime occurredAt;
  final DateTime? expiresAt;
  final String? itemCategory;

  factory ApiItemListingModel.fromJson(Map<String, dynamic> json) {
    final rawOccurredAt = json['occurredAt'] as String?;
    final rawCreatedAt = json['createdAt'] as String;
    return ApiItemListingModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isSensitive: json['isSensitive'] as bool? ?? false,
      createdAt: DateTime.parse(rawCreatedAt),
      // Fall back to createdAt for items predating WBS 2.2
      occurredAt: rawOccurredAt != null
          ? DateTime.parse(rawOccurredAt)
          : DateTime.parse(rawCreatedAt),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      itemCategory: json['itemCategory'] as String?,
    );
  }

  ApiItemListing toEntity() => ApiItemListing(
        id: id,
        title: title,
        category: ItemCategory.fromString(category),
        status: ItemStatus.fromString(status),
        description: description,
        location: location,
        contact: contact,
        imageUrls: imageUrls,
        isSensitive: isSensitive,
        createdAt: createdAt,
        occurredAt: occurredAt,
        expiresAt: expiresAt,
        itemCategory: itemCategory,
      );
}
