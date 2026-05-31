# OBSERVABILITY.md — Campus Lost & Found

Logging and crash reporting conventions for WBS 2.12.

---

## Platform Scope

| Platform | Sink | Condition |
|---|---|---|
| Android (release) | Firebase Crashlytics | `!kIsWeb && kReleaseMode` |
| Android (debug) | Console (`debugPrint`) | `!kIsWeb && !kReleaseMode` |
| Web (any mode) | Console (`debugPrint`) | `kIsWeb` |

Crashlytics is **never** called on Web. The `_active` guard in `CrashlyticsLoggerImpl` enforces this unconditionally.

---

## Log Levels

| Level | Method | Crashlytics action |
|---|---|---|
| `info` | `AppLogger.info(...)` | Breadcrumb only (release+mobile) |
| `warn` | `AppLogger.warn(...)` | Breadcrumb only (release+mobile) |
| `error` | `AppLogger.error(...)` | Breadcrumb + `recordError(fatal: false)` |

Fatal crashes (unhandled Flutter errors, zone errors on mobile) are captured automatically via the hooks in `main.dart` — do **not** call `AppLogger.error` for those.

---

## Usage

```dart
// Info — navigation, lifecycle events
AppLogger.info('Feed loaded', tag: 'FeedScreen');

// Warn — recoverable degraded state
AppLogger.warn('Remote Config fetch timed out', tag: 'FeatureFlagService');

// Error — caught exception that should be investigated
AppLogger.error(
  'Failed to submit claim request',
  tag: 'SubmitClaimRequestUseCase',
  error: e,
  stackTrace: st,
  extras: {'itemId': itemId},
);
```

### Tag convention

Use `ClassName` as the tag — e.g. `'FeedScreen'`, `'ItemRepositoryImpl'`, `'AuthProvider'`. This maps directly to the class emitting the log, making Crashlytics breadcrumbs filterable.

### Session context

`AppLogger.setUserContext` is called twice:
1. At app start in `main.dart` with `userId: 'anonymous'` before auth resolves.
2. After the user signs in (via `ref.listen(currentUserProvider, ...)` in `app.dart`) with the real `uid`.

Custom keys attached to every Crashlytics session:
- `userId` — Firebase Auth UID (or `'anonymous'`)
- `appVersion` — app version string
- `platform` — `'android'` or `'web'`
- `currentRoute` — updated on every navigation by `AppLoggerRouteObserver`

---

## Breadcrumb Format

```
[LEVEL][Tag] message
```

Example: `[ERROR][SubmitClaimRequestUseCase] Failed to submit claim request`

---

## Viewing Crashes

1. Open [Firebase Console → Crashlytics](https://console.firebase.google.com) and select the Campus Lost & Found project.
2. Filter by `currentRoute` or `userId` custom keys to narrow down sessions.
3. Non-fatal errors appear under **Non-fatals** tab within ~5 minutes of being recorded.
4. Test crashes from the **Debug Menu** (Settings → Developer → Debug Menu, admin only) appear under the same tab.

---

## Testing

```bash
flutter test test/unit/observability/app_logger_test.dart
```

- **U1** — `AppLogger.error()` → `repo.log(event)` with `event.level == LogLevel.error`
- **U2** — `AppLogger.info()` → `repo.log(event)` with `event.level == LogLevel.info`, no error-level call

Manual verification (release APK on Android):
1. Sign in as an admin account.
2. Go to Settings → Developer → Debug Menu.
3. Tap **Trigger test non-fatal** → event appears in Crashlytics within ~5 min.
4. Tap **Trigger fatal crash** → confirm app terminates and crash appears in Crashlytics.
