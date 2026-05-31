// WBS 3.1 — Android Build, Testing & Verification
//
// Static verification tests for the Android build configuration. These tests
// run as part of `flutter test` (no emulator, no device required) and gate
// the WBS 3.1 deliverable "Configure `google-services.json` for Android build"
// plus the manifest/plugin wiring needed for Firebase + WBS 2.16 push
// notifications + WBS 4.3 deep links to function on Android.
//
// The on-device smoke tests live in:
//   integration_test/wbs_3_1_android_smoke_test.dart
//
// ── Why these tests live here ────────────────────────────────────────────────
// WBS 3.1 is the final cross-platform quality gate before submission. Many of
// its deliverables are configuration files (Gradle plugins, AndroidManifest
// entries, google-services.json) that can be silently broken without any Dart
// code failing to compile. These tests catch that class of regression by
// reading the files directly and asserting on their contents — fast, hermetic,
// and reproducible on CI without an Android device attached.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WBS 3.1 — Android build configuration', () {
    // -----------------------------------------------------------------------
    // 01: android/app/build.gradle.kts applies the FlutterFire Gradle plugins
    // The Google Services plugin is what reads google-services.json at build
    // time; Crashlytics plugin uploads symbols. Both are required for the
    // WBS 0.x (auth) and WBS 2.12 (Crashlytics) features to work on Android.
    // -----------------------------------------------------------------------
    test('01 app/build.gradle.kts applies google-services and crashlytics plugins', () {
      final gradle = File('android/app/build.gradle.kts');
      expect(gradle.existsSync(), isTrue,
          reason: 'android/app/build.gradle.kts must exist for an Android build.');

      final contents = gradle.readAsStringSync();
      expect(contents, contains('com.google.gms.google-services'),
          reason: 'Google Services Gradle plugin must be applied so '
              'google-services.json is consumed at build time.');
      expect(contents, contains('com.google.firebase.crashlytics'),
          reason: 'Crashlytics Gradle plugin must be applied — WBS 2.12 '
              'depends on Crashlytics symbol upload on Android.');
      expect(contents, contains('dev.flutter.flutter-gradle-plugin'),
          reason: 'Flutter Gradle plugin must be applied last (after Android '
              'and Kotlin plugins) per the Flutter build contract.');
    });

    // -----------------------------------------------------------------------
    // 02: applicationId is the documented KMUTT namespace
    // The applicationId is what Firebase Console uses to identify the Android
    // app; mismatch with google-services.json is a common silent failure.
    // -----------------------------------------------------------------------
    test('02 applicationId matches the registered Firebase Android app', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('applicationId = "com.kmutt.campuslostfound.campus_lost_found"'),
          reason: 'applicationId must match the package name registered in '
              'Firebase Console; otherwise google-services.json lookup fails.');
    });

    // -----------------------------------------------------------------------
    // 03: AndroidManifest declares POST_NOTIFICATIONS (WBS 2.16)
    // Android 13+ requires this permission for FCM to display notifications.
    // Missing this permission is a silent failure — FCM token registers fine
    // but no notification ever shows on screen.
    // -----------------------------------------------------------------------
    test('03 AndroidManifest declares POST_NOTIFICATIONS permission (WBS 2.16)', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml');
      expect(manifest.existsSync(), isTrue,
          reason: 'android/app/src/main/AndroidManifest.xml is required.');

      final contents = manifest.readAsStringSync();
      expect(contents, contains('android.permission.POST_NOTIFICATIONS'),
          reason: 'POST_NOTIFICATIONS permission is required on Android 13+ '
              'for WBS 2.16 push notifications to display.');
    });

    // -----------------------------------------------------------------------
    // 04: AndroidManifest declares a deep-link intent filter (WBS 4.3)
    // GoRouter deep links on Android arrive via an Activity intent filter
    // with android:autoVerify="true" and a https scheme. Required so users
    // can open /item/{id} links from email/messages and land in the app.
    // -----------------------------------------------------------------------
    test('04 AndroidManifest declares a deep-link intent filter (WBS 4.3)', () {
      final contents = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

      expect(contents, contains('android.intent.action.VIEW'),
          reason: 'Deep-link intent filter requires action.VIEW.');
      expect(contents, contains('android.intent.category.BROWSABLE'),
          reason: 'Deep-link intent filter requires category.BROWSABLE so '
              'browsers and messaging apps can open the link.');
      expect(contents, contains('android:scheme="https"'),
          reason: 'Deep links use https scheme (App Links / Universal Links).');
    });

    // -----------------------------------------------------------------------
    // 05: MainActivity launchMode is singleTop
    // singleTop prevents stacking duplicate activities when a deep link or
    // notification is tapped while the app is already foregrounded — required
    // for the WBS 2.16 notification → Detail Screen flow to behave correctly.
    // -----------------------------------------------------------------------
    test('05 MainActivity uses singleTop launchMode', () {
      final contents = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(contents, contains('android:launchMode="singleTop"'),
          reason: 'singleTop avoids duplicate Activity instances when a deep '
              'link / notification opens the already-running app.');
    });

    // -----------------------------------------------------------------------
    // 06: google-services.json is present OR explicitly absent for the build
    // The file is the bridge between the Firebase Console project and the
    // Android app. It is gitignored intentionally — see CLAUDE.md "DO NOT
    // commit google-services.json to a public repo" — so we test the canonical
    // path and emit a clear "missing file" message instead of asserting
    // existsSync()==true, which would fail the suite on a fresh clone.
    //
    // This test is documentation-first: if the file IS present (developer
    // machine, CI with secret injection), it must be at the canonical path.
    // If the file is absent (fresh clone before `flutterfire configure`),
    // the test passes with a printed reminder.
    // -----------------------------------------------------------------------
    test('06 google-services.json — placement check (passes when absent, '
        'documents the required path)', () {
      final canonical = File('android/app/google-services.json');
      final misplacedAtRoot = File('android/google-services.json');

      // Hard failure: file lives in the WRONG place (a common copy-paste error).
      expect(misplacedAtRoot.existsSync(), isFalse,
          reason: 'google-services.json must be at android/app/, NOT at android/. '
              'The Google Services Gradle plugin only reads from android/app/.');

      // Soft check: report whether the file is present, do not fail.
      // On CI without the secret injected, this still passes.
      if (!canonical.existsSync()) {
        // ignore: avoid_print
        print('WBS 3.1 NOTE: android/app/google-services.json is absent. '
            'Run `flutterfire configure` before `flutter run` on Android, '
            'or inject the file via CI secret. (CLAUDE.md forbids committing it.)');
      }
    });

    // -----------------------------------------------------------------------
    // 07: Gradle wrapper is pinned (reproducible Android builds)
    // -----------------------------------------------------------------------
    test('07 Gradle wrapper distribution URL is pinned', () {
      final wrapper = File('android/gradle/wrapper/gradle-wrapper.properties');
      expect(wrapper.existsSync(), isTrue,
          reason: 'gradle-wrapper.properties must be committed so the Android '
              'build is reproducible across machines and CI.');

      final contents = wrapper.readAsStringSync();
      expect(contents, contains('distributionUrl='),
          reason: 'Gradle wrapper must pin a distributionUrl.');
      expect(contents, contains(RegExp(r'gradle-\d+\.\d+(\.\d+)?-')),
          reason: 'distributionUrl should reference a specific Gradle version, '
              'e.g. gradle-8.x-all.zip — not "latest".');
    });

    // -----------------------------------------------------------------------
    // 08: pubspec lists every Firebase / Hive / Riverpod dep referenced by
    // the Android build steps. Catches the case where someone removes a
    // dependency from pubspec but forgets to delete a Gradle plugin or
    // platform channel registration.
    // -----------------------------------------------------------------------
    test('08 pubspec.yaml declares Android-required Firebase + offline deps', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      // Firebase plugins active on Android
      expect(pubspec, contains('firebase_core:'), reason: 'firebase_core required.');
      expect(pubspec, contains('firebase_auth:'), reason: 'firebase_auth — WBS 0.1.');
      expect(pubspec, contains('cloud_firestore:'), reason: 'cloud_firestore — WBS 2.x.');
      expect(pubspec, contains('cloud_functions:'), reason: 'cloud_functions — WBS 0.5 OTP.');
      expect(pubspec, contains('firebase_storage:'), reason: 'firebase_storage — WBS 1.4 photos.');
      expect(pubspec, contains('firebase_crashlytics:'),
          reason: 'firebase_crashlytics — WBS 2.12 (Android-only at call sites).');
      expect(pubspec, contains('firebase_remote_config:'),
          reason: 'firebase_remote_config — WBS 2.13.');
      expect(pubspec, contains('firebase_messaging:'),
          reason: 'firebase_messaging — WBS 2.16 push notifications.');

      // Local storage on Android (file-backed Hive + shared_preferences)
      expect(pubspec, contains('hive:'), reason: 'hive — WBS 2.11 offline cache.');
      expect(pubspec, contains('hive_flutter:'), reason: 'hive_flutter — WBS 2.11.');
      expect(pubspec, contains('shared_preferences:'),
          reason: 'shared_preferences — WBS 2.5.');

      // Routing + state mgmt
      expect(pubspec, contains('go_router:'), reason: 'go_router — WBS 4.3 deep links.');
      expect(pubspec, contains('flutter_riverpod:'), reason: 'flutter_riverpod — WBS 4.2.');
    });

    // -----------------------------------------------------------------------
    // 09: namespace matches applicationId
    // Mismatch breaks R8 / minify in release builds.
    // -----------------------------------------------------------------------
    test('09 android namespace matches applicationId', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('namespace = "com.kmutt.campuslostfound.campus_lost_found"'),
          reason: 'namespace must match applicationId; mismatch causes '
              'R8 to drop the Application class in release builds.');
    });
  });

  // -------------------------------------------------------------------------
  // Manual / device-bound test cases listed in WBS 3.1 Deliverables.
  // These cannot run inside `flutter test` (require a real Android device or
  // emulator). They are listed here as skipped tests so the WBS 3.1
  // traceability matrix can point to a single Dart file and so they are
  // counted by `flutter test --machine` as documented-but-deferred work.
  // -------------------------------------------------------------------------
  group('WBS 3.1 — Manual Android device verification', () {
    test('M1 Full test suite passes on Android — flutter test exits with 0 failures', () {},
        skip: 'Run from repo root: flutter test. This single test is a sentinel '
            'for the WBS 3.1 deliverable "All tests passing".');

    test('M2 Coverage report generated — flutter test --coverage', () {},
        skip: 'Run from repo root: flutter test --coverage. Then commit '
            'coverage/lcov.info as evidence for WBS 3.1 submission.');

    test('M3 App launches on Android device or emulator — flutter run -d <android>', () {},
        skip: 'Manual test — requires Android device/emulator + '
            'android/app/google-services.json present.');

    test('M4 Core features verified on Android: auth, feed, post form, search, '
        'request flow (incl. cancel), recommendation panel, settings, local storage', () {},
        skip: 'Manual walkthrough — capture screenshots/screen recording as '
            'evidence per WBS 3.1 Deliverables.');

    test('M5 On-device smoke tests pass — '
        'flutter test integration_test/wbs_3_1_android_smoke_test.dart -d <android>', () {},
        skip: 'Run from repo root with an Android device attached. See the '
            'header of integration_test/wbs_3_1_android_smoke_test.dart.');
  });
}
