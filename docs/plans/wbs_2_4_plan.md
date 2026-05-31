# Plan Mode Transcript — WBS 2.4 Request & Approval System

> Evidence artifact for WBS 6.1 (see `ORCHESTRATION.md` → "Plan Mode").
> Captured before execution; the plan was reviewed and approved, then executed
> step by step via the architect → flutter_engineer → qa_engineer flow.

**Mode:** Plan Mode (read-only research, no edits)
**Task given to Claude Code:**
> Implement WBS 2.4 — the Request & Approval System. A visitor on a Founder Post
> sends a **Claim Request**; a visitor on a Seeker Post sends a **Found Report**.
> The poster can approve / reject; the requester can cancel. Status lifecycle:
> pending → approved | rejected | cancelled. Follow Clean Architecture and the
> layer rules in `CLAUDE.md`. No Firebase in `domain/`.

---

## Phase A — Research (read-only)

Steps taken before proposing any change:

1. Read `CLAUDE.md` — layer rules (`presentation → domain` only; `domain` pure
   Dart), Firestore collections table, naming conventions, testing rules.
2. Read `wbs_dictionary.md` WBS 2.4 — the request sub-collection schema
   (`items/{itemId}/requests/{requestId}`: requesterId, requesterName,
   requesterContact, message, status, createdAt) and the listed test cases.
3. Grepped the existing feed feature for the established repository / datasource /
   provider triplet pattern to mirror (`item_remote_datasource.dart`,
   `item_repository_impl.dart`, `item_provider.dart`).
4. Read `firestore.rules` to understand the current ownership model so the new
   sub-collection rules slot in consistently.

**Findings / assumptions surfaced:**
- Requests live in a **sub-collection** under the item, not a top-level
  collection — keeps ownership queries simple and rules scoped to the parent.
- Two entry flows share one entity (`ItemRequest`) but differ by post category:
  Claim Request (Founder Post) vs Found Report (Seeker Post). One entity, two
  use cases, two screens.
- RBAC split: requester may only **cancel**; poster may only **approve/reject**.
  This must be enforced in Firestore rules, not just the UI.
- Ambiguity raised: should approving a request auto-resolve the item? Decision
  deferred to poster action (out of 2.4 scope) — noted, not assumed silently.

---

## Phase B — Proposed decomposition (the plan)

Ordered, layer-by-layer, smallest reviewable steps first:

1. **Domain entity** — `features/requests/domain/entities/item_request.dart`:
   `ItemRequest` (+ `RequestStatus` enum). Pure Dart, `copyWith`, no Firebase.
2. **Domain repository interface** —
   `features/requests/domain/repositories/item_request_repository.dart`:
   `submitRequest`, `approveRequest`, `rejectRequest`, `cancelRequest`,
   `watchMyRequestForItem`, `hasPendingRequests`.
3. **Use cases** (one class each) —
   `submit_claim_request.dart`, `submit_found_report.dart`,
   `approve_request.dart`, `reject_request.dart`, `cancel_request.dart`.
   Validation (e.g. domain rules) lives here, never in providers.
4. **Data layer** — `item_request_remote_datasource.dart` (Firestore sub-collection
   CRUD + batched status writes) and `item_request_repository_impl.dart` mapping
   model ↔ entity and wrapping errors in `RequestFailure`.
5. **Presentation** — `item_request_provider.dart` (riverpod codegen) and the
   Claim Request / Found Report screens + the action buttons on the Detail screen.
6. **Firestore rules** — sub-collection create/update rules enforcing the RBAC
   split and field immutability.
7. **Tests** (qa_engineer) — use-case unit tests, repository tests
   (batch approve/reject/cancel, `hasPendingRequests`, `watchMyRequestForItem`),
   widget tests for both screens, and rules tests.

**Verification / success criteria:**
- `flutter analyze` clean; `flutter test` green.
- Every WBS 2.4 test case in `wbs_dictionary.md` has a corresponding test row in
  `test_scripts.md`.
- `domain_lints` passes (no Firebase/Flutter imports in `domain/`).

**Risks called out before coding:**
- Status transitions must be guarded server-side or a malicious requester could
  self-approve — mitigated by the rules RBAC split (step 6).
- Concurrent approve/reject needs a batch/transaction to avoid partial writes.

---

## Phase C — Approval

Plan reviewed: entity + interface first (architect), then implementation
(flutter_engineer), then tests by a **different** role (qa_engineer) per the
Writer/Reviewer rule. Approved without reordering. Execution proceeded step by
step; outcomes are recorded in the WBS 2.4 rows of `test_scripts.md` and the
Weekly Orchestration Log in `ORCHESTRATION.md`.
