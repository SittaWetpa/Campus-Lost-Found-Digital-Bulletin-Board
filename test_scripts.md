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
| `cd test/firestore_rules && npm test` | Firestore security rules (Node.js) | After editing `firestore.rules` |

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
│   └── post/post_form_screen_test.dart          ← WBS 1.4 / 2.10
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
| 1.3 | Item detail screen | — | Widget | ⬜ not yet written |
| 1.4 | Post form screen (validation, submission, "Use my number" toggle, Photo Safety Case 1 + 2 via ImagePickerPlatform mock) | `test/widget/post/post_form_screen_test.dart` | Widget | ✅ 10 tests (+ 1 skipped — see note) |
| 1.4 | PostDraft entity (factories + sensitive-item invariants) | `test/unit/post/post_draft_test.dart` | Unit | ✅ 21 tests |
| 1.5 | Search bar widget | — | Widget | ⬜ not yet written |
| 1.6 | Settings & profile screen | `test/features/profile/presentation/screens/settings_screen_test.dart` | Widget | ✅ 4 tests |
| 1.7 | My posts screen | — | Widget | ⬜ not yet written |
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
| 2.5 | Local storage (preferences) | — | Unit | ⬜ not yet written |
| 2.6 | Post edit (UpdateItemUseCase + form edit-mode flow) | `test/unit/post/update_item_use_case_test.dart` | Unit | ✅ 1 test |
| 2.7 | Post delete (DeleteItemUseCase) | `test/unit/post/delete_item_use_case_test.dart` | Unit | ✅ 1 test |
| 2.8 | Similar posts recommendation (debounced 500 ms title-prefix search) | `test/unit/post/get_similar_founder_posts_use_case_test.dart` | Unit | ✅ 7 tests |
| 1.4 / 2.6 | CreateItemUseCase (post creation, sensitive-item null-handling) | `test/unit/post/create_item_use_case_test.dart` | Unit | ✅ 8 tests |
| 2.9 | REST API | — | Manual | ⬜ not yet written |
| 2.10 | Secret question (Photo Safety Case 2 in post form widget tests) | _see WBS 1.4 row above_ | Widget | ✅ covered |
| 2.11 | Hive offline-first cache | — | Unit + Widget | ⬜ not yet written |
| 2.12 | Crashlytics & logging | — | Unit | ⬜ not yet written |
| 2.13 | FeatureFlagService (Remote Config wrapper, hardcoded defaults) | `test/unit/post/post_draft_test.dart` (covered indirectly via secretQuestionEnabled gating) | Unit | ⏭️ direct test pending |
| 2.14 | Sensitive Item entity invariants (source / isSensitive / expiresAt) | `test/unit/feed/item_entity_test.dart` | Unit | ✅ 14 tests |
| 2.15 | UploadPostPhotosUseCase (3-photo cap, storage upload) | `test/unit/post/upload_post_photos_use_case_test.dart` | Unit | ✅ 5 tests |
| 2.15 | QR walk-in web form | — | Widget | ⬜ not yet written |
| 2.16 | Push notifications | — | Unit + Widget | ⬜ not yet written |

---

### Phase 3.0 — Cross-Platform
Run: `flutter test --coverage` and `flutter drive --target=test_driver/app.dart -d chrome`

| WBS | Description | Test file | Type | Status |
|---|---|---|---|---|
| 3.1 | Android build & verification | Full suite via `flutter test` | All | ⬜ pending full suite |
| 3.2 | Web build & verification | Full suite on Chrome via `flutter drive` | Integration | ⬜ not yet written |

---

### Phase 4.0 — Enterprise Architecture
Run: `flutter test test/unit/router/ test/widget/`

| WBS | Description | Test file | Type | Status |
|---|---|---|---|---|
| 4.3 | Route constants | `test/unit/router/app_routes_test.dart` | Unit | ✅ 33 tests |
| 4.3 | Auth redirect guards | `test/widget/auth/router_redirect_test.dart` | Widget | ✅ 21 tests |
| 4.1 | Clean architecture skeleton | — | Unit | ⬜ not yet written |
| 4.2 | Riverpod state management | — | Unit + Widget | ⬜ not yet written |

---

### Phase 5.0 — Quality Gates
Run: `flutter test` (accessibility guidelines are asserted inside widget tests)

| WBS | Description | Test file | Type | Status |
|---|---|---|---|---|
| 5.1 | Accessibility (WCAG 2.2 AA) | — | Widget | ⬜ not yet written |
| 5.2 | Security & dependency scans | CI workflow + Firestore rules | Rules + CI | ⬜ not yet written |

---

## Coverage Summary

Run `flutter test --coverage` then open `coverage/lcov.info` with `genhtml` or the VS Code Coverage Gutters extension.

| Phase | Tests written | Tests passing |
|---|---|---|
| 0.0 Auth | 55 | 55 |
| 1.0 Flutter UI | 64 | 64 |
| 2.0 Data Layer | 215 + 9 (npm) | 224 |
| 3.0 Cross-Platform | 0 | — |
| 4.0 Architecture | 34 | 34 |
| 5.0 Quality Gates | 0 | — |
| **Total** | **368 Dart + 9 npm** | **376 passing + 9 npm** |

> Phase totals add to 368; `flutter test` reports 376 passing + 4 skipped (manual integration placeholder + WBS 1.4-04 photo-cap). The ~8-test discrepancy is accounting drift — some files cover multiple WBS rows. **`flutter test` is the source of truth.**

---

*Last updated: 2026-05-02 (post-PR-#10 hardening — added 2 widget tests for Photo Safety Guard Case 1 by mocking `ImagePickerPlatform.instance`. WBS 1.4 widget coverage is now 10 active tests. Only WBS 1.4-04 remains skipped at widget level, covered at unit level by `upload_post_photos_use_case_test.dart`.)*
