// WBS 2.8 — Similar Posts panel: GetSimilarFounderPostsUseCase unit tests
//
// WBS 2.8 test cases covered here:
//   ✓ getSimilarFounderPosts("wallet") — verify only Active Founder Posts returned
//   ✓ panel hidden when keyword < 3 chars (enforced by caller — documented here)
//   ✓ empty result when no matches found

import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';
import 'package:campus_lost_found/features/post/domain/usecases/get_similar_founder_posts_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockItemRepository extends Mock implements ItemRepository {}

Item _founderPost({
  required String id,
  required String title,
  ItemStatus status = ItemStatus.active,
}) =>
    Item(
      id: id,
      title: title,
      description: 'desc',
      category: ItemCategory.founder,
      status: status,
      location: 'LIB-1',
      contact: '0800000000',
      imageUrls: const [],
      userId: 'user-poster',
      createdAt: DateTime(2024, 6, 1),
      occurredAt: DateTime(2024, 6, 1),
    );

void main() {
  late _MockItemRepository repository;
  late GetSimilarFounderPostsUseCase useCase;

  setUp(() {
    repository = _MockItemRepository();
    useCase = GetSimilarFounderPostsUseCase(repository);
  });

  // ── WBS 2.8 test case: only Active Founder Posts returned ─────────────────

  test(
    'WBS 2.8 — getSimilarFounderPosts("wallet"): returns Active Founder Posts '
    'from the repository',
    () async {
      final tResults = [
        _founderPost(id: 'f-001', title: 'Brown wallet found'),
        _founderPost(id: 'f-002', title: 'Wallet found near cafeteria'),
      ];
      when(() => repository.getSimilarFounderPosts('wallet'))
          .thenAnswer((_) async => tResults);

      final result = await useCase('wallet');

      expect(result, tResults);
      expect(result.every((i) => i.category == ItemCategory.founder), isTrue);
      expect(result.every((i) => i.status == ItemStatus.active), isTrue);
    },
  );

  test(
    'WBS 2.8 — delegates keyword verbatim to the repository',
    () async {
      when(() => repository.getSimilarFounderPosts(any()))
          .thenAnswer((_) async => []);

      await useCase('headphones');

      final captured =
          verify(() => repository.getSimilarFounderPosts(captureAny()))
              .captured
              .single as String;
      expect(captured, 'headphones');
    },
  );

  test(
    'WBS 2.8 — returns empty list when repository finds no matching posts',
    () async {
      when(() => repository.getSimilarFounderPosts('xyz-no-match'))
          .thenAnswer((_) async => []);

      final result = await useCase('xyz-no-match');

      expect(result, isEmpty);
    },
  );

  test(
    'WBS 2.8 — returns at most the results the repository provides (up to 3)',
    () async {
      final tResults = [
        _founderPost(id: 'f-001', title: 'Wallet 1'),
        _founderPost(id: 'f-002', title: 'Wallet 2'),
        _founderPost(id: 'f-003', title: 'Wallet 3'),
      ];
      when(() => repository.getSimilarFounderPosts('wall'))
          .thenAnswer((_) async => tResults);

      final result = await useCase('wall');

      expect(result.length, lessThanOrEqualTo(3));
    },
  );

  // ── Caller contract (≥3-char guard lives in the presentation layer) ────────

  test(
    'WBS 2.8 — short keyword (< 3 chars) still delegates to repository; '
    'the 3-char guard is the caller\'s responsibility',
    () async {
      when(() => repository.getSimilarFounderPosts('wa'))
          .thenAnswer((_) async => []);

      // Use case is a thin delegate — it does NOT enforce the length guard.
      final result = await useCase('wa');

      expect(result, isEmpty);
      verify(() => repository.getSimilarFounderPosts('wa')).called(1);
    },
  );

  test(
    'WBS 2.8 — empty keyword delegates to repository unchanged',
    () async {
      when(() => repository.getSimilarFounderPosts(''))
          .thenAnswer((_) async => []);

      final result = await useCase('');

      expect(result, isEmpty);
    },
  );

  // ── Category contract ──────────────────────────────────────────────────────

  test(
    'WBS 2.8 — similar posts panel is only relevant for Seeker Post creation; '
    'repository returns only Founder Posts (category contract)',
    () async {
      final tFounderPosts = [
        _founderPost(id: 'f-001', title: 'AirPods found'),
      ];
      when(() => repository.getSimilarFounderPosts('airpod'))
          .thenAnswer((_) async => tFounderPosts);

      final result = await useCase('airpod');

      for (final item in result) {
        expect(item.category, ItemCategory.founder,
            reason: 'getSimilarFounderPosts must never return Seeker Posts');
      }
    },
  );
}
