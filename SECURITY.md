# Security Model — Campus Lost & Found

WBS 5.2 — last updated 2026-05-15.

---

## Overview

This document describes the threat model, RBAC matrix, and operational security policies for the Campus Lost & Found platform. It is the authoritative reference for security decisions during code review and for onboarding new contributors.

---

## Actors & Trust Levels

| Actor | How they authenticate | Trust level |
|---|---|---|
| **Unauthenticated** | No session | Zero trust — all Firestore and Storage reads/writes denied |
| **Authenticated student** | Firebase Auth, `@mail.kmutt.ac.th` + OTP verified | Low trust — may read items, create their own posts and requests |
| **Poster** | Authenticated student who created a specific item | Medium trust — may edit/delete that item and approve/reject its requests |
| **Admin** | Authenticated student with `isAdmin: true` set manually in Firebase Console | Elevated trust — may access admin screens; `isAdmin` cannot be self-granted |

---

## Threat Model

| Threat | Mitigation | Where enforced |
|---|---|---|
| Unauthenticated data read/write | All Firestore and Storage rules require `request.auth != null` | `firestore.rules`, `storage.rules` |
| userId spoofing on item create | Rule checks `request.resource.data.userId == request.auth.uid` | `firestore.rules` — items create |
| Client-forged `createdAt` timestamp | Rule checks `request.resource.data.createdAt == request.time` | `firestore.rules` — items create, requests create, users create |
| Client-forged `editedAt` timestamp | Rule checks `editedAt == request.time` when the field is being set | `firestore.rules` — items update |
| Cross-user item edit/delete | Update/delete rules check `resource.data.userId == request.auth.uid` | `firestore.rules` — items update/delete |
| Self-granting admin role | `isAdmin` is blocked from updates by `diff().affectedKeys()` and the create rule stamps `isAdmin: false` | `firestore.rules` — users create/update |
| Requester self-approving their own request | Requests update RBAC: requester may only set `status = 'cancelled'`; poster may only set `status in ['approved', 'rejected']` | `firestore.rules` — requests update |
| Sensitive item re-classification | `isSensitive` and `expiresAt` are blocked from all client updates via `diff().affectedKeys()` | `firestore.rules` — items update |
| Secret answer exposure | Secret answers live in `/items/{id}/private/` readable only by the poster | `firestore.rules` — private sub-collection |
| Committed secrets (API keys, service accounts) | gitleaks scans every PR; build blocked on any finding | `.github/workflows/security.yml`, `.gitleaks.toml` |
| Dependency vulnerabilities | `dart pub outdated --mode=security` scans every PR; build blocked on High/Critical | `.github/workflows/security.yml` |
| Non-KMUTT email registration | Domain validated server-side before Firebase Auth call with anchored regex | `lib/features/auth/` — `SignUpUseCase` |

---

## Firestore RBAC Matrix

### `users/{userId}`

| Operation | Who | Conditions |
|---|---|---|
| Read | Any authenticated user | Needed to display poster names in the feed |
| Create | Self only | `uid == userId`; `emailVerified=false`; `isAdmin=false`; `createdAt == request.time` |
| Update | Self only | Cannot change `emailVerified`, `createdAt`, `isAdmin` |
| Delete | — | Not permitted client-side |

### `items/{itemId}`

| Operation | Who | Conditions |
|---|---|---|
| Read | Any authenticated user | — |
| Create | Authenticated user (self) | `userId == uid`; `createdAt == request.time`; `itemCategory` required and valid; sensitive item gate |
| Update | Poster only | Cannot change `isSensitive`, `expiresAt`, `userId`, `createdAt`; if `editedAt` is set it must equal `request.time` |
| Delete | Poster only | — |

### `items/{itemId}/private/{doc}` (secret answer)

| Operation | Who |
|---|---|
| Read + Write | Poster only |

### `items/{itemId}/requests/{requestId}`

| Operation | Who | Conditions |
|---|---|---|
| Create | Any authenticated user | `requesterId == uid`; `createdAt == request.time` |
| Read | Requester or Poster | — |
| Update (cancel) | Requester only | `status` field only; new value must be `'cancelled'` |
| Update (approve/reject) | Poster only | `status` field only; new value must be `'approved'` or `'rejected'` |
| Delete | — | Not permitted client-side |

### `otp_verifications/{uid}`, `mail/{docId}`, `policy_audit/{docId}`

All client access denied (`allow read, write: if false`). Written exclusively by Firebase Admin SDK / Cloud Functions.

---

## Secret & Credential Management

**What counts as a secret:** service account JSON files, Firebase Admin SDK private keys, Cloud Function environment variables (API tokens, SMTP credentials), any value that grants elevated server-side access.

**What is NOT a secret:** the Firebase web API key in `lib/config/firebase_options.dart`. This key is a public app identifier; security is entirely governed by the Firestore/Storage rules above. It is safe and intentional to commit it.

**gitleaks policy:**
- Every PR targeting `release` or `develop` runs `gitleaks/gitleaks-action@v2`.
- Any finding blocks the merge.
- `lib/config/firebase_options.dart` is in the allowlist (see `.gitleaks.toml`) to prevent false positives on the public Firebase web config.
- If a real secret is found: rotate it immediately, then add a false-positive allowlist entry only after rotation is confirmed.

**Server-side secrets** (Admin SDK, SMTP credentials) are stored exclusively in Firebase Functions config or GitHub Actions secrets — never in source code.

---

## Dependency Vulnerability Policy

Every PR runs:

```
dart pub outdated --mode=security --no-color
```

The CI step (`dependency-scan` job in `.github/workflows/security.yml`) fails the build if the output contains the word `high` or `critical` (case-insensitive).

**Remediation steps on a failing scan:**

1. Run `dart pub outdated --mode=security` locally to identify the affected package.
2. Run `dart pub upgrade <package>` to pull the patched version.
3. If a non-breaking upgrade is not available, evaluate whether the vulnerable code path is reachable in this app and document the risk.
4. Re-run the scan locally to confirm it passes before pushing.
