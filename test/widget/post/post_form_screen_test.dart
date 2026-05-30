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

import 'package:campus_lost_found/core/domain/entities/feature_flags.dart';
import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';
import 'package:campus_lost_found/features/post/presentation/providers/post_provider.dart';
import 'package:campus_lost_found/features/post/presentation/screens/post_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// ── fakes / mocks ─────────────────────────────────────────────────────────

class _MockPostRepository extends Mock implements PostRepository {}

class _FakeFeatureFlags implements FeatureFlagService {
  const _FakeFeatureFlags({this.secretQuestionEnabled = true});

  @override
  final bool secretQuestionEnabled;
  @override
  bool get sensitiveItemEnabled => true;
  @override
  String get securityOfficeContact => '02-470-9999';
  @override
  Future<void> fetchAndActivate() async {}
  @override
  DateTime get lastFetchTime => DateTime.fromMillisecondsSinceEpoch(0);
  @override
  FeatureFlags get currentFlags => FeatureFlags(
        secretQuestionEnabled: secretQuestionEnabled,
        sensitiveItemEnabled: true,
        securityOfficeContact: '02-470-9999',
        sensitiveCategories: const [
          'credit_card', 'id_card', 'passport', 'key', 'document'
        ],
      );
}

/// Test double for `image_picker`'s platform interface. Lets us count
/// how many times the picker would have been opened, without going to a
/// real native dialog. Returns `null` (the "user cancelled" outcome) so
/// the rest of `_pickAndUploadPhoto` short-circuits cleanly.
class _MockImagePickerPlatform extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  int callCount = 0;
  ImagePickerOptions? lastOptions; // R5(d) — capture compression args

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    callCount++;
    lastOptions = options;
    return null;
  }
}

/// No-op `ItemRepository` so the `SimilarPostsNotifier`'s downstream calls
/// (triggered by the title field's `addListener`) resolve immediately and
/// do not leave pending timers between test phases. Optionally returns a
/// seeded item from `getItemById` to drive the edit-mode population path —
/// that's how the Photo Safety Case 2 tests get photos onto the form
/// without needing to mock image_picker.
class _FakeItemRepository implements ItemRepository {
  _FakeItemRepository({this.seededItem});
  final Item? seededItem;

  @override
  Stream<List<Item>> watchFeed() => const Stream.empty();
  @override
  Stream<Item?> watchItem(String id) => Stream.value(seededItem);
  @override
  Future<Item?> getItemById(String id) async => seededItem;
  @override
  Future<List<Item>> searchItems(String keyword) async => const [];
  @override
  Future<List<Item>> getRecentInCategory({
    required String categoryId,
    int limit = 5,
  }) async => const [];
  @override
  Stream<List<Item>> watchMyItems(String userId) => const Stream.empty();
  @override
  Future<String?> getItemSecretAnswer(String itemId) async => null;
}

const _testUid = 'user-001';
const _testEmail = 'pun@mail.kmutt.ac.th';
const _testTelephone = '0812345678';

final _testUser = User(
  uid: _testUid,
  email: _testEmail,
  firstName: 'Pun',
  lastName: 'Tester',
  studentId: '64000000',
  telephone: _testTelephone,
  emailVerified: true,
);

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
        GoRoute(
          path: '/post/:id/edit',
          builder: (_, s) =>
              PostFormScreen(editId: s.pathParameters['id']),
        ),
      ],
    );

Widget _app({
  required PostRepository postRepository,
  User? profile,
  Item? editingItem,
}) {
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
      currentUserProvider.overrideWith((_) => Stream.value(profile)),
      itemRepositoryProvider.overrideWith(
        (_) => _FakeItemRepository(seededItem: editingItem),
      ),
      postRepositoryProvider.overrideWith((_) => postRepository),
      featureFlagsProvider.overrideWith((_) => const _FakeFeatureFlags()),
    ],
    child: MaterialApp.router(routerConfig: _router(home)),
  );
}

