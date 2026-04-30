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
    this.editedAt,
    this.claimedBy,
    this.secretQuestion,
    this.secretAnswer,
  });
}
