# CROSS_PLATFORM.md — Campus Lost & Found
## WBS 3.2 — Web Build, Testing & Verification

**Supported platforms:** Android · Web  
**Explicitly excluded:** iOS, macOS, Windows, Linux (see CLAUDE.md)

---

## Build Verification

| Command | Status | Notes |
|---|---|---|
| `flutter build web --release` | ✅ Zero errors | `build/web/` generated; WASM dry-run also passes |
| `flutter build apk --release` | ✅ Verified (WBS 3.1) | APK generated for Android |

---

## Web Configuration Checklist

| Item | Status | Detail |
|---|---|---|
| `flutterfire configure` (Web) | ✅ | `firebase_options.dart` includes Web SDK config |
| `image_picker_for_web` in pubspec.yaml | ✅ | `image_picker_for_web: ^3.0.5` |
| Firebase Storage CORS | ✅ | `cors.json` configured; apply with `gsutil cors set cors.json gs://campus-lost-found-e58a7.firebasestorage.app` |
| `<base href>` in `web/index.html` | ✅ | Set to `$FLUTTER_BASE_HREF` — resolved at build time via `--base-href` flag |
| GoRouter deep links on Web | ✅ | `MaterialApp.router` + `<base href>` — browser back/forward & URL-bar navigation work |
| Hive offline cache on Web | ✅ | `hive_flutter` automatically uses IndexedDB as the backend on Web |
| `shared_preferences` on Web | ✅ | Uses `localStorage` on Web automatically |

---

## Feature Parity Matrix — Android × Web

| Feature | Android | Web | Notes |
|---|---|---|---|
| **Authentication** | | | |
| Email/Password sign-in (`@mail.kmutt.ac.th`) | ✅ | ✅ | `firebase_auth_web` |
| Email OTP verification | ✅ | ✅ | Cloud Functions callable |
| Auth state persistence across restarts | ✅ | ✅ | Firebase Auth SDK handles both |
| GoRouter auth guard redirect | ✅ | ✅ | `currentUserProvider` stream |
| **Feed & Search** | | | |
| Real-time item feed (Firestore stream) | ✅ | ✅ | `cloud_firestore_web` |
| Keyword search | ✅ | ✅ | |
| Active/Resolved filter | ✅ | ✅ | |
| Walk-in badge (`source == qr_walk_in`) | ✅ | ✅ | |
| Offline cache (Hive) + offline banner | ✅ | ✅ | Hive → RocksDB (Android) / IndexedDB (Web) |
| **Item Detail** | | | |
| Full detail view (all fields) | ✅ | ✅ | |
| "Edited · [time]" label | ✅ | ✅ | |
| Poster controls (edit / delete) | ✅ | ✅ | |
| Sensitive item banner + security contact | ✅ | ✅ | |
| **Post Form** | | | |
| Create Seeker / Founder post | ✅ | ✅ | |
| Photo upload (up to 3) | ✅ | ✅ | Android: native picker · Web: `image_picker_for_web` (browser file picker) |
| Category picker (8 categories) | ✅ | ✅ | |
| Similar Posts panel | ✅ | ✅ | |
| Secret Question fields | ✅ | ✅ | Remote Config gated |
| Sensitive item selector | ✅ | ✅ | |
| Photo Safety Warning dialog | ✅ | ✅ | |
| **Request System** | | | |
| Claim Request submission | ✅ | ✅ | |
| Found Report submission + optional photo | ✅ | ✅ | |
| Approve / Reject / Cancel requests | ✅ | ✅ | |
| Resubmit policy (cooldown / permanent block) | ✅ | ✅ | |
| **Profile & Settings** | | | |
| View profile (name, email, student ID, telephone) | ✅ | ✅ | |
| Edit profile (name, telephone) | ✅ | ✅ | |
| Avatar upload | ✅ | ✅ | Firebase Storage CORS required on Web |
| Local preferences (theme, notifications toggle) | ✅ | ✅ | `localStorage` on Web |
| My Posts screen | ✅ | ✅ | |
| Sign out | ✅ | ✅ | |
| **Admin Screens (WBS 2.18)** | | | |
| Remote Config viewer (read-only) | ✅ | ✅ | Admin role gated |
| Rollback Plan screen | ✅ | ✅ | Admin role gated |
| Debug menu / test crash | ✅ | ⚠️ | Test fatal crash button is a no-op on Web (Crashlytics disabled) |
| **Notifications** | | | |
| FCM token registration | ✅ | ⚠️ | Web FCM requires `firebase-messaging-sw.js` service worker in `web/`; not yet added — web push is pending |
| Push notification delivery | ✅ | ⚠️ | Same as above |
| In-app notification list screen | ✅ | ✅ | |
| **Error Reporting** | | | |
| Firebase Crashlytics | ✅ | ❌ | **Mobile only.** All Crashlytics call sites are guarded with `if (!kIsWeb)`. Web errors go to `AppLogger` → console only |
| AppLogger (console) | ✅ | ✅ | Debug builds only for both platforms |
| **Feature Flags** | | | |
| Firebase Remote Config fetch | ✅ | ✅ | `firebase_remote_config_web` |
| `secret_question_enabled` flag | ✅ | ✅ | |

