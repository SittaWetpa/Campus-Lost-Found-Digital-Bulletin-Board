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
  final DateTime createdAt;
  final DateTime? occurredAt;
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
    required this.createdAt,
    this.occurredAt,
    this.editedAt,
    this.claimedBy,
    this.secretQuestion,
    this.secretAnswer,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      category: data['category'] as String,
      status: data['status'] as String,
      location: data['location'] as String,
      contact: data['contact'] as String,
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
      userId: data['userId'] as String,
      // serverTimestamp is null during the pending-write window; fall back to now
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      occurredAt: (data['occurredAt'] as Timestamp?)?.toDate(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      claimedBy: data['claimedBy'] as String?,
      secretQuestion: data['secretQuestion'] as String?,
      secretAnswer: data['secretAnswer'] as String?,
    );
  }

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
        createdAt: item.createdAt,
        occurredAt: item.occurredAt,
        editedAt: item.editedAt,
        claimedBy: item.claimedBy,
        secretQuestion: item.secretQuestion,
        secretAnswer: item.secretAnswer,
      );

  /// Returns the mutable fields to write to Firestore.
  /// createdAt and editedAt are excluded — the datasource sets them
  /// via FieldValue.serverTimestamp() to guarantee server-side timestamps.
  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'category': category,
        'status': status,
        'location': location,
        'contact': contact,
        'imageUrls': imageUrls,
        'userId': userId,
        if (occurredAt != null) 'occurredAt': Timestamp.fromDate(occurredAt!),
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
        createdAt: createdAt,
        occurredAt: occurredAt,
        editedAt: editedAt,
        claimedBy: claimedBy,
        secretQuestion: secretQuestion,
        secretAnswer: secretAnswer,
      );
}
