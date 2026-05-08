// WBS 2.6 — UpdateItemUseCase delegates to PostRepository.updateItem.

import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';
import 'package:campus_lost_found/features/post/domain/usecases/update_item_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostRepository extends Mock implements PostRepository {}

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
  late UpdateItemUseCase useCase;

  final tItem = Item(
    id: 'item-1',
    title: 'Updated title',
    description: 'Updated description',
    category: ItemCategory.founder,
    status: ItemStatus.active,
    location: 'LIB-1',
    contact: '0812345678',
    imageUrls: const [],
    userId: 'user-001',
    createdAt: DateTime(2026, 5, 1),
    occurredAt: DateTime(2026, 5, 1),
  );

  setUpAll(() => registerFallbackValue(_fallbackItem));

  setUp(() {
    repository = _MockPostRepository();
    useCase = UpdateItemUseCase(repository);
    when(() => repository.updateItem(any())).thenAnswer((_) async {});
  });

  test('delegates the Item unchanged to PostRepository.updateItem', () async {
    await useCase(tItem);

    final captured =
        verify(() => repository.updateItem(captureAny())).captured.single
            as Item;
    expect(captured, same(tItem));
  });
}
