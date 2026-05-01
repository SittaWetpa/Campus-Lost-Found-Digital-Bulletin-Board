# Plan — Add `occurredAt` field to Item entity (WBS 2.1 / 2.2)

> Saved per `ORCHESTRATION.md` Plan Mode rule (line 100). Date: 2026-05-01.

---

## Trigger

`wbs_dictionary.md` updates surfaced a field that the code does not yet model:

- **WBS 2.2** (line 571) — *Associated Activities*: "Ensure `userId`, `category`, **`occurredAt` (Timestamp)**, and `imageUrls` are included in `addItem()`"
- **WBS 2.6** (line 706) — *Deliverables*: "Editable fields: title, description, location, **occurredAt (date/time)**, contact, photos"
- **WBS 2.1** (line 524) — baseline schema list does **not** include `occurredAt` → doc inconsistency to fix.

`occurredAt` represents when the item was actually lost (Seeker post) or found (Founder post), distinct from `createdAt` (when the post was made).

---

## Decisions (confirmed by user)

| # | Question | Decision |
|---|---|---|
| 1 | Required vs optional | **Required**, non-nullable |
| 2 | Type | Single `DateTime` (date + time) |
| 3 | Surface in post creation form (WBS 1.4)? | **No** — out of scope for this change |

---

## Scope

### Files to change

| Path | Change |
|---|---|
| `lib/features/feed/domain/entities/item.dart` | Add `final DateTime occurredAt;` to `Item` (required). |
| `lib/features/feed/data/models/item_model.dart` | Add field; parse `Timestamp` in `fromFirestore`; write `Timestamp.fromDate(occurredAt)` in `toFirestore`; round-trip in `fromEntity` / `toEntity`. |
| `test/unit/items/item_entity_test.dart` | Add `occurredAt` to all 10 `Item(...)` call sites; add storage-assertion test(s). |
| `test/features/feed/data/datasources/item_remote_datasource_test.dart` | Add `occurredAt` to seed maps; assert it persists on `addItem()`. |
| `wbs_dictionary.md` (line 524) | Add `occurredAt` to WBS 2.1 baseline schema list. |
| `CLAUDE.md` Firestore Collections table — `items` row | Add `occurredAt` to documented field list. |
| `test_scripts.md` | Bump WBS 2.1 entity test count + WBS 2.2 datasource test count + footer "Last updated". |
| `ORCHESTRATION.md` Weekly Log | New row for 2026-05-01 documenting the change + agents run + security_reviewer skip rationale. |

### Out of scope

- Post creation / edit UI (WBS 1.4 / 2.6 territory).
- Firestore security rules (`occurredAt` does not need field-level guarding).
- Repositories, providers, datasource query methods (field-agnostic).

---

## Agent flow

Per ORCHESTRATION.md Standard Flow + Writer/Reviewer Rule (no agent reviews its own work):

1. **architect** — confirm field placement (entity vs. model), `Timestamp ↔ DateTime` mapping, layer-rule compliance.
2. **flutter_engineer** — apply edits to entity + model.
3. **qa_engineer** — extend item entity tests + datasource test.
4. ~~security_reviewer~~ — **skipped**. ORCHESTRATION.md line 76 scopes this step to "features touching auth, Firestore rules, or secrets." `occurredAt` touches none of those.
5. Run `flutter test` and confirm zero failures.
6. Update `wbs_dictionary.md`, `CLAUDE.md`, `test_scripts.md`, `ORCHESTRATION.md` weekly log.
7. Stop and hand the diff to the human reviewer. **No commit** until human reviews.

---

## Verification criteria

- `flutter test` — 0 failures, item-related test counts increased to reflect new assertions.
- `lib/features/feed/domain/entities/item.dart` declares `occurredAt` as a required, non-nullable `DateTime`.
- `lib/features/feed/data/models/item_model.dart` round-trips `occurredAt` through Firestore `Timestamp` correctly.
- `wbs_dictionary.md` baseline schema for 2.1 lists `occurredAt`.
- `CLAUDE.md` items row lists `occurredAt`.
- `test_scripts.md` counts and "Last updated" line refreshed.
- `ORCHESTRATION.md` weekly log row for 2026-05-01 added.

---

## Risk notes

- **Existing Firestore docs** (if any in dev/prod) will not have `occurredAt`. Because the field is now required, `ItemModel.fromFirestore` will throw on legacy docs. This is acceptable for the dev branch; if real data exists, a backfill is needed before merging to `release`. Flag for human reviewer.
- The post creation form (WBS 1.4) does not yet collect `occurredAt`. Until that form is updated, no new docs will satisfy the contract — meaning post creation will break until WBS 1.4 catches up. This change should land **before or alongside** the WBS 1.4 update, not after a long delay.
