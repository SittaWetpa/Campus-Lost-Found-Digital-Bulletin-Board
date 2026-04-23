# CLAUDE.md — Campus Lost & Found

Project memory for Claude Code. Read this before every session.

---

## Project Overview

A Flutter mobile app for reporting and finding lost items on campus. Students post **Seeker Posts** (lost items) or **Founder Posts** (found items), browse a feed, send Claim Requests or Found Reports, and verify ownership via a Secret Question.

**Platforms:** Android and Web only. No iOS, no desktop.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter (Dart) |
| State | Riverpod 2.x with `riverpod_generator` |
| Routing | GoRouter with auth guards |
| Auth | Firebase Authentication — Email/Password, `@mail.kmutt.ac.th` only |
| Database | Cloud Firestore |
| File storage | Firebase Storage |
| Offline cache | Hive (with `hive_generator`) |
| Preferences | shared_preferences |
| REST API | Firebase Cloud Functions (Node.js 20, `asia-southeast1`) |
| OTP email | Firebase Extension — Trigger Email from Firestore |
| Error reporting | Firebase Crashlytics (Android only — never on Web) |
| Feature flags | Firebase Remote Config |
| Connectivity | connectivity_plus |

---

## Architecture — Clean Architecture, Feature-First

```
lib/
├── main.dart               # Firebase init, Hive init, Crashlytics, ProviderScope
├── app.dart                # MaterialApp.router placeholder (replaced by GoRouter in 4.3)
├── config/
│   ├── firebase_options.dart
│   └── router/app_router.dart
├── core/                   # Cross-cutting, no dependency on features/
│   ├── constants/
│   ├── theme/
│   ├── errors/             # Failures and exceptions
│   ├── utils/              # Validators, formatters
│   ├── network/            # Connectivity provider
│   ├── observability/      # AppLogger + Crashlytics wrapper
│   └── services/
│       ├── preference_service.dart
│       └── feature_flag_service.dart
├── features/
│   ├── auth/               # Login, Register, OTP Verification
│   ├── feed/               # Feed, Detail, Search
│   ├── post/               # Post Form, Similar Posts
│   ├── requests/           # Claim Request, Found Report
│   └── profile/            # Settings, Edit Profile, My Posts
└── shared/widgets/
```

Each feature follows this internal structure:
```
<feature>/
├── data/
│   ├── datasources/        # Firebase, Hive calls
│   ├── models/             # DTOs with fromJson/toJson + @HiveType if cached
│   └── repositories/       # Implements domain abstract
├── domain/
│   ├── entities/           # Pure Dart, no Firebase imports
│   ├── repositories/       # Abstract interfaces
│   └── usecases/           # One class per use case
└── presentation/
    ├── providers/           # Riverpod providers
    ├── screens/
    └── widgets/
```

---

## Layer Rules — Enforced, No Exceptions

- `presentation/` → depends on `domain/` only. Never import from `data/` directly.
- `domain/` → zero Flutter or Firebase imports. Pure Dart.
- `data/` → implements `domain/` repositories.
- `core/` and `shared/` → no imports from any `features/` directory.
- Cross-feature communication → through `domain/` entities or shared Riverpod providers only.

---

## Firestore Collections

| Collection | Owner WBS | Notes |
|---|---|---|
| `users/{uid}` | 0.2 | Profile: firstName, lastName, studentId, telephone, avatarUrl, emailVerified, createdAt |
| `items/{itemId}` | 2.1 | title, description, category (seeker/founder), status (active/resolved), location, contact, imageUrls, userId, createdAt, editedAt?, claimedBy?, secretQuestion?, secretAnswer? |
| `items/{itemId}/requests/{requestId}` | 2.4 | requesterId, requesterName, requesterContact, message, status (pending/approved/rejected/cancelled), createdAt, visitorAnswer? |
| `otp_verifications/{uid}` | 0.5 | code, expiresAt, attempts, createdAt |
| `mail/{docId}` | 0.5 | Watched by Firebase Extension to send OTP emails |

---

## Authentication Rules

