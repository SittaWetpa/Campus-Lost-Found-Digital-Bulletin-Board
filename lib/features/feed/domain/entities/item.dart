enum ItemCategory {
  seeker,
  founder;

  static ItemCategory fromString(String value) => switch (value) {
        'seeker' => ItemCategory.seeker,
        'founder' => ItemCategory.founder,
        _ => throw ArgumentError('Unknown ItemCategory: $value'),
      };
}

enum ItemStatus {
  active,
  resolved;

  static ItemStatus fromString(String value) => switch (value) {
        'active' => ItemStatus.active,
        'resolved' => ItemStatus.resolved,
        _ => throw ArgumentError('Unknown ItemStatus: $value'),
      };
}

// WBS 2.15 — walk-in QR registration source
enum ItemSource {
  web,
  qrWalkIn;

  static ItemSource fromString(String value) => switch (value) {
        'qr_walk_in' => ItemSource.qrWalkIn,
        _ => ItemSource.web,
      };
}

class Item {
  final String id;
  final String title;

  // Null when isSensitive == true (hidden from public view)
  final String? description;

  final ItemCategory category;
  final ItemStatus status;
  final String location;

  // Null when isSensitive == true (hidden from public view)
  final String? contact;

  final List<String> imageUrls;
  final String userId;

  // WBS 2.15 — walk-in QR registration badge on ItemCard
  final ItemSource source;

  // WBS 2.14 — hides description & contact; directs seekers to Security Office
  final bool isSensitive;

  final DateTime createdAt;

  // When the item was lost (seeker) or found (founder) — drives the datetime picker
  final DateTime occurredAt;

  // WBS 2.6 — null until post has been edited
  final DateTime? editedAt;

  // Sensitive Founder Posts auto-expire after 14 days; null for all other posts
  final DateTime? expiresAt;

  // WBS 2.4 — null until a request is approved
  final String? claimedBy;

  // WBS 2.10 — only on Founder Posts with a secret question
  final String? secretQuestion;
  final String? secretAnswer;

  const Item({
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
    this.source = ItemSource.web,
    this.isSensitive = false,
    this.editedAt,
    this.expiresAt,
    this.claimedBy,
    this.secretQuestion,
    this.secretAnswer,
  });

  Item copyWith({
    String? id,
    String? title,
    String? description,
    ItemCategory? category,
    ItemStatus? status,
    String? location,
    String? contact,
    List<String>? imageUrls,
    String? userId,
    ItemSource? source,
    bool? isSensitive,
    DateTime? createdAt,
    DateTime? occurredAt,
    DateTime? editedAt,
    DateTime? expiresAt,
    String? claimedBy,
    String? secretQuestion,
    String? secretAnswer,
  }) => Item(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        status: status ?? this.status,
        location: location ?? this.location,
        contact: contact ?? this.contact,
        imageUrls: imageUrls ?? this.imageUrls,
        userId: userId ?? this.userId,
        source: source ?? this.source,
        isSensitive: isSensitive ?? this.isSensitive,
        createdAt: createdAt ?? this.createdAt,
        occurredAt: occurredAt ?? this.occurredAt,
        editedAt: editedAt ?? this.editedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        claimedBy: claimedBy ?? this.claimedBy,
        secretQuestion: secretQuestion ?? this.secretQuestion,
        secretAnswer: secretAnswer ?? this.secretAnswer,
      );
}
