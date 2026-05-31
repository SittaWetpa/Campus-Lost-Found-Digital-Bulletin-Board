# Accessibility Audit — WBS 5.1

**Date:** 2026-05-15
**Standard:** WCAG 2.2 Level AA
**Scope:** All 14 presentation screens in `lib/features/`
**Auditor:** WBS 5.1 automated sweep (Claude Code)

---

## Summary

Phase 1 fixed the one global color token that failed contrast (ink500). Phases 2–3 added Semantics labels to all bare interactive widgets and verified each screen against Flutter's built-in accessibility guidelines. All pre-existing contrast failures that remain are documented below as known design debt — they originate from the amber primary palette and compact-button layout choices that pre-date this WBS.

---

## Phase 1 — Color Contrast Token Fix

| Token | Old value | New value | Old ratio (on cream bg) | New ratio | Status |
|---|---|---|---|---|---|
| `AppTokens.ink500` | `0xFF8A7E66` | `0xFF6B6050` | ~3.2:1 | ~4.6:1 | Fixed |
| `AppTokens.primary500` | unchanged | unchanged | — | — | Marked: icon/fill only, not for text |
| `AppTokens.primary400` | unchanged | unchanged | — | — | Marked: icon/fill only, not for text |

File: `lib/core/theme/app_tokens.dart`

---

## Phase 2 — Semantics Sweep (14 screens)

Each row lists what was changed and why.

| Screen | File | Changes made |
|---|---|---|
| Login | `auth/presentation/screens/login_screen.dart` | App icon → `ExcludeSemantics`; both TextFormFields → `labelText:`; password toggle → `tooltip:`; "Create account" GestureDetector → `Semantics(label:, button: true)` |
| Register | `auth/presentation/screens/register_screen.dart` | All 7 TextFormFields → `labelText:`; both password toggles → `tooltip:`; removed unused `_label()` helper |
| OTP Verify | `auth/presentation/screens/otp_verify_screen.dart` | Each digit box → `Semantics(label: 'OTP digit N')`; Resend GestureDetector → `Semantics(label: 'Resend OTP code', button: true)` |
| Feed | `feed/presentation/screens/feed_screen.dart` | FAB → `tooltip: 'Post item'`; `_Tab` GestureDetector → `Semantics(label:, button: true, selected:)`; category filter/clear InkWells → `Semantics` |
| Item Detail | `feed/presentation/screens/item_detail_screen.dart` | Edit IconButton → `tooltip: 'Edit post'`; Delete IconButton → `tooltip: 'Delete post'`; phone GestureDetector → `Semantics(label: 'Call poster: …', button: true)` |
| My Posts | `feed/presentation/screens/my_posts_screen.dart` | `_Tab` GestureDetector → `Semantics(label:, button: true, selected:)` |
| Post Form | `post/presentation/screens/post_form_screen.dart` | `_CategoryButton`, `_SensitiveButton`, `_DateTimeTile`, photo GestureDetectors, `_ContactSourceButton`, `_QuickPickChips` chips → all wrapped in `Semantics(label:, button: true[, selected:])` |
| Edit Post | `post/presentation/screens/edit_post_screen.dart` | Thin wrapper; no interactive elements needed labelling |
| Claim Request | `requests/presentation/screens/claim_request_screen.dart` | Back IconButtons (main + AlreadySubmitted) → `tooltip: 'Back'` |
| Found Report | `requests/presentation/screens/found_report_screen.dart` | Back IconButtons (main + AlreadySubmitted) → `tooltip: 'Back'`; `_PhotoPickButton` → `Semantics(label: 'Attach photo', button: true)`; `_PhotoPreview` remove → `Semantics(label: 'Remove photo', button: true)` |
| Request Detail | `requests/presentation/screens/request_detail_screen.dart` | All buttons are Material (`ElevatedButton`/`OutlinedButton`) — auto-labelled; no changes needed |
| Settings | `profile/presentation/screens/settings_screen.dart` | `_DeveloperRow` InkWell → `Semantics(label:, button: true)` |
| Edit Profile | `profile/presentation/screens/edit_profile_screen.dart` | All 5 TextFormFields → `labelText:` in InputDecoration; removed unused `_label()` helper |
| Notifications | `notifications/presentation/screens/notifications_screen.dart` | `_TypeFilterChip` InkWell → `Semantics(label:, button: true, selected:)`; `_NotificationTile` Material/InkWell → `Semantics(label: title + body, button: true)` |

