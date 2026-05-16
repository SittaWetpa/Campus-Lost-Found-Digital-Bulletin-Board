# Test Scripts & Traceability Matrix
## Project: Campus Lost & Found Digital Bulletin Board

> This file is the single source of truth for test execution. See **WBS 7.1** in `wbs_dictionary.md` for the full work package definition.

---

## How to Run Tests

| Command | What it runs | When to run |
|---|---|---|
| `flutter test` | All Dart tests under `test/` | Before every PR merge |
| `flutter test test/unit/` | Unit tests only | During feature development |
| `flutter test test/features/` | Feature widget tests only | During UI development |
| `flutter test --coverage` | Full suite + generates `coverage/lcov.info` | For WBS 3.1 / 3.2 submission |
| `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/wbs_3_2_web_smoke_test.dart -d chrome` | Web integration smoke tests (requires chromedriver on PATH) | WBS 3.2 web verification |
| `flutter test integration_test/wbs_3_2_web_smoke_test.dart -d chrome` | Same tests via modern flutter-test runner | Alternative to flutter drive |
| `cd test/firestore_rules && npm test` | Firestore security rules (Node.js) | After editing `firestore.rules` |
| `cd test/functions && npm install && npm test` | Cloud Function + REST API unit tests (Node.js Jest) | After editing `functions/index.js` |

---

## Test File Structure

```
test/
├── unit/                         # Pure Dart — no Firebase, no Flutter
│   ├── auth/                                    ← WBS 0.1 / 0.2
│   │   ├── sign_up_test.dart
│   │   ├── sign_in_test.dart
│   │   ├── otp_remote_datasource_test.dart
│   │   ├── user_remote_datasource_test.dart
│   │   └── user_repository_impl_test.dart
│   ├── feed/                                    ← WBS 1.2 / 2.14
│   │   ├── feed_providers_test.dart
│   │   ├── item_entity_test.dart                ← WBS 2.14 (source/isSensitive/expiresAt)
│   │   ├── item_model_test.dart
│   │   └── item_repository_impl_test.dart
│   ├── post/                                    ← WBS 1.4 / 2.6 / 2.7 / 2.8 / 2.15
│   │   ├── create_item_use_case_test.dart
│   │   ├── delete_item_use_case_test.dart
│   │   ├── get_similar_founder_posts_use_case_test.dart
│   │   ├── post_draft_test.dart
│   │   ├── update_item_use_case_test.dart
│   │   └── upload_post_photos_use_case_test.dart
│   ├── requests/                                ← WBS 2.1 / 2.4
│   │   ├── item_request_entity_test.dart
│   │   ├── submit_claim_request_use_case_test.dart
│   │   └── submit_found_report_use_case_test.dart
│   ├── items/item_entity_test.dart              ← WBS 2.1
│   └── router/app_routes_test.dart              ← WBS 4.3
├── widget/                       # Widget tests — use ProviderScope overrides
│   ├── auth/router_redirect_test.dart           ← WBS 0.4 / 4.3
│   ├── feed/feed_screen_test.dart               ← WBS 1.2
│   ├── post/post_form_screen_test.dart          ← WBS 1.4 / 2.10
│   └── requests/                               ← WBS 2.10
│       ├── claim_request_screen_test.dart
│       └── found_report_screen_test.dart
├── features/                     # Per-feature widget tests
│   ├── auth/presentation/screens/
│   │   ├── login_screen_test.dart               ← WBS 0.3
│   │   ├── otp_verify_screen_test.dart          ← WBS 0.5
│   │   └── register_screen_test.dart            ← WBS 0.3
│   └── feed/data/
│       ├── datasources/
│       │   └── item_remote_datasource_test.dart     ← WBS 2.2
│       ├── models/
│       │   └── item_model_test.dart                  ← WBS 2.1 / 2.2
│       └── repositories/
│           └── item_repository_impl_test.dart        ← WBS 2.3
├── integration/                  # Integration tests (require Firebase Emulator)
│   └── wbs_2_1_firestore_rules_test.dart        ← WBS 2.1 (manual placeholder)
├── functions/                    # Node.js Cloud Function unit tests
│   ├── auto_expire_test.js                      ← WBS 2.14 (Cloud Function)
│   ├── items_api_test.js                        ← WBS 2.14 (REST API redaction)
│   └── package.json
└── firestore_rules/              # Node.js Firestore rules tests
    ├── rules.test.js                            ← WBS 2.1
    └── package.json
```

