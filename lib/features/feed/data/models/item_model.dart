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
  final DateTime occurredAt;
  final DateTime? editedAt;
  final DateTime? expiresAt;
  final String? claimedBy;
  final String? secretQuestion;
  final String? secretAnswer;
  final String? posterName;
  final String? posterAvatarUrl;
  // WBS 2.8 — taxonomy bucket stored as the enum's id string
  final String? itemCategory;

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
    required this.occurredAt,
    this.source = 'web',
    this.isSensitive = false,
    this.editedAt,
    this.expiresAt,
    this.claimedBy,
    this.secretQuestion,
    this.secretAnswer,
    this.posterName,
    this.posterAvatarUrl,
    this.itemCategory,
  });

  factory ItemModel.fromMap(String id, Map<String, dynamic> data) => ItemModel(
        id: id,
        title: data['title'] as String,
        // description / contact / location are conceptually required but a
        // single bad doc with null in any of them used to throw a TypeError
        // and break the whole feed stream. Default to '' so the rest of the
        // feed keeps rendering; the post form is responsible for never
        // writing null in the first place.
        description: data['description'] as String? ?? '',
        category: data['category'] as String,
        status: data['status'] as String,
        location: data['location'] as String? ?? '',
        contact: data['contact'] as String? ?? '',
        imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
        userId: data['userId'] as String,
        source: data['source'] as String? ?? 'web',
        isSensitive: data['isSensitive'] as bool? ?? false,
        // serverTimestamp is null during the pending-write window; fall back to now
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        // user-supplied; never null on a well-formed doc — let it throw if missing
        occurredAt: (data['occurredAt'] as Timestamp).toDate(),
        editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
        expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
        claimedBy: data['claimedBy'] as String?,
        secretQuestion: data['secretQuestion'] as String?,
        secretAnswer: data['secretAnswer'] as String?,
        posterName: data['posterName'] as String?,
        posterAvatarUrl: data['posterAvatarUrl'] as String?,
        itemCategory: data['itemCategory'] as String?,
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
        occurredAt: item.occurredAt,
        editedAt: item.editedAt,
        expiresAt: item.expiresAt,
        claimedBy: item.claimedBy,
        secretQuestion: item.secretQuestion,
        secretAnswer: item.secretAnswer,
        posterName: item.posterName,
        posterAvatarUrl: item.posterAvatarUrl,
        itemCategory: item.itemTaxonomy?.id,
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
        'source': source,
        'isSensitive': isSensitive,
        'occurredAt': Timestamp.fromDate(occurredAt),
        // WBS 2.8 — always write itemCategory; fall back to 'other' for legacy
        'itemCategory': itemCategory ?? 'other',
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
        if (claimedBy != null) 'claimedBy': claimedBy,
        if (secretQuestion != null) 'secretQuestion': secretQuestion,
        // secretAnswer is intentionally excluded — it is written to
        // items/{id}/private/answer (poster-only sub-document) by the
        // datasource, never to the main item document.
        if (posterName != null) 'posterName': posterName,
        if (posterAvatarUrl != null) 'posterAvatarUrl': posterAvatarUrl,
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
        occurredAt: occurredAt,
        editedAt: editedAt,
        expiresAt: expiresAt,
        claimedBy: claimedBy,
        secretQuestion: secretQuestion,
        secretAnswer: secretAnswer,
        posterName: posterName,
        posterAvatarUrl: posterAvatarUrl,
        // Lazy backfill: items written before WBS 2.8 have no itemCategory.
        // Default to 'other' so the entity is always non-null after a read.
        itemTaxonomy: ItemTaxonomy.fromId(itemCategory ?? 'other'),
      );

  Map<String, dynamic> toHiveMap() => {
        'id': id,
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
        'createdAt': createdAt.toIso8601String(),
        'occurredAt': occurredAt.toIso8601String(),
        'editedAt': editedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'claimedBy': claimedBy,
        'secretQuestion': secretQuestion,
        'secretAnswer': secretAnswer,
        'posterName': posterName,
        'posterAvatarUrl': posterAvatarUrl,
      };

  factory ItemModel.fromHiveMap(Map map) => ItemModel(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        category: map['category'] as String,
        status: map['status'] as String,
        location: map['location'] as String? ?? '',
        contact: map['contact'] as String? ?? '',
        imageUrls: List<String>.from(map['imageUrls'] as List? ?? []),
        userId: map['userId'] as String,
        source: map['source'] as String? ?? 'web',
        isSensitive: map['isSensitive'] as bool? ?? false,
        createdAt: DateTime.parse(map['createdAt'] as String),
        occurredAt: DateTime.parse(map['occurredAt'] as String),
        editedAt: map['editedAt'] == null
            ? null
            : DateTime.parse(map['editedAt'] as String),
        expiresAt: map['expiresAt'] == null
            ? null
            : DateTime.parse(map['expiresAt'] as String),
        claimedBy: map['claimedBy'] as String?,
        secretQuestion: map['secretQuestion'] as String?,
        secretAnswer: map['secretAnswer'] as String?,
        posterName: map['posterName'] as String?,
        posterAvatarUrl: map['posterAvatarUrl'] as String?,
      );
}