- Email must end with `@mail.kmutt.ac.th` — reject all other domains with `InvalidDomainException` **before** calling Firebase Auth
- After register: send OTP → navigate to OTP Verification Screen
- After login: check `users/{uid}.emailVerified == true` → if false, navigate to OTP Verification Screen
- OTP: 6 digits, 10-minute expiry, max 5 attempts
- Error messages must be in **English**

---

## Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Files | snake_case | `item_repository_impl.dart` |
| Classes | PascalCase | `ItemRepositoryImpl` |
| Variables/methods | camelCase | `getItems()` |
| Riverpod providers | camelCase + `Provider` suffix | `currentUserProvider` |
| Firestore fields | camelCase | `createdAt`, `imageUrls` |
| Route paths | kebab-case | `/feed`, `/item/:id`, `/otp-verify` |
| Branch names | `<nickname>/feat/<feature-name>` | `film/feat/firebase-auth` |
| Commit messages | Conventional Commits | `feat(auth): add OTP verification` |

---

## Riverpod Conventions

- Use `@riverpod` annotation with `riverpod_generator` — never create providers manually
- Run `dart run build_runner watch` during development
- Keep providers in `presentation/providers/` of each feature
- Never put business logic in providers — delegate to use cases
- `currentUserProvider` lives in `features/auth/presentation/providers/`

---

## GoRouter Conventions

- All routes defined in `lib/config/router/app_router.dart`
- Auth guard: redirect unauthenticated users to `/login`
- OTP guard: redirect users with `emailVerified == false` to `/otp-verify`
- Route names as constants, not raw strings

---

## Firebase Crashlytics

- **Mobile only.** Always wrap Crashlytics calls with `if (!kIsWeb)`
- `AppLogger` in `core/observability/` is the only place that calls Crashlytics directly
- Debug builds: log to console only. Release builds: log to Crashlytics
- Never call `FirebaseCrashlytics.instance` directly outside `AppLogger`

---

## Feature Flags (Remote Config)

- All flags accessed via `FeatureFlagService` in `core/services/`
- Current flags:
  - `secret_question_enabled` (bool, default `true`) — gates WBS 2.10 Secret Question feature
- Never read Remote Config directly in UI — always go through `FeatureFlagService`

---

## DO NOT

- ❌ Import Firebase directly in `domain/` layer
- ❌ Call `FirebaseCrashlytics` outside `AppLogger`
- ❌ Call `FirebaseRemoteConfig` outside `FeatureFlagService`
- ❌ Use `setState` — use Riverpod
- ❌ Use `Navigator.push` — use GoRouter
- ❌ Hardcode strings in UI — use constants
- ❌ Accept non-`@mail.kmutt.ac.th` emails anywhere
- ❌ Add iOS or desktop platform code
- ❌ Commit secrets, API keys, or `google-services.json` to a public repo
- ❌ Use `StreamBuilder` for routing — GoRouter handles auth redirects
- ❌ Write business logic in `presentation/` — use cases belong in `domain/`

---

## Key Files to Know

| File | Purpose |
|---|---|
| `lib/main.dart` | Entry point — Firebase, Hive, Crashlytics init |
| `lib/config/firebase_options.dart` | Generated by `flutterfire configure` — do not edit manually |
| `lib/config/router/app_router.dart` | All routes + auth guards |
| `firestore.rules` | Firestore security rules |
| `storage.rules` | Storage security rules |
| `functions/index.js` | REST API endpoint (`GET /items`) |
| `SETUP.md` | Full setup guide from scratch |
| `README.md` | Project overview, team, branching strategy |

---

## WBS Reference

Full task breakdown is in `wbs_lost_found.md` and `wbs_dictionary.md`.
Quick map of features to WBS codes:

- Auth + OTP: 0.1, 0.2, 0.3, 0.5
- Feed + Detail: 1.2, 1.3, 2.2, 2.3
- Post Form + Similar Posts: 1.4, 2.6, 2.7, 2.8
- Request System: 2.4, 2.10
- Profile: 1.6, 1.7, 1.8
- REST API: 2.9
- Offline Cache: 2.11
- Observability: 2.12
- Feature Flags: 2.13
- Architecture: 4.1, 4.2, 4.3

---

*CLAUDE.md v4.1 — Campus Lost & Found Digital Bulletin Board*
