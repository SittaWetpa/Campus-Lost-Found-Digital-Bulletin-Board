// WBS 2.7 — DeleteItemUseCase delegates to PostRepository.deleteItem.

import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';
import 'package:campus_lost_found/features/post/domain/usecases/delete_item_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostRepository extends Mock implements PostRepository {}

void main() {
  late _MockPostRepository repository;
  late DeleteItemUseCase useCase;

  setUp(() {
    repository = _MockPostRepository();
    useCase = DeleteItemUseCase(repository);
    when(() => repository.deleteItem(any())).thenAnswer((_) async {});
  });

  test('delegates the itemId to PostRepository.deleteItem', () async {
    await useCase('item-42');

    verify(() => repository.deleteItem('item-42')).called(1);
  });
}
