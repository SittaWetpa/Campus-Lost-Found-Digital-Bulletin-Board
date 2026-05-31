# Rollback Plan — WBS 2.13: Feature Flags via Firebase Remote Config

## Feature currently gated

| Remote Config key | Type | Default | Effect when `false`/empty |
|---|---|---|---|
| `secret_question_enabled` | Boolean | `true` | Hides Secret Question and Secret Answer fields on Founder Post form and Claim Request flow (WBS 2.10) |
| `sensitive_item_enabled` | Boolean | `true` | Hides Sensitive Item selector on Post Form (WBS 2.14) |
| `security_office_contact` | String | `02-470-9820` | Phone number shown on sensitive-item posts and Security Office contact button |
| `sensitive_categories` | String (JSON array) | `["credit_card","id_card","passport","key","document"]` | Item categories that trigger the sensitive-item flow |

---

## When to invoke this plan

- Unexpected bugs in the claim-request flow traced to secret-question logic
- Evidence of fraudulent abuse patterns exploiting the question field
- Legal or privacy escalation requiring immediate feature removal
- Critical performance regression caused by additional Firestore reads

---

## Rollback procedure — `secret_question_enabled`

1. **Open Firebase Console**
   Navigate to `console.firebase.google.com` → select the project → **Remote Config**.

2. **Locate the parameter**
   Find `secret_question_enabled` in the parameter list. Click the pencil (Edit) icon.

3. **Set value to `false`**
   Change the default value from `true` → `false`. Leave any condition overrides unchanged.

4. **Publish**
   Click **Save** then **Publish changes**. Confirm in the dialog.

5. **Propagation time**
   - Production: up to **1 hour** (governed by `minimumFetchInterval: Duration(hours: 1)`).
   - To force immediate propagation: in Firebase Console → Remote Config → click the overflow menu → **Force fetch** (if available), or temporarily set `minimumFetchInterval` to `Duration.zero` in the next app release.

---

## Post-rollback verification checklist

| # | Check | Pass condition |
|---|---|---|
| 1 | Cold-restart the app (kill process, reopen) | App launches without crash; Remote Config fetched (check logcat/console for `FirebaseRemoteConfig` log line) |
| 2 | Navigate to **Post Form** → select **Founder Post** | `SECRET QUESTION (optional)` section is **not visible** |
| 3 | Open a Founder Post Detail as a Visitor → tap **Claim Request** | No secret-answer field appears in the request form |
| 4 | Open a Request Detail as the Poster | No Verification section is shown |
| 5 | Crashlytics shows **no new fatal errors** for 15 min post-rollback | Zero new crashes in Firebase Console → Crashlytics |

---

## On-call contacts

| Role | Contact |
|---|---|
| Tech Lead | `@team-lead` (fill in before going to production) |
| Firebase Console | `console.firebase.google.com` → Remote Config UI |
| Crashlytics | `console.firebase.google.com` → Crashlytics |

---

## Firebase Remote Config — one-time setup

Create the following parameters in Firebase Console → Remote Config → **Add parameter**:

| Parameter key | Data type | Default value |
|---|---|---|
| `secret_question_enabled` | Boolean | `true` |
| `sensitive_item_enabled` | Boolean | `true` |
| `security_office_contact` | String | `02-470-9820` |
| `sensitive_categories` | String | `["credit_card","id_card","passport","key","document"]` |

Click **Publish changes**. No app release is needed for the initial setup.