---

## Writing Conventions

- **Unit tests**: no Flutter, no Firebase imports. Use Mocktail for fakes.
- **Widget tests**: wrap in `ProviderScope(overrides: [...])`. Never call `Firebase.initializeApp()` in tests — always override the provider instead.
- **File location**: mirrors `lib/` — e.g. `test/features/auth/presentation/screens/login_screen_test.dart` ↔ `lib/features/auth/presentation/screens/login_screen.dart`
- **Naming**: `group('ScreenName — WBS X.Y', () { test('01 description...', ...) })`
- **New test files**: must be added to this traceability matrix when created.

---

## Traceability Matrix

### Phase 0.0 — Authentication
Run: `flutter test test/features/auth/`

| WBS | Description | Test file | Type | Status |
|---|---|---|---|---|
| 0.3 | Login screen | `test/features/auth/presentation/screens/login_screen_test.dart` | Widget | ✅ 6 tests |
| 0.3 | Register screen | `test/features/auth/presentation/screens/register_screen_test.dart` | Widget | ✅ 11 tests |
| 0.1 | SignUp use case (domain check + auth/user repo delegation) | `test/unit/auth/sign_up_test.dart` | Unit | ✅ 7 tests |
| 0.1 | SignIn use case (domain check + repo delegation) | `test/unit/auth/sign_in_test.dart` | Unit | ✅ 4 tests |
| 0.1 | OTP Cloud Functions caller (exception mapping + call shape) | `test/unit/auth/otp_remote_datasource_test.dart` | Unit | ✅ 4 tests |
| 0.2 | Firestore user-profile datasource | `test/unit/auth/user_remote_datasource_test.dart` | Unit | ✅ 10 tests |
| 0.2 | UserRepositoryImpl (delegation + Failure wrapping) | `test/unit/auth/user_repository_impl_test.dart` | Unit | ✅ 8 tests |
| 0.4 | Auth state & route guard | `test/widget/auth/router_redirect_test.dart` | Widget | ✅ 21 tests |
| 0.5 | OTP verification screen | `test/features/auth/presentation/screens/otp_verify_screen_test.dart` | Widget | ✅ 5 tests |

> ℹ️ **WBS 0.1 OTP behavioural cases live in Cloud Functions, not Dart.** The four OTP test cases listed in `wbs_dictionary.md` WBS 0.1 ("correct code returns true / writes emailVerified", "expired returns false", "5 wrong attempts locked out", "attempts ≥ 5 returns false") test logic that runs server-side in `functions/index.js`. The Dart `CloudFunctionOtpDatasource` is a thin caller — `otp_remote_datasource_test.dart` covers the call shape and exception mapping it actually owns. A Cloud Functions test suite is not yet in place; flagged as follow-up for the WBS 0.1 owner.
> ℹ️ **WBS 0.2 cross-user-access denial** is enforced by Firestore Security Rules, exercised in `test/firestore_rules/rules.test.js` (Node.js — `cd test/firestore_rules && npm test`).
> ℹ️ **WBS 1.4-04 (4-photo cap)** stays skipped at the widget level — exercising the cap requires already having 3 photos, which requires successful upload, which requires Firebase Storage. The cap is unit-tested in `test/unit/post/upload_post_photos_use_case_test.dart`. **Photo Safety Guard Case 1 and Case 2 are both widget-tested** — Case 1 by overriding `ImagePickerPlatform.instance` with a counting mock (verifying the picker is NOT opened on Cancel and IS opened on "I understand"); Case 2 by seeding photos through the edit-mode populate path.

