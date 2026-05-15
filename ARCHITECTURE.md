# Architecture — Campus Lost & Found

Clean Architecture, Feature-First. This document is the authoritative reference for layer rules, directory structure, and cross-cutting conventions. Two custom lint rules enforce the most critical constraints automatically.

---

## Layer Rules (enforced, no exceptions)

| From | May import | Must NOT import |
|---|---|---|
| `presentation/` | `domain/` entities, use cases, Riverpod providers | `data/` directly |
| `domain/` | Pure Dart only | Firebase, Flutter, `data/`, `presentation/` |
| `data/` | `domain/` repositories + entities | `presentation/` |
| `core/` & `shared/` | Dart + Flutter SDK | Any `features/` directory |

Cross-feature communication happens through `domain/` entities or shared Riverpod providers in `features/auth/presentation/providers/`. Never import a sibling feature's `data/` or `presentation/` layer.

---

## Directory Structure

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── firebase_options.dart
│   └── router/app_router.dart          # All routes + auth guards
├── core/                               # No features/ imports ever
│   ├── constants/
│   ├── theme/
│   ├── errors/                         # Failure, Exception base classes
│   ├── utils/
│   ├── network/
│   ├── observability/                  # AppLogger (only place calling Crashlytics)
│   └── services/
│       ├── preference_service.dart
│       └── feature_flag_service.dart   # Only place calling RemoteConfig
├── features/
│   ├── auth/
│   ├── feed/
│   ├── post/
│   ├── requests/
│   └── profile/
└── shared/widgets/
```

Each feature is internally structured as:

```
<feature>/
├── data/
│   ├── datasources/    # Firebase + Hive calls only
│   ├── models/         # DTOs — fromMap/toMap, @HiveType if cached
│   └── repositories/   # Implements domain abstract interface
├── domain/
│   ├── entities/       # Pure Dart — no Firebase, no Flutter
│   ├── repositories/   # Abstract interfaces
│   └── usecases/       # One public class per use case
└── presentation/
    ├── providers/       # Riverpod @riverpod — delegates to use cases
    ├── screens/
    └── widgets/
```

---

## Enforced Lint Rules

Two custom lint rules in `tools/domain_lints/` run via `custom_lint`:

| Rule | What it catches |
|---|---|
| `no_firebase_in_domain` | Any import of `cloud_firestore`, `firebase_auth`, `firebase_storage`, `firebase_core`, `firebase_crashlytics`, `firebase_messaging`, `firebase_remote_config`, or `cloud_functions` inside a `domain/` file |
| `no_flutter_in_domain` | Any import of `package:flutter/…` inside a `domain/` file |

Run locally:

```bash
dart run custom_lint
```

Both rules fire on any file whose path contains `/domain/`. Violations are also surfaced inline in VS Code and IntelliJ when the `custom_lint` analyzer plugin is active.

---

## Key Singletons

| Concern | Owner | Rule |
|---|---|---|
| Error reporting | `core/observability/AppLogger` | Only file allowed to call `FirebaseCrashlytics`. Guard with `if (!kIsWeb)`. |
| Feature flags | `core/services/FeatureFlagService` | Only file allowed to call `FirebaseRemoteConfig`. |
| Auth state | `features/auth/presentation/providers/auth_provider.dart` | Shared across features via provider. |
| Current user profile | `features/auth/presentation/providers/user_provider.dart` | Shared across features via provider. |

---

## Riverpod Conventions

- Use `@riverpod` annotation — never create providers manually.
- Providers live in `presentation/providers/` of their feature.
- Business logic belongs in domain use cases, not in providers.
- `currentUserProvider` is the single source of truth for logged-in user identity.

---

## GoRouter Conventions

- All routes defined in `lib/config/router/app_router.dart`.
- Auth guard: unauthenticated → `/login`.
- OTP guard: `emailVerified == false` → `/otp-verify`.
- Navigation: always `context.push()` / `context.go()` — never `Navigator.push()`.

---

## Platform Targets

Android and Web only. No iOS, no desktop. Crashlytics is mobile-only; always guard with `if (!kIsWeb)`.
