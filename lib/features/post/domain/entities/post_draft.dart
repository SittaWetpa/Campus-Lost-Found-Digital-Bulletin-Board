import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

/// Working state of the Post Form. Distinct from [Item] (the persisted entity)
/// because it carries UI-only flags (e.g. [useMyNumber]) and unsanitized text.
///
/// Pipeline: PostDraft -> validate() -> toItem() -> PostRepository.createItem
class PostDraft {
  final ItemCategory category;
  final bool isSensitive;
  final String title;
  final String description;
  final String location;
  final DateTime occurredAt;
  final String contact;
  final bool useMyNumber;
  final List<String> imageUrls;
  final String secretQuestion;
  final String secretAnswer;

  const PostDraft({
    required this.category,
    required this.title,
    required this.location,
    required this.occurredAt,
    this.isSensitive = false,
    this.description = '',
    this.contact = '',
    this.useMyNumber = true,
    this.imageUrls = const [],
    this.secretQuestion = '',
    this.secretAnswer = '',
  });

  factory PostDraft.empty({required String defaultContact}) => PostDraft(
        category: ItemCategory.seeker,
        title: '',
        location: '',
        occurredAt: DateTime.now(),
        contact: defaultContact,
      );

  factory PostDraft.fromItem(Item item, {required String myTelephone}) =>
      PostDraft(
        category: item.category,
        isSensitive: item.isSensitive,
        title: item.title,
        description: item.description ?? '',
        location: item.location,
        occurredAt: item.occurredAt,
        contact: item.contact ?? '',
        useMyNumber: item.contact == myTelephone,
        imageUrls: List.of(item.imageUrls),
        secretQuestion: item.secretQuestion ?? '',
        secretAnswer: item.secretAnswer ?? '',
      );

  PostDraft copyWith({
    ItemCategory? category,
    bool? isSensitive,
    String? title,
    String? description,
    String? location,
    DateTime? occurredAt,
    String? contact,
    bool? useMyNumber,
    List<String>? imageUrls,
    String? secretQuestion,
    String? secretAnswer,
  }) =>
      PostDraft(
        category: category ?? this.category,
        isSensitive: isSensitive ?? this.isSensitive,
        title: title ?? this.title,
        description: description ?? this.description,
        location: location ?? this.location,
        occurredAt: occurredAt ?? this.occurredAt,
        contact: contact ?? this.contact,
        useMyNumber: useMyNumber ?? this.useMyNumber,
        imageUrls: imageUrls ?? this.imageUrls,
        secretQuestion: secretQuestion ?? this.secretQuestion,
        secretAnswer: secretAnswer ?? this.secretAnswer,
      );

  /// Returns a map of `field -> error message` (empty when valid).
  /// Mirrors the validation in `screens-forms.jsx` `submit()`.
  /// [secretQuestionEnabled] comes from FeatureFlagService (WBS 2.13).
  Map<String, String> validate({required bool secretQuestionEnabled}) {
    final isFounder = category == ItemCategory.founder;
    final sensitive = isFounder && isSensitive;
    final errs = <String, String>{};
    if (title.trim().isEmpty) errs['title'] = 'Required';
    if (!sensitive && description.trim().isEmpty) {
      errs['description'] = 'Required';
    }
    if (location.trim().isEmpty) errs['location'] = 'Required';
    if (!sensitive && contact.trim().isEmpty) errs['contact'] = 'Required';
    if (isFounder &&
        !sensitive &&
        secretQuestionEnabled &&
        secretQuestion.trim().isNotEmpty &&
        secretAnswer.trim().isEmpty) {
      errs['secretAnswer'] =
          'Expected answer is required when question is set';
    }
    return errs;
  }

  /// Materializes the draft into a persistable [Item]. Encapsulates the five
  /// domain rules from the design doc (sensitive nullification, expiry,
  /// secret-question gating).
  ///
  /// [id] = '' for create (Firestore assigns); existing id for edit.
  /// [createdAt] reuses the original on edit; pass `DateTime.now()` for create.
  Item toItem({
    required String id,
    required String userId,
    required DateTime createdAt,
    required bool secretQuestionEnabled,
  }) {
    final isFounder = category == ItemCategory.founder;
    final sensitive = isFounder && isSensitive;
    final allowSecret = isFounder && !sensitive && secretQuestionEnabled;

    return Item(
      id: id,
      userId: userId,
      createdAt: createdAt,
      category: category,
      status: ItemStatus.active,
      source: ItemSource.web,
      isSensitive: sensitive,
      title: title.trim(),
      description: sensitive ? null : description.trim(),
      location: location.trim(),
      contact: sensitive ? null : contact.trim(),
      occurredAt: occurredAt,
      imageUrls: imageUrls,
      expiresAt:
          sensitive ? createdAt.add(const Duration(days: 14)) : null,
      secretQuestion: allowSecret && secretQuestion.trim().isNotEmpty
          ? secretQuestion.trim()
          : null,
      secretAnswer: allowSecret && secretAnswer.trim().isNotEmpty
          ? secretAnswer.trim()
          : null,
    );
  }
}
