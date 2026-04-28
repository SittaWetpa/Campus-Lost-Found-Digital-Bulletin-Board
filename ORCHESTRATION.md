# Orchestration Guide — Campus Lost & Found

How the team uses Claude Code's multi-agent system to implement features safely, with clear role separation.

---

## Agent Roles

| Agent | File | Job |
|---|---|---|
| **architect** | `.claude/agents/architect.md` | Design layer structure, validate imports, define interfaces |
| **flutter_engineer** | `.claude/agents/flutter_engineer.md` | Implement production Dart/Flutter code |
| **qa_engineer** | `.claude/agents/qa_engineer.md` | Write unit, widget, and integration tests |
| **security_reviewer** | `.claude/agents/security_reviewer.md` | Read-only audit of code and Firestore rules |

`CLAUDE.md` at the project root is the shared memory loaded into every session automatically.

---

## The Writer/Reviewer Rule

**The agent that writes a module must not be the agent that reviews it.**

In practice: after `flutter_engineer` implements a feature, invoke `security_reviewer` in a separate session (or prompt) to audit it. Never ask the same agent to both write and approve.

---

## How to Implement a Feature (Standard Flow)

Use this flow for every WBS work package:

### Step 1 — Design (architect)

Ask the architect to design before writing any code:

```
@architect
Design the domain entity and repository interface for WBS 2.4 (Request & Approval System).
Include: entity shape, abstract repository methods, and file paths.
```

Review the output. If the design looks correct, proceed.

### Step 2 — Implement (flutter_engineer)

Hand the architect's design to the engineer:

```
@flutter_engineer
Implement WBS 2.4 (Request & Approval System) using this design:
[paste architect output]

Implement:
- domain/entities/request.dart
- domain/repositories/request_repository.dart
- data/repositories/request_repository_impl.dart
- presentation/providers/requests_provider.dart
- The "Claim Request" button and form on the Founder Post Detail Screen
```

### Step 3 — Write Tests (qa_engineer)

After implementation, hand the code to QA:

```
@qa_engineer
Write tests for WBS 2.4 (Request & Approval System).
Cover all test cases listed in wbs_dictionary.md for WBS 2.4.
The implementation is in:
- features/requests/data/repositories/request_repository_impl.dart
- features/requests/domain/usecases/submit_request.dart
```

### Step 4 — Security Review (security_reviewer)

For any feature touching auth, Firestore rules, or secrets:

```
@security_reviewer
Review the Firestore rules changes and the RequestRepository implementation for WBS 2.4.
Focus on: sub-collection access control, visitorAnswer protection, ownership enforcement.
```

### Step 5 — Commit

Only commit after all four steps pass with no blockers.

---

## Plan Mode

For complex tasks spanning multiple files or features, use Plan Mode before writing any code:

1. Press `/plan` (or invoke Plan Mode in the Claude Code UI)
2. Describe the full task
3. Review the generated plan — add, remove, or reorder steps
4. Approve the plan
5. Execute step by step

**Save the plan transcript** as evidence for WBS 6.1. Copy the plan output into `docs/plans/` with a filename matching the WBS code (e.g., `docs/plans/wbs_2_4_plan.md`).

---

## Branching + Agent Mapping

Each team member owns a branch and works on specific WBS items:

```
git checkout -b <nickname>/feat/<feature-name>
```

Suggested ownership (update this table as the team assigns tasks):

| WBS | Feature | Owner Branch Pattern |
|---|---|---|
| 0.1, 0.3, 0.5 | Auth + OTP | `*/feat/auth` |
| 1.2, 1.3, 1.5 | Feed + Detail + Search | `*/feat/feed` |
| 1.4, 2.6, 2.7, 2.8 | Post Form + Edit/Delete | `*/feat/post` |
| 2.4, 2.10 | Request System + Secret Q | `*/feat/requests` |
| 1.6, 1.7, 1.8 | Profile + Settings | `*/feat/profile` |
| 4.1, 4.2, 4.3 | Architecture skeleton | `*/feat/architecture` |

---

## Weekly Orchestration Log

Update this table every week. It is evidence for WBS 6.1.

> ⚠️ **Apr 18 – Apr 27 reconstructed from git log** (`git log --all --oneline --format="%ad | %s" --date=short`) on 2026-04-28. Future entries must be logged in real time.

| Dates | WBS Completed | Agent Tasks Run | Key Handoffs | Human Reviewer Catches |
|---|---|---|---|---|
| Apr 18 | Project scaffold | — | — | — |
| Apr 23–25 | WBS 0.1, 0.2, 0.3, 0.5 (auth + OTP), WBS 2.9 (Cloud Functions REST API), WBS 4.1 (Clean Architecture scaffold), WBS 4.2 (Riverpod + Firebase init) | `flutter_engineer` → auth implementation; `security_reviewer` → audit of auth layer and Firestore rules | `flutter_engineer` → `security_reviewer` (auth audit) → `flutter_engineer` (apply fixes) | CRITICAL: `google-services.json` was tracked by git — removed and keys rotated; HIGH: OTP `verifyOtp` had a Firestore race condition — fixed with a transaction; HIGH: `createdAt` was set client-side — replaced with `FieldValue.serverTimestamp()`; LOW: email domain check used `endsWith` — replaced with anchored regex |
| Apr 26–27 | WBS 2.1 (domain entities + Firestore indexes), WBS 4.3 (GoRouter + auth guards + 33 unit tests), WBS 0.3 redesign (amber/cream UI + 17 widget tests) | `architect` → schema design for Item/ItemRequest entities; `flutter_engineer` → implementation; `qa_engineer` → widget tests for 0.3 and unit tests for 4.3 | `architect` → `flutter_engineer` (entity + router implementation) → `qa_engineer` (write tests) | Auth redesign PR (#6) was accidentally merged to `main` instead of `develop` — resolved by opening PR #7 (main → develop), fixing merge conflicts manually, and updating the login screen (removed demo info box) |
| Apr 28 (morning) | WBS 1.2 (feed screen), WBS 7.1 (test_scripts.md + traceability matrix), CLAUDE.md testing rules | `flutter_engineer` → feed screen; `qa_engineer` → test_scripts.md + traceability matrix | — | — |
| Apr 28 (afternoon) | WBS 2.2 (Firestore CRUD for items — full data layer) | Plan Mode → `architect` design → `flutter_engineer` implementation → `qa_engineer` tests | Plan approved before coding; `flutter_engineer` → `qa_engineer` (write 4 unit tests with fake_cloud_firestore) | Prefix-range query upper-bound needed `String.fromCharCode(0xF8FF)` not raw `` escape (tool encoding issue); `fake_cloud_firestore: ^3.0.3` added as dev dependency |

---

## Quick Reference — Invoking Agents

In Claude Code, prefix your prompt with the agent name:

```
@architect   — design / structure questions
@flutter_engineer   — write production code
@qa_engineer   — write tests
@security_reviewer   — audit / review (read-only)
```

Or select the agent from the Claude Code agent picker in the VS Code panel.
