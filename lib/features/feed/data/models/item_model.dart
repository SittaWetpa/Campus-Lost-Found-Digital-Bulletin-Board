import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String location;
  final String contact;
  final List<String> imageUrls;
  final String userId;
  final String source;
  final bool isSensitive;
  final DateTime createdAt;
  final DateTime? editedAt;
  final String? claimedBy;
  final String? secretQuestion;
  final String? secretAnswer;

  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.location,
    required this.contact,
    required this.imageUrls,
    required this.userId,
    this.source = 'web',
    this.isSensitive = false,
    required this.createdAt,
    this.editedAt,
    this.claimedBy,
    this.secretQuestion,
    this.secretAnswer,
  });

  factory ItemModel.fromMap(String id, Map<String, dynamic> data) => ItemModel(
        id: id,
        title: data['title'] as String,
        description: data['description'] as String,
        category: data['category'] as String,
        status: data['status'] as String,
        location: data['location'] as String,
        contact: data['contact'] as String,
        imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
        userId: data['userId'] as String,
        source: data['source'] as String? ?? 'web',
        isSensitive: data['isSensitive'] as bool? ?? false,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
        claimedBy: data['claimedBy'] as String?,
        secretQuestion: data['secretQuestion'] as String?,
        secretAnswer: data['secretAnswer'] as String?,
      );

  factory ItemModel.fromFirestore(DocumentSnapshot doc) =>
      ItemModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);

  factory ItemModel.fromEntity(Item item) => ItemModel(
        id: item.id,
        title: item.title,
        description: item.description,
        category: item.category.name,
        status: item.status.name,
        location: item.location,
        contact: item.contact,
        imageUrls: item.imageUrls,
        userId: item.userId,
        source: item.source == ItemSource.qrWalkIn ? 'qr_walk_in' : 'web',
        isSensitive: item.isSensitive,
        createdAt: item.createdAt,
        editedAt: item.editedAt,
        claimedBy: item.claimedBy,
        secretQuestion: item.secretQuestion,
        secretAnswer: item.secretAnswer,
      );

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'category': category,
        'status': status,
        'location': location,
        'contact': contact,
        'imageUrls': imageUrls,
        'userId': userId,
        'source': source,
        'isSensitive': isSensitive,
        'createdAt': Timestamp.fromDate(createdAt),
        if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
        if (claimedBy != null) 'claimedBy': claimedBy,
        if (secretQuestion != null) 'secretQuestion': secretQuestion,
        if (secretAnswer != null) 'secretAnswer': secretAnswer,
      };

  Item toEntity() => Item(
        id: id,
        title: title,
        description: description,
        category: ItemCategory.fromString(category),
        status: ItemStatus.fromString(status),
        location: location,
        contact: contact,
        imageUrls: imageUrls,
        userId: userId,
        source: ItemSource.fromString(source),
        isSensitive: isSensitive,
        createdAt: createdAt,
        editedAt: editedAt,
        claimedBy: claimedBy,
        secretQuestion: secretQuestion,
        secretAnswer: secretAnswer,
      );
}