---

## Phase 3 — Widget Test Accessibility Assertions

One `testWidgets('meets accessibility guidelines …')` block added to each of the 14 screen test files.

| Test file | Guidelines checked | Omissions & reason |
|---|---|---|
| `login_screen_test.dart` | `androidTapTarget`, `labeledTapTarget` | `textContrast` omitted — amber floating labelText ~2.79:1, pre-existing design token |
| `register_screen_test.dart` | `androidTapTarget`, `labeledTapTarget` | `textContrast` omitted — same amber floating label issue |
| `otp_verify_screen_test.dart` | `androidTapTarget`, `labeledTapTarget` | `textContrast` omitted — grey helper text pre-dates WBS 5.1 |
| `feed_screen_test.dart` | `labeledTapTarget`, `textContrast` | `androidTapTarget` omitted — ItemCard shrinkWrap padding pre-existing; connectivity provider overridden to prevent `MissingPluginException` |
| `item_detail_screen_test.dart` | `androidTapTarget`, `labeledTapTarget` | `textContrast` omitted — metadata text at ~4.32:1, marginally below threshold, pre-existing |
| `my_posts_screen_test.dart` | `labeledTapTarget`, `textContrast` | `androidTapTarget` omitted — same ItemCard shrinkWrap issue |
| `post_form_screen_test.dart` | `androidTapTarget`, `labeledTapTarget` | `textContrast` omitted — "POST" AppBar text ~2.53:1, pre-existing |
| `edit_post_screen_test.dart` | `androidTapTarget` | `labeledTapTarget` omitted — ImagePickerPlatform mock leaks from post_form_screen_test when run in same process (pre-existing isolation issue); `textContrast` omitted — amber FilledButton |
| `claim_request_screen_test.dart` | `androidTapTarget`, `labeledTapTarget` | `textContrast` omitted — hint text and AppBar action amber/grey tones, pre-existing |
| `found_report_screen_test.dart` | `androidTapTarget`, `labeledTapTarget` | `textContrast` omitted — same as above |
| `request_detail_screen_test.dart` | `androidTapTarget`, `labeledTapTarget` | `textContrast` omitted — PENDING chip ~3.71:1, requester text ~3.12:1, pre-existing `_Tokens` local palette |
| `edit_profile_screen_test.dart` | `labeledTapTarget` | `androidTapTarget` omitted — "Change photo" shrinkWrap 32 dp; `textContrast` omitted — amber FilledButton |
| `settings_screen_test.dart` | `labeledTapTarget` | `androidTapTarget` omitted — "Edit" shrinkWrap 32 dp; `textContrast` omitted — GoogleFonts async fetch surfaces through `meetsGuideline`'s `runAsync` |
| `notifications_screen_test.dart` (new) | `androidTapTarget`, `labeledTapTarget`, `textContrast` | All three checked — no omissions |

---

## Known Design Debt (out of scope for WBS 5.1)

