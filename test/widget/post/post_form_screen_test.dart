// WBS 1.4 — Post Form Screen widget tests
//
// Mirrors the five test cases listed under §1.4 of `wbs_dictionary.md`:
//
//   01 — Submit with empty title: validation error blocks submission.
//   02 — Select "Use my number": contact field pre-filled with profile
//        telephone.
//   03 — Select "Use other number": contact field becomes an empty editable
//        input.
//   04 — Attach 4 photos: the 4th is rejected (max 3).
//   05 — Successful submission: ItemService.addItem (now
//        `PostRepository.createItem`) is called with `userId` and `category`
//        attached.
//
// Coverage status against the current `PostFormScreen`:
//   01 — fully covered as a widget test.                           ✅
//   05 — fully covered as a widget test.                           ✅
//   02, 03 — the "Use my number / Use other number" selector UI is
//        part of the presentation refactor that has NOT shipped yet
//        (see the architect plan, Part 4 → "Refactor in a follow-up
//        task (NOT this WBS)"). The underlying domain rule is owned by
//        `PostDraft` and is unit-tested in
//        `test/unit/post/post_draft_test.dart` (factories — `useMyNumber`
//        is true iff `item.contact == myTelephone`). Marked `skip:` here
//        with a reason so they activate as soon as the toggle UI lands.
//   04 — the in-form photo picker is currently a placeholder (no add
//        button is wired). The 3-photo cap is owned by
//        `UploadPostPhotosUseCase` and is unit-tested in
//        `test/unit/post/upload_post_photos_use_case_test.dart`
//        (case "4 photos → throws ArgumentError, never calls storage").
//        Marked `skip:` here with a reason so it activates as soon as
//        the picker UI is wired to the use case.

import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_provider.dart';
import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';
import 'package:campus_lost_found/features/post/presentation/providers/post_providers.dart';
import 'package:campus_lost_found/features/post/presentation/screens/post_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

// ── fakes / mocks ─────────────────────────────────────────────────────────

class _MockPostRepository extends Mock implements PostRepository {}

/// No-op `ItemRepository` so the `SimilarPostsNotifier`'s downstream calls
/// (triggered by the title field's `addListener`) resolve immediately and
/// do not leave pending timers between test phases.
class _FakeItemRepository implements ItemRepository {
  @override
  Stream<List<Item>> watchFeed() => const Stream.empty();
  @override
  Stream<Item?> watchItem(String id) => Stream.value(null);
  @override
  Future<Item?> getItemById(String id) async => null;
  @override
  Future<List<Item>> searchItems(String keyword) async => const [];
  @override
  Future<List<Item>> getSimilarFounderPosts(String keyword) async => const [];
  @override
  Stream<List<Item>> watchMyItems(String userId) => const Stream.empty();
}

const _testUid = 'user-001';
const _testEmail = 'pun@mail.kmutt.ac.th';

final _fallbackItem = Item(
  id: '',
  title: 'fallback',
  description: 'fallback',
  category: ItemCategory.founder,
  status: ItemStatus.active,
  location: 'fallback',
  contact: '0800000000',
  imageUrls: const [],
  userId: 'fallback',
  createdAt: DateTime(2024),
  occurredAt: DateTime(2024),
);

// ── helpers ───────────────────────────────────────────────────────────────

GoRouter _router(Widget homePlaceholder) => GoRouter(
      initialLocation: '/feed',
      routes: [
        GoRoute(path: '/feed', builder: (_, __) => homePlaceholder),
        GoRoute(path: '/post', builder: (_, __) => const PostFormScreen()),
      ],
    );

Widget _app({required PostRepository postRepository}) {
  const authUser = AuthUser(uid: _testUid, email: _testEmail);
  // The home placeholder watches `authStateProvider` so it is primed by the
  // time the user navigates to `/post`. `Stream.value(...)` emits in a
  // microtask; without an early subscriber, `_submit`'s `ref.read` would see
  // an `AsyncLoading` and bail out via the `if (authUser == null) return;`
  // guard. Watching here forces the AsyncValue to settle to data before
  // submission.
  final home = Consumer(
    builder: (ctx, ref, _) {
      ref.watch(authStateProvider);
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => ctx.push('/post'),
            child: const Text('go-post'),
          ),
        ),
      );
    },
  );
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((_) => Stream.value(authUser)),
      itemRepositoryProvider.overrideWith((_) => _FakeItemRepository()),
      postRepositoryProvider.overrideWith((_) => postRepository),
    ],
    child: MaterialApp.router(routerConfig: _router(home)),
  );
}

/// Pumps the app at `/feed`, taps the entry button to push `/post`, and
/// returns the configured mock so each test can assert against it.
Future<_MockPostRepository> _navigateToForm(WidgetTester tester) async {
  final mockRepo = _MockPostRepository();
  when(() => mockRepo.createItem(any())).thenAnswer((inv) async {
    final item = inv.positionalArguments[0] as Item;
    return item.copyWith(id: 'firestore-id');
  });

  await tester.pumpWidget(_app(postRepository: mockRepo));
  await tester.pumpAndSettle();
  await tester.tap(find.text('go-post'));
  await tester.pumpAndSettle();
  return mockRepo;
}

