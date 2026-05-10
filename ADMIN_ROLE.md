# Admin Role — WBS 2.18

The Flutter app has two admin-only screens (Settings → Developer):

- **Remote Config viewer** (`/admin/remote-config`) — read-only display of currently fetched Remote Config values plus a "Fetch & activate" trigger (WBS 2.13)
- **Rollback Plan** (`/admin/rollback-plan`) — interactive runbook mirroring `ROLLBACK_PLAN.md`

Access is gated by a single boolean field on the user document.

---

## Field

```
users/{uid}.isAdmin : bool   // default false
```

- New accounts are written with `isAdmin: false` (see `FirestoreUserDatasource.createUser`).
- Firestore rules block any client from setting or modifying `isAdmin` on their own document or anyone else's. The only writer is the Firebase Console (Admin SDK, which bypasses rules).
- The `isAdmin()` rules helper (top of `firestore.rules`) is available for any future admin-gated reads or writes.

---

## Granting admin

1. Open Firebase Console → select the project → **Firestore Database**.
2. Navigate to the `users` collection and locate the target user's document by `uid`. (The user's UID is shown on their Firebase Auth → Users row, and matches their Firestore doc ID.)
3. Click **Add field**:
   - Field name: `isAdmin`
   - Type: `boolean`
   - Value: `true`
4. **Save**.
5. Have the user kill and reopen the app (or wait for the Firestore stream listener to push the change — the user's Settings screen will show the **DEVELOPER** section within a second or two).

That user can now reach `/admin/remote-config` and `/admin/rollback-plan`. The route guard in `lib/config/router/app_router.dart` checks `currentUser.isAdmin` on every navigation.

---

## Revoking admin

Same path — set `isAdmin` to `false` (or delete the field). The Settings → Developer section disappears on the next Firestore snapshot, and any in-flight admin route is redirected to `/feed` with the snackbar **"Admin access required"**.

---

## Who should be an admin?

Keep the pool small. Recommended: tech lead and one on-call backup. Admins can:

- See the live Remote Config values without opening the Firebase Console.
- Trigger an immediate `fetchAndActivate()` from the device.
- Walk through the Rollback Plan runbook with an interactive checklist.

Admins **cannot** edit Remote Config from inside the app — Remote Config writes still happen exclusively in the Firebase Console. The viewer is read-only by design (no Cloud Function with Remote Config admin credentials, no risk of a stolen admin device flipping flags).

---

## Verifying

After granting:

- Sign in as the user.
- Navigate to **Settings**. A **DEVELOPER** section card with two rows ("Remote Config", "Rollback Plan") should appear above Sign out.
- Tap **Remote Config** → the viewer renders all four flags with their current values.
- Tap **Rollback Plan** → the runbook renders with a status banner reflecting `secret_question_enabled`.

After revoking, re-open Settings — the **DEVELOPER** card is gone. Attempting to navigate to `/admin/remote-config` directly redirects to `/feed`.