---

## Deliberate Platform Differences

### 1. Crashlytics — Android only
Firebase Crashlytics does not support Web. All error-capture code in `lib/main.dart` and `lib/core/observability/` is guarded with `kIsWeb`:
```dart
if (!kIsWeb) {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  ...
}
```
Web uncaught errors are logged to `AppLogger` (console output). See `OBSERVABILITY.md`.

### 2. Photo picker — browser file dialog vs. native picker
On Android, `image_picker` opens the native media picker. On Web, `image_picker_for_web` opens the browser's `<input type="file">` dialog. Behaviour and UX differ but both support selecting up to 3 images and uploading to Firebase Storage. The Storage bucket must have CORS configured (see `cors.json`).

### 3. FCM Web push — service worker not yet configured
FCM on Web requires a `firebase-messaging-sw.js` service worker in `web/` with the VAPID public key. This has not been added in the current sprint. Web users will not receive push notifications. The `NotificationService.registerToken()` call is a no-op on Web until the service worker is added.

### 4. Hive storage backend
`hive_flutter` automatically uses **IndexedDB** as the Hive box backend on Web and **RocksDB** (via native FFI) on Android. The offline-first cache behaviour is identical from the app's perspective.

### 5. Screen layout — mobile-first
The current UI is designed for mobile viewport (≤ 480 px width). On wide Web viewports the layout stretches. No responsive breakpoints have been implemented. This is an accepted limitation for the current sprint.

---

## Firebase Storage CORS

The `cors.json` at the repo root allows the web origin to make Storage requests:

```json
[
  {
    "origin": [
      "http://localhost:*",
      "https://campus-lost-found-e58a7.web.app",
      "https://campus-lost-found-e58a7.firebaseapp.com"
    ],
    "method": ["GET", "POST", "PUT", "DELETE"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Authorization", "x-goog-resumable"]
  }
]
```

To apply (one-time setup, requires `gsutil`):
```bash
gsutil cors set cors.json gs://campus-lost-found-e58a7.firebasestorage.app
```

---

## Integration Test Commands

```bash
# Smoke tests — no Firebase Emulator required (unauthenticated paths only)
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/wbs_3_2_web_smoke_test.dart \
  -d chrome

# Alternative modern runner (Flutter 3.x)
flutter test integration_test/wbs_3_2_web_smoke_test.dart -d chrome

# Full Dart test suite (all unit + widget tests — does not require Chrome)
flutter test --coverage
```

**Chromedriver version pinning:** Install chromedriver matching your installed Chrome version. Download from https://googlechromelabs.github.io/chrome-for-testing/. Add to `PATH` before running `flutter drive`.

---

## Manual Verification Steps

These steps must be performed manually by a developer with access to a real Firebase project or Local Emulator:

| # | Step | Expected result | Platform |
|---|---|---|---|
| M1 | Sign in with `@mail.kmutt.ac.th` test account on Chrome | Redirected to Feed screen | Web |
| M2 | Upload a photo on the Post Form in Chrome | Photo appears in Firebase Storage under `posts/` path | Web |
| M3 | Open a deep link `/item/{id}` in a new browser tab (authenticated) | Detail Screen loads with the correct item | Web |
| M4 | Open a deep link `/item/{id}` in a new browser tab (unauthenticated) | Login screen shown; after sign-in, navigates to the item | Web |
| M5 | Side-by-side: Android emulator + Chrome, same Firestore data | Feed renders same items in same order | Both |
| M6 | Toggle offline (DevTools → Network → Offline) after Feed loads | Offline banner visible; cached items remain | Web |
| M7 | Submit a Claim Request in Chrome | Poster receives FCM notification (Android only until SW added) | Web → Android |
| M8 | Admin user navigates to `/admin/remote-config` | Remote Config viewer renders with current values | Web |

---

*Last updated: 2026-05-15 (WBS 3.2 — Web Build, Testing & Verification)*