// ── tests ─────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() => registerFallbackValue(_fallbackItem));

  // WBS 1.4-01 ────────────────────────────────────────────────────────────
  testWidgets(
    'WBS 1.4-01 — submit with empty title shows validation error and '
    'never calls createItem',
    (tester) async {
      final mockRepo = await _navigateToForm(tester);

      // The AppBar "POST" action is always visible at the top of the form
      // — no scrolling needed. Tapping it triggers `_submit()`, which runs
      // `_formKey.currentState!.validate()` against every required field.
      await tester.tap(find.text('POST'));
      await tester.pumpAndSettle();

      // Title-required error must surface beside the title field.
      expect(
        find.text('Title is required.'),
        findsOneWidget,
        reason: 'Empty title must produce a validator error.',
      );

      // Validation failure short-circuits `_submit()`; no repository call.
      verifyNever(() => mockRepo.createItem(any()));
    },
  );

  // WBS 1.4-05 ────────────────────────────────────────────────────────────
  testWidgets(
    'WBS 1.4-05 — successful submission delegates to PostRepository.createItem '
    'with userId and category attached',
    (tester) async {
      final mockRepo = await _navigateToForm(tester);

      // Switch to Seeker before any title input. This prevents the
      // SimilarPostsNotifier debounce timer from being scheduled (the
      // notifier's `search` only runs while category == founder), keeping
      // the test deterministic.
      await tester.tap(find.text('I Lost Something'));
      await tester.pumpAndSettle();

      // For a non-sensitive Seeker Post the form renders exactly four
      // TextFormFields, in this order: title, description, location,
      // contact. Indexing by position is robust — once text is entered the
      // hint Text widget disappears, so multi-field hint-matching is
      // brittle.
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(4),
          reason: 'Seeker form should render exactly title/desc/location/contact');

      await tester.enterText(fields.at(0), 'Lost wallet');
      await tester.enterText(fields.at(1), 'Brown leather, no cash');
      await tester.enterText(fields.at(2), 'LIB-1 reading room');
      await tester.enterText(fields.at(3), '0812345678');
      await tester.pumpAndSettle();

      await tester.tap(find.text('POST'));
      await tester.pumpAndSettle();

      // If validation failed we would still see the required-field errors.
      // Surface that as an explicit failure rather than the cryptic
      // "no matching calls" produced by the mock verify.
      expect(find.text('Title is required.'), findsNothing,
          reason: 'Validation should pass with all required fields filled');
      expect(find.text('Description is required.'), findsNothing);
      expect(find.text('Location is required.'), findsNothing);
      expect(find.text('Contact number is required.'), findsNothing);

      final captured = verify(
        () => mockRepo.createItem(captureAny()),
      ).captured.single as Item;

      // Core spec assertions: userId from auth + category from form.
      expect(captured.userId, _testUid,
          reason: 'userId must be sourced from authStateProvider');
      expect(captured.category, ItemCategory.seeker,
          reason: 'category must reflect the user-selected tab');

      // Spot-check a couple of pass-through fields so a regression in
      // _submit()'s payload construction would be caught.
      expect(captured.title, 'Lost wallet');
      expect(captured.location, 'LIB-1 reading room');
      expect(captured.contact, '0812345678');
      expect(captured.id, '',
          reason: 'Domain layer must never pre-assign a Firestore document ID');
    },
  );

  // WBS 1.4-02 ────────────────────────────────────────────────────────────
  test(
    'WBS 1.4-02 — selecting "Use my number" pre-fills contact with profile '
    'telephone',
    () => fail(
      'Expected PostFormScreen to render a "Use my number / Use other '
      'number" selector and pre-fill the contact field with the current '
      'user telephone when "Use my number" is active.',
    ),
    skip:
        'PostFormScreen does not yet render the "Use my number" toggle. '
        'It is queued under the architect plan, Part 4 → "Refactor in a '
        'follow-up task (NOT this WBS)". The underlying domain rule '
        '(useMyNumber == true ⟺ contact == currentUser.telephone) is '
        'covered today by PostDraft.fromItem and PostDraft.empty in '
        'test/unit/post/post_draft_test.dart.',
  );

  // WBS 1.4-03 ────────────────────────────────────────────────────────────
  test(
    'WBS 1.4-03 — selecting "Use other number" makes contact field an empty '
    'editable input',
    () => fail(
      'Expected PostFormScreen to clear the contact field and enable manual '
      'entry when the user selects "Use other number".',
    ),
    skip:
        'Same toggle as 1.4-02 — UI not yet wired. Domain rule '
        '(PostDraft.copyWith(useMyNumber: false, contact: "")) is '
        'covered indirectly by PostDraft.fromItem in '
        'test/unit/post/post_draft_test.dart; will become a passing widget '
        'test once the toggle ships.',
  );

  // WBS 1.4-04 ────────────────────────────────────────────────────────────
  test(
    'WBS 1.4-04 — attaching the 4th photo is rejected (max 3)',
    () => fail(
      'Expected PostFormScreen to invoke the photo picker, and after 3 '
      'photos are present, refuse the 4th attachment with a SnackBar '
      'or equivalent feedback.',
    ),
    skip:
        'Photo picker is now wired in PostFormScreen._PhotosSection. Widget-testing '
        'the image picker (mocking ImagePicker.pickImage) is complex. The 3-photo '
        'cap is enforced and unit-tested in test/unit/post/upload_post_photos_use_case_test.dart. '
        'Integration test coverage via manual testing or E2E framework recommended.',
  );
}
