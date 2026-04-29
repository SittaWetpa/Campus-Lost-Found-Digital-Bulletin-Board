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
  final String description;
  final ItemCategory category;
  final ItemStatus status;
  final String location;
  final String contact;
  final List<String> imageUrls;
  final String userId;

  // WBS 2.15 — walk-in QR registration badge on ItemCard
  final ItemSource source;

  // Future WBS — hides photo & description; shows "Contact Security Office"
  final bool isSensitive;

  final DateTime createdAt;

  // WBS 2.6 — null until post has been edited
  final DateTime? editedAt;

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
    this.source = ItemSource.web,
    this.isSensitive = false,
    this.editedAt,
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
    DateTime? editedAt,
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
        editedAt: editedAt ?? this.editedAt,
        claimedBy: claimedBy ?? this.claimedBy,
        secretQuestion: secretQuestion ?? this.secretQuestion,
        secretAnswer: secretAnswer ?? this.secretAnswer,
      );
}
