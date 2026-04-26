// WBS 2.1 — Firebase Project & Firestore Schema
//
// Covers the three test cases listed in wbs_dictionary.md §2.1 Testing:
//
//   1. Manual test: Firebase.initializeApp() succeeds on launch
//   2. Firestore rules test: unauthenticated read on `items` — access denied
//   3. Firestore rules test: authenticated read on `items` — access allowed
//
// ─────────────────────────────────────────────────────────────────────────────
// WHY THIS FILE CONTAINS NO RUNNABLE FIREBASE TESTS
// ─────────────────────────────────────────────────────────────────────────────
// `flutter test` executes on the Dart VM without a Flutter host application.
// Firebase Flutter packages (firebase_core, firebase_auth, cloud_firestore) rely
// on native platform channels which are NOT available in the VM test environment.
// Calling Firebase.initializeApp() from `flutter test` always throws a
// PlatformException("channel-error") regardless of emulator availability.
//
// The correct test medium for Firestore security rules is the JavaScript
// @firebase/rules-unit-testing library, which speaks directly to the emulator
// over HTTP and fully enforces rule evaluation.
//
// ─────────────────────────────────────────────────────────────────────────────
// WHERE THE REAL TESTS LIVE
// ─────────────────────────────────────────────────────────────────────────────
// test/firestore_rules/rules.test.js  ← covers all three WBS 2.1 test cases.
//
// HOW TO RUN
// ----------
//   Step 1 — start the Firebase Emulator (from the project root):
//     firebase emulators:start --only firestore,auth
//
//   Step 2 — run the rules tests:
//     cd test/firestore_rules && npm install && npm test
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WBS 2.1 — Firestore rules (see test/firestore_rules/rules.test.js)', () {
    // ── Test case 1 ────────────────────────────────────────────────────────
    test(
      'Manual: Firebase.initializeApp() succeeds on launch '
      '— verified by running the app on a device with the emulator active',
      () {},
      skip:
          'Manual test — launch the app on Android/Web with the emulator '
          'running and confirm no Firebase init error appears in the console.',
    );

    // ── Test case 2 ────────────────────────────────────────────────────────
    test(
      'Firestore rules: unauthenticated read on items is denied '
      '— run: cd test/firestore_rules && npm test',
      () {},
      skip:
          'Requires Firebase Emulator + Node.js. '
          'Run: cd test/firestore_rules && npm install && npm test',
    );

    // ── Test case 3 ────────────────────────────────────────────────────────
    test(
      'Firestore rules: authenticated read on items is allowed '
      '— run: cd test/firestore_rules && npm test',
      () {},
      skip:
          'Requires Firebase Emulator + Node.js. '
          'Run: cd test/firestore_rules && npm install && npm test',
    );
  });
}