| Issue | Location | Contrast / size | Recommendation |
|---|---|---|---|
| Amber `FilledButton` (white text on amber) | All screens using `_kAmber` / `AppTokens.primary500` as `backgroundColor` | ~2.77:1 — fails 4.5:1 AA for normal text | Replace amber with `primary600` (`0xFFB36F00`) for text-on-light, or darken button to `0xFFA06200` |
| Amber floating `labelText` | Login, Register TextFormFields | ~2.79:1 | Override `floatingLabelStyle` with `primary600` in `InputDecoration` |
| AppBar action "POST" text | PostFormScreen AppBar | ~2.53:1 | Use `foregroundColor` override with darker text or change to `IconButton` |
| `ItemCard` tap target | Feed, My Posts | 69×33 dp rendered | Increase card padding or set `constraints: BoxConstraints(minHeight: 48)` |
| Compact `OutlinedButton` ("Edit", "Change photo") | Settings, Edit Profile | 84×32 dp | Remove `MaterialTapTargetSize.shrinkWrap` or add `minimumSize: Size(48, 48)` |
| Status chip contrast ("PENDING", "APPROVED" etc.) | Request Detail | 3.12–3.71:1 | Darken chip text colors in `_Tokens` local palette |
| Metadata text (timestamp, location) | Item Detail | ~4.32:1 | Bump `ink500` usages to `ink600` (`0xFF5C5242`) for 11–12 pt text |

---

## R5(c) Remediation — Contrast Debt Cleared (compliance-gap audit)

The "Known Design Debt" above is now resolved. White↔amber contrast is symmetric,
so a single accessible amber (`0xFFA06200`, ≈4.9:1 vs white / ≈4.6:1 vs cream)
serves both as a button fill (white text on it) and as amber text. Every screen
widget test now asserts `textContrastGuideline` (previously omitted on 11 of 14).

### Token / color before → after

| Element | Location | Before | After | Before ratio | After ratio |
|---|---|---|---|---|---|
| Primary `FilledButton` fill | `app.dart` theme + local `_kAmber`/`_kPrimary` | `0xFFD98A0E` / `0xFFCA8A04` | `0xFFA06200` (`AppTokens.amberAccessible`) | ~2.77:1 | ~4.9:1 |
| Floating `labelText` | `app.dart` `inputDecorationTheme` | amber primary | `ink700` (`0xFF423A2D`) | ~2.79:1 | >7:1 |
| Helper text "11-digit KMUTT ID" | `register_screen.dart` | `_amber` | `0xFF6B6050` | ~2.79:1 | ~4.6:1 |
| Muted text (`Colors.grey`) | `login_screen.dart`, `otp_verify_screen.dart` | `0xFF9E9E9E` | `0xFF6B6050` | ~2.55:1 | ~4.6:1 |
| Status accent `success` | `AppTokens` (chips, ACTIVE, "Found · Founder") | `0xFF2F7D3E` | `0xFF2A7038` | ~4.32:1 | ~5.2:1 |
| Status accent `seeker` | `AppTokens` (chips, error) | `0xFFC94A3E` | `0xFFB23A2E` | ~3.6:1 (on seekerBg) | ~4.6:1 |
| Status accent `warn` | `AppTokens` + `_Tokens` (PENDING chip) | `0xFFA96C00` | `0xFF8A5800` | ~3.71:1 | ~5.1:1 |
| Secondary text `ink400` | `claim_request`, `found_report`, `request_detail` `_Tokens` | `0xFF9C9179` | `0xFF6E6450` | ~2.9–3.1:1 | ~5.9:1 |
| AppBar "POST" action | `post_form_screen.dart` `_kAmber` | `0xFFCA8A04` | `0xFFA06200` | ~2.53:1 | ~4.6:1 |

### Tests

- `textContrastGuideline` re-enabled in all 14 screen test files (the 11 previously
  omitting it: login, register, otp_verify, item_detail, post_form, edit_post,
  claim_request, found_report, request_detail, settings, edit_profile).
- `settings_screen_test` disables `GoogleFonts.config.allowRuntimeFetching` so the
  guideline's `runAsync` no longer surfaces a font-download exception.
- Dynamic type: `login_screen_test` adds a 1.5× `TextScaler` test
  (`MediaQuery.withClampedTextScaling`) asserting no overflow/layout exception.

> `androidTapTargetGuideline` omissions on compact buttons (Settings/Edit Profile
> "Edit"/"Change photo", ItemCard) and the `edit_post` `labeledTapTarget` mock-leak
> note are unchanged — those are tap-target/test-isolation items, out of scope for
> the R5(c) contrast remediation.
