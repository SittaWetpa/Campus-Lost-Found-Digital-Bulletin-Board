// WBS 1.4 — Post Form Screen: CreateItemUseCase unit tests
//
// WBS 1.4 test case covered here:
//   ✓ "successful submission — verify addItem() is called with userId and category attached"
//
// Widget-layer test cases (pending PostFormScreen implementation):
//   ○ submit with empty title — verify validation error blocks submission
//   ○ select "Use my number" — verify contact field pre-filled with profile telephone
//   ○ select "Use other number" — verify contact field becomes empty editable input
//   ○ attach 4 photos — verify the 4th is rejected (max 3)

import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';
import 'package:campus_lost_found/features/post/domain/usecases/create_item_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostRepository extends Mock implements PostRepository {}

// Minimal valid Item used as a mocktail fallback value.
final _fallbackItem = Item(
  id: '',
  title: 'fallback',
  description: 'fallback',
  category: ItemCategory.founder,
  status: ItemStatus.active,
  location: 'fallback',
  contact: '0800000000',
  imageUrls: const [],
  userId: 'uid-fallback',
  createdAt: DateTime(2024),
  occurredAt: DateTime(2024),
);

void main() {
  late _MockPostRepository repository;
  late CreateItemUseCase useCase;

  // A realistic Founder Post submitted from the Post Form Screen.
  final tNewItem = Item(
    id: '',
    title: 'Brown wallet found near LIB-1',
    description: 'Brown leather wallet, no cash inside.',
    category: ItemCategory.founder,
    status: ItemStatus.active,
    location: 'LIB-1 reading room',
    contact: '0812345678',
    imageUrls: const ['https://storage.example.com/img1.jpg'],
    userId: 'user-001',
    createdAt: DateTime(2024, 6, 1, 10, 0),
    occurredAt: DateTime(2024, 6, 1, 9, 30),
    secretQuestion: 'What brand is on the inside?',
    secretAnswer: 'Fossil',
  );

  final tCreatedItem = tNewItem.copyWith(id: 'firestore-abc123');

  setUpAll(() => registerFallbackValue(_fallbackItem));

  setUp(() {
    repository = _MockPostRepository();
    useCase = CreateItemUseCase(repository);
    when(() => repository.createItem(any())).thenAnswer((_) async => tCreatedItem);
  });

  // ── WBS 1.4 test case: successful submission ───────────────────────────────

  test(
    'WBS 1.4-05 — successful submission: delegates to PostRepository with '
    'userId and category attached',
    () async {
      final result = await useCase(tNewItem);

      expect(result.id, 'firestore-abc123');
      expect(result.userId, 'user-001');
      expect(result.category, ItemCategory.founder);
      verify(() => repository.createItem(tNewItem)).called(1);
    },
  );

  test(
    'WBS 1.4-05 — caller must pass id = "" so the repository assigns the real ID',
    () async {
      await useCase(tNewItem);

      final captured =
          verify(() => repository.createItem(captureAny())).captured.single as Item;
      expect(captured.id, '',
          reason: 'Domain layer must never pre-assign a Firestore document ID');
    },
  );

  test(
    'WBS 1.4-05 — returned item carries the server-assigned ID',
    () async {
      final result = await useCase(tNewItem);

      expect(result.id, isNotEmpty);
    },
  );

  // ── Field pass-through assertions ─────────────────────────────────────────

  test('passes title, location, and occurredAt unchanged to the repository', () async {
    await useCase(tNewItem);

    final captured =
        verify(() => repository.createItem(captureAny())).captured.single as Item;
    expect(captured.title, tNewItem.title);
    expect(captured.location, tNewItem.location);
    expect(captured.occurredAt, tNewItem.occurredAt);
  });

  test('passes secretQuestion and secretAnswer unchanged to the repository', () async {
    await useCase(tNewItem);

    final captured =
        verify(() => repository.createItem(captureAny())).captured.single as Item;
    expect(captured.secretQuestion, 'What brand is on the inside?');
    expect(captured.secretAnswer, 'Fossil');
  });

  test('passes imageUrls unchanged to the repository', () async {
    await useCase(tNewItem);

    final captured =
        verify(() => repository.createItem(captureAny())).captured.single as Item;
    expect(captured.imageUrls, ['https://storage.example.com/img1.jpg']);
  });

  // ── Sensitive Founder Post ─────────────────────────────────────────────────

  test(
    'WBS 2.14 — sensitive Founder Post: description, contact, secretQuestion, '
    'secretAnswer are null',
    () async {
      final sensitiveItem = Item(
        id: '',
        title: 'Student ID card found',
        description: null,
        category: ItemCategory.founder,
        status: ItemStatus.active,
        location: 'ECC Building',
        contact: null,
        imageUrls: const [],
        userId: 'user-001',
        createdAt: DateTime(2024, 6, 1),
        occurredAt: DateTime(2024, 6, 1),
        isSensitive: true,
        expiresAt: DateTime(2024, 6, 15),
      );
      when(() => repository.createItem(any()))
          .thenAnswer((_) async => sensitiveItem.copyWith(id: 'sensitive-id'));

      await useCase(sensitiveItem);

      final captured =
          verify(() => repository.createItem(captureAny())).captured.single as Item;
      expect(captured.isSensitive, isTrue);
      expect(captured.description, isNull);
      expect(captured.contact, isNull);
      expect(captured.expiresAt, isNotNull);
    },
  );

  // ── Seeker Post ────────────────────────────────────────────────────────────

  test(
    'WBS 1.4-05 — Seeker Post: category is seeker and userId is present',
    () async {
      final seekerItem = Item(
        id: '',
        title: 'Lost black headphones',
        description: 'Sony WH-1000XM5, black, left in LIB-2.',
        category: ItemCategory.seeker,
        status: ItemStatus.active,
        location: 'LIB-2',
        contact: '0898765432',
        imageUrls: const [],
        userId: 'user-002',
        createdAt: DateTime(2024, 6, 2),
        occurredAt: DateTime(2024, 6, 2, 14, 0),
      );
      when(() => repository.createItem(any()))
          .thenAnswer((_) async => seekerItem.copyWith(id: 'seeker-id'));

      await useCase(seekerItem);

      final captured =
          verify(() => repository.createItem(captureAny())).captured.single as Item;
      expect(captured.category, ItemCategory.seeker);
      expect(captured.userId, 'user-002');
    },
  );
}