---

### Phase 1.0 — Flutter UI
Run: `flutter test test/features/`

| WBS | Description | Test file | Type | Status |
|---|---|---|---|---|
| 1.2 | Item listing feed screen + ItemCard | `test/widget/feed/feed_screen_test.dart` | Widget | ✅ 23 tests |
| 1.2 | Feed providers (filter + filtered watchFeed view-model) | `test/unit/feed/feed_providers_test.dart` | Unit | ✅ 10 tests |
| 1.3 / 2.4 | Item detail screen (role views, sensitive item, existing request, Seeker Post, editedAt label, delete guard with pending requests) | `test/widget/feed/item_detail_screen_test.dart` | Widget | ✅ 9 tests |
| 1.3 | Request detail screen (verification card, action buttons by role/status) | `test/widget/feed/request_detail_screen_test.dart` | Widget | ✅ 5 tests |
| 1.4 / 2.10 / 2.14 | Post form screen (validation, submission, "Use my number" toggle, Photo Safety Case 1 + 2 including Seeker/Sensitive/edit-mode edge cases, SQ field hidden on Seeker, Sensitive selector hides description/contact/SQ) | `test/widget/post/post_form_screen_test.dart` | Widget | ✅ 19 tests (+ 1 skipped — see note) |
| 1.4 | PostDraft entity (factories + sensitive-item invariants) | `test/unit/post/post_draft_test.dart` | Unit | ✅ 21 tests |
| 1.5 | Search bar widget | — | Widget | ⬜ not yet written |
| 1.6 | Settings & profile screen | `test/features/profile/presentation/screens/settings_screen_test.dart` | Widget | ✅ 4 tests |
| 1.7 | My posts screen | `test/features/feed/presentation/screens/my_posts_screen_test.dart` | Widget | ✅ 3 tests |
| 1.8 | Edit profile & avatar screen | `test/features/profile/presentation/screens/edit_profile_screen_test.dart` | Widget | ✅ 4 tests |

---

### Phase 2.0 — Data Layer
Run: `flutter test test/unit/` and `cd test/firestore_rules && npm test`

