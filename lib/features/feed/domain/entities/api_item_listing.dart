import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

class ApiItemListing {
  const ApiItemListing({
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
  final ItemCategory category;
  final ItemStatus status;
  final String description;
  final String location;
  final String contact;
  final List<String> imageUrls;
  final bool isSensitive;
  final DateTime createdAt;
  final DateTime occurredAt;
  final DateTime? expiresAt;
  final String? itemCategory;

  ApiItemListing copyWith({
    String? id,
    String? title,
    ItemCategory? category,
    ItemStatus? status,
    String? description,
    String? location,
    String? contact,
    List<String>? imageUrls,
    bool? isSensitive,
    DateTime? createdAt,
    DateTime? occurredAt,
    DateTime? expiresAt,
    String? itemCategory,
  }) =>
      ApiItemListing(
        id: id ?? this.id,
        title: title ?? this.title,
        category: category ?? this.category,
        status: status ?? this.status,
        description: description ?? this.description,
        location: location ?? this.location,
        contact: contact ?? this.contact,
        imageUrls: imageUrls ?? this.imageUrls,
        isSensitive: isSensitive ?? this.isSensitive,
        createdAt: createdAt ?? this.createdAt,
        occurredAt: occurredAt ?? this.occurredAt,
        expiresAt: expiresAt ?? this.expiresAt,
        itemCategory: itemCategory ?? this.itemCategory,
      );
}
