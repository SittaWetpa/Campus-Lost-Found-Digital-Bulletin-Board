// WBS 2.4.1 — Request Resubmit Policy: end-to-end integration test.
//
// Covers the integration test case listed in wbs_dictionary.md §2.4.1 Testing:
//
//   "Integration test combining client-side canResubmit and Firestore-side
//    enforcement (Cloud Function trigger) — verify a 4th claim request on a
//    Secret Question post is rejected end-to-end."
//
// ─────────────────────────────────────────────────────────────────────────────
// WHY THIS FILE CONTAINS NO RUNNABLE FIREBASE TESTS
// ─────────────────────────────────────────────────────────────────────────────
// `flutter test` runs on the Dart VM without platform channels, so
// firebase_core / cloud_firestore cannot connect to a real or emulated
// Firebase project from inside a unit-test process.
//
// The end-to-end check requires:
//   1. Firebase Emulator (firestore + functions) running locally.
//   2. The Flutter app launched in integration_test mode against the emulator.
//   3. The `onRequestCreatePolicyCheck` Cloud Function deployed/loaded.
//
// ─────────────────────────────────────────────────────────────────────────────
// HOW TO RUN
// ----------
//   Step 1 — start the Firebase Emulator:
//     firebase emulators:start --only firestore,functions,auth
//
//   Step 2 — seed an item document with secretQuestion = 'Q?'
//            and 3 rejected claim requests by visitor 'uid-test'.
//
//   Step 3 — from the Flutter app (debug build pointed at the emulator):
//            sign in as 'uid-test', open the seeded item's Detail Screen.
//            Verify the Submit button is disabled and the banner reads
//            "You can no longer submit a request on this post."
//
//   Step 4 — directly write a 4th request via the Firestore SDK
//            (bypassing the disabled UI). Within ~2 seconds the trigger
//            should delete the doc and write an entry to `policy_audit/`.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WBS 2.4.1 — Resubmit policy end-to-end', () {
    test(
      'Integration: 4th claim request on a Secret Question post is blocked '
      '— manual run against Firebase Emulator',
      () {},
      skip:
          'Requires Firebase Emulator + integration_test runner. '
          'Run: firebase emulators:start --only firestore,functions,auth, '
          'then exercise the seeded scenario described in this file.',
    );
  });
}