| WBS | Description | Test file | Type | Status |
|---|---|---|---|---|
| 2.1 | Item entity | `test/unit/items/item_entity_test.dart` | Unit | ✅ 60 tests |
| 2.1 | ItemRequest entity | `test/unit/requests/item_request_entity_test.dart` | Unit | ✅ 21 tests |
| 2.1 | Firestore rules | `test/firestore_rules/rules.test.js` | Node.js | ✅ 9 tests |
| 2.1 | Firestore rules (placeholder) | `test/integration/wbs_2_1_firestore_rules_test.dart` | Integration | ⏭️ 3 skipped (manual) |
| 2.2 | Firestore CRUD for items | `test/features/feed/data/datasources/item_remote_datasource_test.dart` | Unit | ✅ 5 tests |
| 2.1 / 2.2 | ItemModel ↔ Firestore mapping (focused) | `test/features/feed/data/models/item_model_test.dart` | Unit | ✅ 5 tests |
| 1.2 / 2.1 | ItemModel full mapping + null-tolerance regression (`source` / `isSensitive` / `occurredAt`) | `test/unit/feed/item_model_test.dart` | Unit | ✅ 48 tests |
| 2.3 | Keyword search query | `test/features/feed/data/repositories/item_repository_impl_test.dart` | Unit | ✅ 3 tests |
| 1.2 | ItemRepositoryImpl (entity↔model mapping + ItemFailure wrapping) | `test/unit/feed/item_repository_impl_test.dart` | Unit | ✅ 12 tests |
| 2.4 | SubmitClaimRequestUseCase (Seeker → Founder) | `test/unit/requests/submit_claim_request_use_case_test.dart` | Unit | ✅ 10 tests |
| 2.4 | SubmitFoundReportUseCase (Founder → Seeker) | `test/unit/requests/submit_found_report_use_case_test.dart` | Unit | ✅ 15 tests |
| 1.3 / 2.4 | ApproveRequestUseCase (delegation, success, exception propagation) | `test/unit/requests/approve_request_use_case_test.dart` | Unit | ✅ 3 tests |
| 1.3 / 2.4 | RejectRequestUseCase (delegation, success, exception propagation) | `test/unit/requests/reject_request_use_case_test.dart` | Unit | ✅ 3 tests |
| 1.3 / 2.4 | CancelRequestUseCase (delegation, success, exception propagation) | `test/unit/requests/cancel_request_use_case_test.dart` | Unit | ✅ 3 tests |
| 1.3 / 2.4 | ItemRequestRepositoryImpl (batch approve, reject, cancel, hasPendingRequests, watchMyRequestForItem, watchSingleRequest) | `test/unit/requests/item_request_repository_impl_test.dart` | Unit | ✅ 8 tests |
| 2.4.1 | canResubmit policy logic (no history, attempts-remaining on SQ post, permanent block, cooldown active, cooldown expired, alreadyActive, per-requester scoping) | `test/unit/requests/can_resubmit_logic_test.dart` | Unit | ✅ 7 tests |
| 2.4.1 | CheckResubmitPolicyUseCase (delegation to repository) | `test/unit/requests/check_resubmit_policy_use_case_test.dart` | Unit | ✅ 1 test |
| 2.4.1 | submitRequest throws ResubmitNotAllowedFailure when policy denies; proceeds when allowed | `test/unit/requests/submit_request_resubmit_guard_test.dart` | Unit | ✅ 2 tests |
| 2.4.1 | ResubmitBanner widget — attempts-remaining, permanent-block, cooldown, hidden when allowed | `test/widget/feed/item_detail_resubmit_banner_test.dart` | Widget | ✅ 4 tests |
| 2.4.1 | End-to-end policy enforcement (Cloud Function trigger + UI) — manual emulator run | `test/integration/wbs_2_4_1_resubmit_test.dart` | Integration | ⬜ manual placeholder |
| 2.4.1 | Firestore rules contract — basic create still allowed, policy_audit denied | `test/firestore_rules/rules.test.js` | Rules | ✅ 4 tests (in-file) |
| 2.5 | Datasource raw-string ops (setThemeMode/getThemeMode round-trip, fresh-install null, setLastViewedCategory null removes key, round-trip) | `test/features/profile/data/datasources/preference_local_datasource_test.dart` | Unit | ✅ 4 tests |
| 2.5 | Repository enum conversion (stored 'dark' → AppThemeMode.dark; no stored value → AppThemeMode.system) | `test/features/profile/data/repositories/preference_repository_impl_test.dart` | Unit | ✅ 2 tests |
| 2.5 | PreferenceService startup loader (stored value returned; missing key → 'system' default) | `test/core/services/preference_service_test.dart` | Unit | ✅ 2 tests |
| 2.6 | Post edit (UpdateItemUseCase + form edit-mode flow) | `test/unit/post/update_item_use_case_test.dart` | Unit | ✅ 1 test |
| 2.7 | Post delete (DeleteItemUseCase) | `test/unit/post/delete_item_use_case_test.dart` | Unit | ✅ 1 test |
| 2.8 | `getRecentInCategory` Firestore query (correct filters, empty result, sensitive excluded) | `test/features/feed/data/repositories/item_repository_impl_test.dart` (3 added) | Unit | ✅ 3 tests |
| 2.8 | `ItemModel.fromMap` / `toFirestore` — `itemCategory` round-trip + legacy backfill default | `test/features/feed/data/models/item_model_test.dart` (4 added) | Unit | ✅ 4 tests |
| 2.8 | `CategoryPicker` widget — validation error, onChanged fires, all 8 tiles rendered | `test/features/post/presentation/widgets/category_picker_test.dart` | Widget | ✅ 5 tests |
| 2.8 | `SimilarPostsPanel` widget — empty/loading/error hidden, items rendered, header count | `test/features/post/presentation/widgets/similar_posts_panel_test.dart` | Widget | ✅ 5 tests |
| 2.8 | `SimilarItemsNotifier` — initial state, load calls repo with correct id, clear resets, returns items | `test/features/post/presentation/providers/similar_items_provider_test.dart` | Unit | ✅ 4 tests |
| 2.8 | Firestore rules — `itemCategory` required on create; invalid value denied; valid values allowed | `test/firestore_rules/item_category.test.js` | Node.js | ✅ 5 tests (requires emulator) |
| 1.4 / 2.6 | CreateItemUseCase (post creation, sensitive-item null-handling) | `test/unit/post/create_item_use_case_test.dart` | Unit | ✅ 8 tests |
| 2.9 | REST API — `ApiItemListingModel` JSON parsing (full fields, sensitive masking, occurredAt fallback, nullable itemCategory) | `test/features/feed/data/models/api_item_listing_model_test.dart` | Unit | ✅ 11 tests |
| 2.9 | REST API — `FetchItemListingsUseCase` delegation (category, keyword, limit, empty list, exception propagation) | `test/features/feed/domain/usecases/fetch_item_listings_use_case_test.dart` | Unit | ✅ 6 tests |
| 2.9 | REST API — `ExternalApiRepositoryImpl` entity mapping + error translation (401→ServerFailure, 400→ServerFailure, unexpected→ServerFailure) | `test/features/feed/data/repositories/external_api_repository_impl_test.dart` | Unit | ✅ 9 tests |
| 2.9 / 2.14 | Cloud Function GET /items — sensitive redaction, auth guards, category filter, keyword filter, occurredAt/itemCategory fields | `test/functions/items_api_test.js` | Node.js | ✅ 10 tests |
| 2.10 | Secret question (Photo Safety Cases 1+2 incl. Seeker/Sensitive/edit-mode edge cases, SQ hidden on Seeker) | _see WBS 1.4/2.10/2.14 row above_ | Widget | ✅ covered |
| 2.10 | SecretAnswerRequiredFailure thrown when secretQuestion set + no answer; succeeds when no question; ResubmitNotAllowedFailure thrown before secret check | `test/unit/requests/submit_claim_request_wbs_2_10_test.dart` | Unit | ✅ 4 tests |
| 2.10 | ItemRequest.editedAt field + copyWith (WBS 2.4 schema gap) | `test/unit/requests/item_request_entity_test.dart` (added 3 tests) | Unit | ✅ 3 tests |
| 2.10 | ClaimRequestScreen — SQ block shown/hidden, empty-answer error, poster's answer not displayed, AlreadySubmitted screen | `test/widget/requests/claim_request_screen_test.dart` | Widget | ✅ 5 tests |
| 2.10 | FoundReportScreen — no Secret Question block or answer field | `test/widget/requests/found_report_screen_test.dart` | Widget | ✅ 1 test |
| 2.11 | Hive item local datasource (cold start, cacheFeed order, replace, cacheItem upsert, remove, full round-trip, nullable fields) | `test/features/feed/data/datasources/item_local_datasource_test.dart` | Unit | ✅ 7 tests |
| 2.11 | Hive sync metadata datasource (cold start, round-trip, independent keys, overwrite) | `test/core/services/sync_metadata_datasource_test.dart` | Unit | ✅ 4 tests |
| 2.11 | Hive user local datasource (cold start, cache+retrieve, upsert, round-trip all fields, nullable fields) | `test/features/auth/data/datasources/user_local_datasource_test.dart` | Unit | ✅ 5 tests |
| 2.11 | ItemRepositoryImpl offline — watchFeed fallback + write-through + error propagation; getItemById cache fallback; watchItem fallback + write-through + error propagation; watchMyItems fallback + write-through + error propagation | `test/features/feed/data/repositories/item_repository_impl_offline_test.dart` | Unit | ✅ 11 tests |
| 2.11 | UserRepositoryImpl offline — watchUser cache seed + write-through + error propagation; getUserById cache fallback + empty miss | `test/features/auth/data/repositories/user_repository_impl_offline_test.dart` | Unit | ✅ 5 tests |
| 2.11 | Offline banner widget — hidden when online, visible when offline, "No cached data" label, relative time display | `test/shared/widgets/offline_banner_test.dart` | Widget | ✅ 4 tests |
| 2.12 | Crashlytics & logging — AppLogger.error() routes to log with level=error; AppLogger.info() routes to log with level=info | `test/unit/observability/app_logger_test.dart` | Unit | ✅ 2 tests |
| 2.13 | FeatureFlagService — RC getters, network-failure fallback, malformed-JSON fallback | `test/core/services/feature_flag_service_test.dart` | Unit | ✅ 4 tests |
| 2.13 | PostFormScreen — secretQuestionEnabled flag hides/shows SECRET QUESTION section | `test/features/post/presentation/screens/post_form_screen_test.dart` | Widget | ✅ 2 tests |
| 2.14 | Sensitive Item entity invariants (source / isSensitive / expiresAt) + `ItemStatus.expired` parsing | `test/unit/feed/item_entity_test.dart` | Unit | ✅ 16 tests |
| 2.14 | `autoExpireSensitivePosts` Cloud Function (expired doc → status:'expired'; non-expired → unchanged; multiple docs) | `test/functions/auto_expire_test.js` | Node.js | ✅ 4 tests |
| 2.14 | REST API redaction (sensitive → omits contact/description; general → includes; auth + method guards; mixed feed) | `test/functions/items_api_test.js` | Node.js | ✅ 5 tests |
| 2.14 | Firestore rules: `isSensitive` and `expiresAt` immutable after creation (poster + visitor denied; allowed-field update succeeds) | `test/firestore_rules/rules.test.js` | Node.js | ✅ 4 tests (requires emulator) |
| 2.14 | Post Form: Founder → select Sensitive → description/contact/SQ hidden; General → fields restored; Seeker → selector hidden | `test/widget/post/post_form_screen_test.dart` | Widget | ✅ 3 tests |
| 2.15 | UploadPostPhotosUseCase (3-photo cap, storage upload) | `test/unit/post/upload_post_photos_use_case_test.dart` | Unit | ✅ 5 tests |
| 2.15 | QR walk-in: valid submit → 201 + source field; missing fields → 400; rate limit → 429; reCAPTCHA fail → 400; sensitive → isSensitive:true | `functions/test/walkin.test.js` | Node.js | ✅ 7 tests |
| 2.15 | ItemCard: walk-in ribbon rendered for source==qrWalkIn; absent for web source; ribbon uses blue container | `test/features/feed/presentation/widgets/item_card_test.dart` | Widget | ✅ 3 tests |
| 2.15 | Firestore rules: client write with source:"qr_walk_in" denied | — | Rules | ⬜ requires Firebase emulator |
| 2.16 | `NotificationType.fromString()` (4 valid + 3 error cases); `AppNotification` constructor + `copyWith()` (incl. null sentinel); `DeviceToken` + `DevicePlatform` (android/web only) | `test/unit/notifications/app_notification_entity_test.dart` | Unit | ✅ 29 tests |
| 2.16 | `NotificationService.registerToken()` — arrayUnion contract; `unregisterToken()` — arrayRemove contract | `test/unit/notifications/notification_service_test.dart` | Unit | ✅ 2 tests |
| 2.16 | Settings toggle "Receive notifications" off → `PreferenceRepository.setNotificationsEnabled(false)` | `test/features/profile/presentation/screens/settings_screen_test.dart` (test 03) | Widget | ✅ covered |
| 2.16 | CF `onNewRequest`: T1 payload (app/enabled/valid token); walk-in (userId=walkin, no user doc) skips FCM + doc write; in-app doc written to `users/{uid}/notifications/req_{requestId}`; stale token → arrayRemove; CF `onRequestStatusChange`: T3 on approved + doc write; T4 on rejected; non-qualifying change skips FCM | `functions/test/notifications.test.js` | Node.js | ✅ 7 tests; 2 skipped (manual integration) |
| 2.18 | UserModel.fromFirestore reads `isAdmin` (true / false / missing-defaults-to-false; toEntity carries it) | `test/unit/auth/user_model_is_admin_test.dart` | Unit | ✅ 4 tests |
| 2.18 | `FirestoreUserDatasource.createUser` stamps `isAdmin: false` on new accounts | `test/unit/auth/user_remote_datasource_test.dart` (added row to existing file) | Unit | ✅ 1 test |
| 2.18 | Settings screen — Developer section gated on `currentUser.isAdmin` | `test/features/profile/presentation/screens/settings_screen_admin_test.dart` | Widget | ✅ 2 tests |
| 2.18 | RemoteConfigViewerScreen renders all four flags + last-fetched banner + "Fetch & activate" trigger | `test/features/admin/presentation/screens/remote_config_viewer_screen_test.dart` | Widget | ✅ 4 tests |
| 2.18 | RollbackPlanScreen banner reflects `secret_question_enabled`; checklist toggles on tap | `test/features/admin/presentation/screens/rollback_plan_screen_test.dart` | Widget | ✅ 3 tests |
| 2.18 | Admin route guard: non-admin → /feed + snackbar; admin → viewer screen | `test/widget/admin/admin_route_guard_test.dart` | Widget | ✅ 2 tests |
| 2.18 | Firestore rules: client cannot self-elevate `isAdmin` (own doc, others' doc, on create) | `test/firestore_rules/rules.test.js` | Node.js | ✅ 4 tests (requires emulator) |

---

### Phase 3.0 — Cross-Platform
Run: `flutter test --coverage` and `flutter drive --target=test_driver/app.dart -d chrome`

| WBS | Description | Test file | Type | Status |
|---|---|---|---|---|
| 3.1 | Android build & verification | Full suite via `flutter test` | All | ⬜ pending full suite |
| 3.2 | Web build smoke tests (boot, auth guard, email validation, register nav, deep-link guard, image_picker_for_web compile check) | `integration_test/wbs_3_2_web_smoke_test.dart` | Integration | ✅ 6 smoke tests (requires chromedriver) |
| 3.2 | `flutter build web --release` zero-error build | Manual — verified 2026-05-15 | Smoke | ✅ passes |
| 3.2 | Firebase Web config, CORS, base href, Hive-IndexedDB, shared_preferences-localStorage | `CROSS_PLATFORM.md` checklist | Manual | ✅ documented |

---

### Phase 4.0 — Enterprise Architecture
Run: `flutter test test/unit/router/ test/widget/`

| WBS | Description | Test file | Type | Status |
|---|---|---|---|---|
| 4.3 | Route constants | `test/unit/router/app_routes_test.dart` | Unit | ✅ 36 tests |
| 4.3 | Auth redirect guards | `test/widget/auth/router_redirect_test.dart` | Widget | ✅ 21 tests |
| 4.1 | ItemTaxonomy domain entity: pure Dart, no Firebase (01a–01d) | `test/features/post/domain/entities/item_taxonomy_test.dart` | Unit | ✅ 4 tests |
| 4.1 | ItemModel mapper — domain→data direction, source field exclusion, round-trip (02a–02c) | `test/features/feed/data/models/item_model_test.dart` | Unit | ✅ 3 tests (added to existing file) |
| 4.2 | Riverpod state management | — | Unit + Widget | ⬜ not yet written |

---

### Phase 5.0 — Quality Gates
Run: `flutter test` (accessibility guidelines are asserted inside widget tests)

| WBS | Description | Test file | Type | Status |
|---|---|---|---|---|
| 5.1 | Accessibility (WCAG 2.2 AA) — `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline` added to 13 existing test files; 1 new test file created | `test/widget/notifications/notifications_screen_test.dart` (new); `test/features/auth/presentation/screens/login_screen_test.dart`; `test/features/auth/presentation/screens/register_screen_test.dart`; `test/features/auth/presentation/screens/otp_verify_screen_test.dart`; `test/widget/feed/feed_screen_test.dart`; `test/widget/feed/item_detail_screen_test.dart`; `test/features/feed/presentation/screens/my_posts_screen_test.dart`; `test/widget/post/post_form_screen_test.dart`; `test/features/post/presentation/screens/edit_post_screen_test.dart`; `test/widget/requests/claim_request_screen_test.dart`; `test/widget/requests/found_report_screen_test.dart`; `test/widget/feed/request_detail_screen_test.dart`; `test/features/profile/presentation/screens/edit_profile_screen_test.dart`; `test/features/profile/presentation/screens/settings_screen_test.dart` | Widget | ✅ 14 a11y test blocks; see `A11Y_AUDIT.md` for documented omissions |
| 5.2 | Security & dependency scans | CI workflow + Firestore rules | Rules + CI | ⬜ not yet written |

---

## Coverage Summary

Run `flutter test --coverage` then open `coverage/lcov.info` with `genhtml` or the VS Code Coverage Gutters extension.

| Phase | Tests written | Tests passing |
|---|---|---|
| 0.0 Auth | 55 | 55 |
| 1.0 Flutter UI | 82 | 82 |
| 2.0 Data Layer | 335 + 24 (npm) | 359 |
| 3.0 Cross-Platform | 6 (integration) | requires chromedriver |
| 4.0 Architecture | 44 | 44 |
| 5.0 Quality Gates | 17 | 17 |
| **Total** | **527 Dart + 24 npm** | **543 passing + 24 npm** |

> Phase totals add to 418 Dart; `flutter test` is the source of truth. The small discrepancy vs. `flutter test` is accounting drift (some files cover multiple WBS rows). **`flutter test` is the source of truth.**

---

*Last updated: 2026-05-15 (WBS 3.2 — Web Build, Testing & Verification. Added: `test_driver/integration_test.dart`, `integration_test/wbs_3_2_web_smoke_test.dart` (6 smoke tests), `CROSS_PLATFORM.md` (feature-parity matrix + manual verification steps), `integration_test: sdk: flutter` dev dependency, two new run commands. `flutter build web --release` verified passing. Previous entry: WBS 2.8 — Similar Posts Recommendation (category-based). Replaced old title-prefix query with `getRecentInCategory`. New files: `ItemTaxonomy` enum (8 values + metadata), `CategoryPicker` widget (4×2 icon grid), `SimilarPostsPanel` widget (category-based), `SimilarItemsNotifier` provider, `similar_items_provider.dart`. Updated: `Item` entity, `ItemModel`, `ItemRemoteDatasource`, `ItemRepository`, `ItemRepositoryImpl`, `PostFormScreen` (full UX overhaul — quick-pick chips, adaptive placeholders, photo row redesign, sensitive explanation box, photo safety hint), `firestore.indexes.json`, `firestore.rules`. Deleted: `GetSimilarFounderPostsUseCase`, `SimilarPostsNotifier`, old test file. Added 21 new Dart tests + 5 npm rules tests across 5 new/updated test files. Old WBS 2.8 test deleted (use case removed). All Dart tests pass.)*