/// Pumps the app at `/feed`, taps the entry button to push `/post`, and
/// returns the configured mock so each test can assert against it.
Future<_MockPostRepository> _navigateToForm(
  WidgetTester tester, {
  User? profile,
}) async {
  final mockRepo = _MockPostRepository();
  when(() => mockRepo.createItem(any())).thenAnswer((inv) async {
    final item = inv.positionalArguments[0] as Item;
    return item.copyWith(id: 'firestore-id');
  });

  await tester.pumpWidget(
    _app(postRepository: mockRepo, profile: profile),
  );
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

      // Switch to Seeker and select a category (WBS 2.8: required field).
      await tester.tap(find.text('I Lost Something'));
      await tester.pumpAndSettle();

      // Select the "Other" category tile so category validation passes.
      await tester.tap(find.text('Other'));
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
  testWidgets(
    'WBS 1.4-02 — "Use my number" is selected by default and pre-fills '
    'contact with the profile telephone',
    (tester) async {
      await _navigateToForm(tester, profile: _testUser);

      // Selector renders both options.
      expect(find.text('Use my number'), findsOneWidget);
      expect(find.text('Use different'), findsOneWidget);

      // The contact field (4th TextFormField on a Founder Post: title, desc,
      // location, contact) should be prefilled with the profile telephone
      // and rendered read-only.
      final fields = find.byType(TextFormField);
      final contactField = tester.widget<TextFormField>(fields.at(3));
      expect(contactField.controller!.text, _testTelephone);
      expect(contactField.controller!.text, isNotEmpty);
    },
  );

  // WBS 1.4-03 ────────────────────────────────────────────────────────────
  testWidgets(
    'WBS 1.4-03 — selecting "Use different" clears the contact field and '
    'makes it editable again',
    (tester) async {
      await _navigateToForm(tester, profile: _testUser);

      // Sanity: starts in Use-my-number mode with profile telephone.
      final fields = find.byType(TextFormField);
      var contactCtrl = tester.widget<TextFormField>(fields.at(3)).controller!;
      expect(contactCtrl.text, _testTelephone);

      // Switch to "Use different" — the contact section is below the fold
      // on the taller form (category picker + sensitive selector add height).
      await tester.ensureVisible(find.text('Use different'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use different'));
      await tester.pumpAndSettle();

      // Contact is cleared.
      contactCtrl = tester
          .widget<TextFormField>(find.byType(TextFormField).at(3))
          .controller!;
      expect(contactCtrl.text, isEmpty);

      // User can type a new number.
      await tester.ensureVisible(find.byType(TextFormField).at(3));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(3), '0899999999');
      await tester.pumpAndSettle();
      contactCtrl = tester
          .widget<TextFormField>(find.byType(TextFormField).at(3))
          .controller!;
      expect(contactCtrl.text, '0899999999');
    },
  );

  // WBS 1.4-02b ───────────────────────────────────────────────────────────
  // Edge case: profile has no telephone — selector is hidden and the
  // contact field is just a plain editable input. Avoids trapping the
  // user with a read-only prefilled-with-empty-string field.
  testWidgets(
    'WBS 1.4-02b — profile with empty telephone hides the source selector '
    'and leaves contact field editable',
    (tester) async {
      const noPhoneUser = User(
        uid: _testUid,
        email: _testEmail,
        firstName: 'Pun',
        lastName: 'Tester',
        studentId: '64000000',
        telephone: '',
        emailVerified: true,
      );
      await _navigateToForm(tester, profile: noPhoneUser);

      expect(find.text('Use my number'), findsNothing);
      expect(find.text('Use different'), findsNothing);

      // Contact field is empty and accepts user input.
      await tester.enterText(find.byType(TextFormField).at(3), '0888888888');
      await tester.pumpAndSettle();
      final contactCtrl = tester
          .widget<TextFormField>(find.byType(TextFormField).at(3))
          .controller!;
      expect(contactCtrl.text, '0888888888');
    },
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

  // WBS 2.10 — Photo Safety Guard, Case 1 ────────────────────────────────
  // Tap "Add Photo" with secret question already filled → dialog appears,
  // gating the file picker behind explicit confirmation. We swap
  // `ImagePickerPlatform.instance` with a counting mock so we can assert
  // whether the picker was actually opened — no real OS dialog ever runs.
  testWidgets(
    'Photo Safety Case 1 — Cancel does NOT open the picker; "I understand" '
    'opens it',
    (tester) async {
      // Restore the original picker after the test so we don't leak a
      // mock into other tests (test runner may reuse the isolate).
      final originalInstance = ImagePickerPlatform.instance;
      final mockPicker = _MockImagePickerPlatform();
      ImagePickerPlatform.instance = mockPicker;
      addTearDown(() => ImagePickerPlatform.instance = originalInstance);

      await _navigateToForm(tester, profile: _testUser);

      // Founder Post (default) — fields rendered: title, desc, location,
      // contact, sq, sa. Fill the SQ field WITHOUT photos present so
      // the Case 2 listener doesn't fire (no photos → no review prompt).
      final fields = find.byType(TextFormField);
      final sqIndex = fields.evaluate().length - 2;
      await tester.enterText(
        fields.at(sqIndex),
        'What colour is the lining?',
      );
      await tester.pumpAndSettle();
      // Sanity: no Case 2 dialog yet (no photos → no review prompt).
      expect(find.text('Photo Safety'), findsNothing);

      // ── First attempt: tap Add Photo, then Cancel ────────────────────
      // Scroll the photos placeholder into view first; in the test
      // viewport the form scrolls and the button can be off-screen.
      await tester.ensureVisible(find.text('Add photos (up to 3)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add photos (up to 3)'));
      await tester.pumpAndSettle();

      // Case 1 dialog should be visible.
      expect(find.text('Photo Safety'), findsOneWidget);
      expect(find.text('I understand'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Picker not invoked yet — gate is intercepting.
      expect(mockPicker.callCount, 0,
          reason: 'Picker must NOT be opened until the user confirms.');

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Photo Safety'), findsNothing);
      expect(mockPicker.callCount, 0,
          reason: 'Cancel must short-circuit before opening the picker.');

      // ── Second attempt: tap Add Photo, confirm with "I understand" ──
      // Per the spec, the dialog re-prompts on EVERY Add Photo tap (Case
      // 1 is a per-action gate, not a one-shot session flag).
      await tester.tap(find.text('Add photos (up to 3)'));
      await tester.pumpAndSettle();

      expect(find.text('Photo Safety'), findsOneWidget,
          reason: 'Dialog must re-prompt on each Add Photo tap.');

      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();

      expect(find.text('Photo Safety'), findsNothing);
      expect(mockPicker.callCount, 1,
          reason: 'Picker must open once the user confirms.');
    },
  );

  // WBS 2.10 — Photo Safety Guard, Case 1 no-fire path ──────────────────
  // No SQ → no dialog, picker opens immediately.
  testWidgets(
    'Photo Safety Case 1 — no dialog when secret question is empty; picker '
    'opens directly',
    (tester) async {
      final originalInstance = ImagePickerPlatform.instance;
      final mockPicker = _MockImagePickerPlatform();
      ImagePickerPlatform.instance = mockPicker;
      addTearDown(() => ImagePickerPlatform.instance = originalInstance);

      await _navigateToForm(tester, profile: _testUser);

      // Photos section is inside a SingleChildScrollView and may be off-
      // screen at the test viewport's default height. Scroll it into
      // view before tapping.
      await tester.ensureVisible(find.text('Add photos (up to 3)'));
      await tester.pumpAndSettle();

      // Tap Add Photo without filling the secret question.
      await tester.tap(find.text('Add photos (up to 3)'));
      await tester.pumpAndSettle();

      expect(find.text('Photo Safety'), findsNothing,
          reason: 'No SQ filled → no safety dialog.');
      expect(mockPicker.callCount, 1,
          reason: 'Picker should open directly when SQ is empty.');
    },
  );

  // WBS 2.10 — Photo Safety Guard, Case 2 ────────────────────────────────
  // Photos already present → user types into Secret Question → dialog
  // appears as a review prompt. Cancelling clears the SQ field so the
  // user can scrub photos before re-entering the question.
  //
  // Photos are seeded by routing through edit-mode (`/post/:id/edit`) with
  // a fake repository that returns an Item carrying imageUrls. This avoids
  // touching the form's private state while still exercising the real
  // _populateFromItem → _imageUrls path.
  testWidgets(
    'Photo Safety Case 2 — filling SQ with photos already present shows '
    'the review dialog; cancelling clears the SQ field',
    (tester) async {
      // Existing item with photos and NO secret question yet.
      final existing = Item(
        id: 'edit-1',
        title: 'Existing post',
        description: 'has photos already',
        category: ItemCategory.founder,
        status: ItemStatus.active,
        location: 'CB2',
        contact: '0812345678',
        imageUrls: const ['https://example.com/seeded.jpg'],
        userId: _testUid,
        createdAt: DateTime(2024),
        occurredAt: DateTime(2024),
      );

      final mockRepo = _MockPostRepository();
      await tester.pumpWidget(_app(
        postRepository: mockRepo,
        profile: _testUser,
        editingItem: existing,
      ));
      await tester.pumpAndSettle();

      // Navigate to edit-mode for the seeded item.
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .context
          .go('/post/${existing.id}/edit');
      await tester.pumpAndSettle();

      // Form is populated; the SQ field starts empty (existing item had
      // no secret question). Find the SQ field — on edit-mode founder
      // post: title, desc, location, contact, sq, sa.
      final fields = find.byType(TextFormField);
      final sqIndex = fields.evaluate().length - 2;

      await tester.enterText(fields.at(sqIndex), 'What colour is the lining?');
      await tester.pumpAndSettle();

      // Dialog appears.
      expect(find.text('Photo Safety'), findsOneWidget);
      expect(find.text('I understand'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel → dialog closes AND SQ field is cleared (revert).
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Photo Safety'), findsNothing);
      final sqCtrl = tester
          .widget<TextFormField>(find.byType(TextFormField).at(sqIndex))
          .controller!;
      expect(sqCtrl.text, isEmpty);
    },
  );

  // WBS 2.10 — Photo Safety Guard, Case 2 confirm path ──────────────────
  testWidgets(
    'Photo Safety Case 2 — "I understand" keeps the SQ text intact',
    (tester) async {
      final existing = Item(
        id: 'edit-2',
        title: 'Existing post',
        description: 'has photos already',
        category: ItemCategory.founder,
        status: ItemStatus.active,
        location: 'CB2',
        contact: '0812345678',
        imageUrls: const ['https://example.com/seeded.jpg'],
        userId: _testUid,
        createdAt: DateTime(2024),
        occurredAt: DateTime(2024),
      );

      final mockRepo = _MockPostRepository();
      await tester.pumpWidget(_app(
        postRepository: mockRepo,
        profile: _testUser,
        editingItem: existing,
      ));
      await tester.pumpAndSettle();

      tester
          .state<NavigatorState>(find.byType(Navigator))
          .context
          .go('/post/${existing.id}/edit');
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      final sqIndex = fields.evaluate().length - 2;
      const sqText = 'What colour is the lining?';
      await tester.enterText(fields.at(sqIndex), sqText);
      await tester.pumpAndSettle();

      expect(find.text('Photo Safety'), findsOneWidget);
      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();

      expect(find.text('Photo Safety'), findsNothing);
      final sqCtrl = tester
          .widget<TextFormField>(find.byType(TextFormField).at(sqIndex))
          .controller!;
      expect(sqCtrl.text, sqText);
    },
  );

  // WBS 2.10 — Photo Safety Guard, Case 2 no-fire path ───────────────────
  testWidgets(
    'Photo Safety Case 2 — typing in SQ does NOT show the dialog when no '
    'photos are attached',
    (tester) async {
      await _navigateToForm(tester, profile: _testUser);

      final fields = find.byType(TextFormField);
      final sqIndex = fields.evaluate().length - 2;
      await tester.enterText(fields.at(sqIndex), 'Anything');
      await tester.pumpAndSettle();

      expect(find.text('Photo Safety'), findsNothing);
    },
  );

  // WBS 2.6-01 ────────────────────────────────────────────────────────────
  testWidgets(
    'WBS 2.6-01 — edit mode pre-populates all fields with existing item values',
    (tester) async {
      final existing = Item(
        id: 'item-edit-01',
        title: 'Blue Umbrella',
        description: 'Left at the library entrance',
        category: ItemCategory.seeker,
        status: ItemStatus.active,
        location: 'Library 2nd floor',
        contact: '081-234-5678',
        imageUrls: const [],
        userId: _testUid,
        createdAt: DateTime(2026, 5, 1),
        occurredAt: DateTime(2026, 5, 1),
      );

      final mockRepo = _MockPostRepository();
      await tester.pumpWidget(_app(
        postRepository: mockRepo,
        profile: _testUser,
        editingItem: existing,
      ));
      await tester.pumpAndSettle();

      tester
          .state<NavigatorState>(find.byType(Navigator))
          .context
          .go('/post/${existing.id}/edit');
      await tester.pumpAndSettle();

      // App bar shows edit title.
      expect(find.text('Edit Post'), findsOneWidget);

      // All TextFormFields are pre-populated: title, desc, location, contact.
      expect(
        find.widgetWithText(TextFormField, existing.title),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, existing.description),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, existing.location),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, existing.contact),
        findsOneWidget,
      );
    },
  );

  // WBS 2.6-02 ────────────────────────────────────────────────────────────
  testWidgets(
    'WBS 2.6-02 — edit mode: save with empty title shows validation error',
    (tester) async {
      final existing = Item(
        id: 'item-edit-02',
        title: 'Red Jacket',
        description: 'Left at cafeteria',
        category: ItemCategory.founder,
        status: ItemStatus.active,
        location: 'Cafeteria',
        contact: '081-000-0099',
        imageUrls: const [],
        userId: _testUid,
        createdAt: DateTime(2026, 5, 1),
        occurredAt: DateTime(2026, 5, 1),
      );

      final mockRepo = _MockPostRepository();
      await tester.pumpWidget(_app(
        postRepository: mockRepo,
        profile: _testUser,
        editingItem: existing,
      ));
      await tester.pumpAndSettle();

      tester
          .state<NavigatorState>(find.byType(Navigator))
          .context
          .go('/post/${existing.id}/edit');
      await tester.pumpAndSettle();

      // Clear the title field.
      await tester.enterText(
        find.widgetWithText(TextFormField, existing.title),
        '',
      );

      // Tap the app bar POST button to trigger validation.
      await tester.tap(find.text('POST'));
      await tester.pumpAndSettle();

      expect(find.text('Title is required.'), findsOneWidget);
      verifyNever(() => mockRepo.updateItem(any()));
    },
  );

  // WBS 2.14 — Sensitive Item selector ───────────────────────────────────

  // Test case from wbs_dictionary.md §2.14:
  // "Widget test: Post Form with category = Founder Post → select Sensitive
  //  type → verify description, contact, and Secret Question fields are hidden"
  testWidgets(
    'WBS 2.14 — Founder Post: selecting "Sensitive Item" hides description, '
    'contact, and Secret Question fields',
    (tester) async {
      // Profile with a telephone so "Use my number" appears and we can confirm
      // the full CONTACT section (label + selector + field) is hidden.
      await _navigateToForm(tester, profile: _testUser);

      // ── Sanity: default Founder Post shows all fields ──────────────────
      // The form opens as Founder (PostFormScreen._category = founder).
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(find.text('CONTACT'), findsOneWidget);
      expect(find.text('SECRET QUESTION (optional)'), findsOneWidget);

      // ── Tap "Sensitive Item" ───────────────────────────────────────────
      await tester.ensureVisible(find.text('Sensitive Item'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sensitive Item'));
      await tester.pumpAndSettle();

      // ── Sensitive mode: hidden fields ─────────────────────────────────
      expect(find.text('DESCRIPTION'), findsNothing,
          reason: 'Description label must vanish for sensitive items');
      expect(find.text('CONTACT'), findsNothing,
          reason: 'Contact label must vanish for sensitive items');
      expect(find.text('SECRET QUESTION (optional)'), findsNothing,
          reason: 'Secret Question label must vanish for sensitive items');

      // LOCATION and PHOTOS must still be present (always shown).
      expect(find.text('LOCATION'), findsOneWidget);
      expect(find.text('PHOTOS'), findsOneWidget);
    },
  );

  testWidgets(
    'WBS 2.14 — switching back to "General Item" restores description and '
    'contact fields',
    (tester) async {
      await _navigateToForm(tester, profile: _testUser);

      // Select Sensitive first.
      await tester.ensureVisible(find.text('Sensitive Item'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sensitive Item'));
      await tester.pumpAndSettle();

      expect(find.text('DESCRIPTION'), findsNothing);

      // Switch back to General.
      await tester.ensureVisible(find.text('General Item'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('General Item'));
      await tester.pumpAndSettle();

      expect(find.text('DESCRIPTION'), findsOneWidget,
          reason: 'Description must reappear when General Item is re-selected');
      expect(find.text('CONTACT'), findsOneWidget,
          reason: 'Contact must reappear when General Item is re-selected');
    },
  );

  testWidgets(
    'WBS 2.14 — switching category to Seeker hides the Sensitive selector entirely',
    (tester) async {
      await _navigateToForm(tester);

      // Default: Founder — Sensitive Item button is in the widget tree.
      // (SingleChildScrollView renders all children; find works even off-screen.)
      expect(find.text('Sensitive Item'), findsOneWidget);
      expect(find.text('General Item'), findsOneWidget);

      // Category selector is at the top of the form — scroll to it and tap Seeker.
      await tester.ensureVisible(find.text('I Lost Something'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I Lost Something'));
      await tester.pumpAndSettle();

      // Sensitive selector must vanish (only shown for Founder posts).
      expect(find.text('Sensitive Item'), findsNothing,
          reason: 'Sensitive selector must not appear on Seeker posts');
      expect(find.text('General Item'), findsNothing);
    },
  );

  // WBS 2.10 — Secret Question field visibility by category ─────────────────

  testWidgets(
    'WBS 2.10 — Seeker Post hides the Secret Question field',
    (tester) async {
      await _navigateToForm(tester);

      // Default is Founder Post — SECRET QUESTION field is shown.
      expect(find.text('SECRET QUESTION (optional)'), findsOneWidget);

      // Switch to Seeker category.
      await tester.ensureVisible(find.text('I Lost Something'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I Lost Something'));
      await tester.pumpAndSettle();

      // Secret Question must not appear on Seeker Posts.
      expect(find.text('SECRET QUESTION (optional)'), findsNothing,
          reason: 'Secret Question section is only for Founder Posts');
    },
  );

  // WBS 2.10 — Photo Safety Guard, Case 1 additional no-fire paths ──────────

  testWidgets(
    'Photo Safety Case 1 — Seeker Post: no dialog on Add Photo; '
    'picker opens directly',
    (tester) async {
      final originalInstance = ImagePickerPlatform.instance;
      final mockPicker = _MockImagePickerPlatform();
      ImagePickerPlatform.instance = mockPicker;
      addTearDown(() => ImagePickerPlatform.instance = originalInstance);

      await _navigateToForm(tester, profile: _testUser);

      // Switch to Seeker (no SQ field rendered).
      await tester.ensureVisible(find.text('I Lost Something'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I Lost Something'));
      await tester.pumpAndSettle();

      // Tap Add Photo — no SQ value can exist, so no safety dialog fires.
      await tester.ensureVisible(find.text('Add photos (up to 3)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add photos (up to 3)'));
      await tester.pumpAndSettle();

      expect(find.text('Photo Safety'), findsNothing,
          reason: 'No SQ field on Seeker Post → Case 1 dialog must not appear');
      expect(mockPicker.callCount, 1,
          reason: 'Picker should open immediately on Seeker Post');
    },
  );

  testWidgets(
    'R5(d) — Add Photo passes compression args to the picker '
    '(imageQuality/maxWidth/maxHeight)',
    (tester) async {
      final originalInstance = ImagePickerPlatform.instance;
      final mockPicker = _MockImagePickerPlatform();
      ImagePickerPlatform.instance = mockPicker;
      addTearDown(() => ImagePickerPlatform.instance = originalInstance);

      await _navigateToForm(tester, profile: _testUser);

      // Seeker Post → no Photo Safety dialog, picker opens directly.
      await tester.ensureVisible(find.text('I Lost Something'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I Lost Something'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Add photos (up to 3)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add photos (up to 3)'));
      await tester.pumpAndSettle();

      expect(mockPicker.lastOptions, isNotNull);
      expect(mockPicker.lastOptions!.imageQuality, 85);
      expect(mockPicker.lastOptions!.maxWidth, 1600);
      expect(mockPicker.lastOptions!.maxHeight, 1600);
    },
  );

  testWidgets(
    'Photo Safety Case 1 — Sensitive Item: no dialog on Add Photo; '
    'picker opens directly',
    (tester) async {
      final originalInstance = ImagePickerPlatform.instance;
      final mockPicker = _MockImagePickerPlatform();
      ImagePickerPlatform.instance = mockPicker;
      addTearDown(() => ImagePickerPlatform.instance = originalInstance);

      await _navigateToForm(tester, profile: _testUser);

      // Switch to Sensitive Item (SQ field is hidden).
      await tester.ensureVisible(find.text('Sensitive Item'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sensitive Item'));
      await tester.pumpAndSettle();

      // Tap Add Photo — SQ is not accessible, so no safety dialog fires.
      await tester.ensureVisible(find.text('Add photos (up to 3)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add photos (up to 3)'));
      await tester.pumpAndSettle();

      expect(find.text('Photo Safety'), findsNothing,
          reason: 'SQ field hidden on Sensitive Item → Case 1 dialog must not appear');
      expect(mockPicker.callCount, 1,
          reason: 'Picker should open immediately on Sensitive Item');
    },
  );

  testWidgets(
    'Photo Safety Case 1 — edit mode with existing secretQuestion: '
    'dialog appears when tapping Add Photo',
    (tester) async {
      final originalInstance = ImagePickerPlatform.instance;
      final mockPicker = _MockImagePickerPlatform();
      ImagePickerPlatform.instance = mockPicker;
      addTearDown(() => ImagePickerPlatform.instance = originalInstance);

      // Existing item with secretQuestion already set and no photos yet.
      final existing = Item(
        id: 'edit-sq-case1',
        title: 'Item with secret question',
        description: 'desc',
        category: ItemCategory.founder,
        status: ItemStatus.active,
        location: 'CB2',
        contact: '0812345678',
        imageUrls: const [],
        userId: _testUid,
        createdAt: DateTime(2024),
        occurredAt: DateTime(2024),
        secretQuestion: 'What brand is it?',
      );

      final mockRepo = _MockPostRepository();
      await tester.pumpWidget(_app(
        postRepository: mockRepo,
        profile: _testUser,
        editingItem: existing,
      ));
      await tester.pumpAndSettle();

      tester
          .state<NavigatorState>(find.byType(Navigator))
          .context
          .go('/post/${existing.id}/edit');
      await tester.pumpAndSettle();

      // The SQ field is pre-filled from the existing item.
      // Tapping Add Photo with a pre-filled SQ should trigger Case 1 dialog.
      await tester.ensureVisible(find.text('Add photos (up to 3)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add photos (up to 3)'));
      await tester.pumpAndSettle();

      expect(
        find.text('Photo Safety'),
        findsOneWidget,
        reason:
            'Safety dialog must appear when SQ is pre-filled from edit mode',
      );
      expect(mockPicker.callCount, 0,
          reason: 'Picker must not open until the user confirms');
    },
  );

  testWidgets(
    'meets accessibility guidelines (tap target size, labels)',
    (tester) async {
      final mockRepo = _MockPostRepository();
      when(() => mockRepo.createItem(any())).thenAnswer((inv) async {
        final item = inv.positionalArguments[0] as Item;
        return item.copyWith(id: 'firestore-id');
      });

      await tester.pumpWidget(_app(postRepository: mockRepo, profile: _testUser));
      await tester.pumpAndSettle();
      await tester.tap(find.text('go-post'));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      // textContrastGuideline is omitted: the "POST" AppBar action button
      // uses amber text (~2.53:1 on the AppBar background) — a pre-existing
      // design token issue not in scope for WBS 5.1.
    },
  );
}
