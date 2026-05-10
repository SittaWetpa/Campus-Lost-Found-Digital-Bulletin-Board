# WBS Dictionary
## Project: Campus Lost & Found Digital Bulletin Board
**Tech Stack: Flutter (Dart) + Firebase (Authentication, Firestore, Storage, Cloud Functions) + shared_preferences**

> Each entry covers: **Scope / Statement of Work**, **Deliverables**, and **Associated Activities**.

---

## 📖 Term Glossary

| Old Term | New Term | Meaning |
|---|---|---|
| Non-owner found post | **Founder Post** | A post created by the person who found the item |
| Non-owner lost post | **Seeker Post** | A post created by the person who lost the item |
| "Request to claim" (on Founder Post) | **Claim Request** | A request submitted by the person who lost the item to reclaim it |
| "I found this" (on Seeker Post) | **Found Report** | A report indicating that someone has found the item being searched for |
| Post owner | **Poster** | The person who created the post |
| Non-owner | **Visitor** | The person who views another user's post |
| status: "active" | **Active** | A post that is still open and accepting requests |
| status: "returned" | **Resolved** | A post that has been closed; the item has been returned |


---

> **Testing Guide, run commands, writing conventions, and the full traceability matrix are in [`test_scripts.md`](test_scripts.md).** The work package definition is at **WBS 7.1**.

---

## Phase 0.0 — Authentication

---
 
### 0.1 Firebase Auth Setup 
 
| Field | Detail |
|---|---|
| **WBS Code** | 0.1 |
| **Type** | Work Package |
| **Requirement** | Firebase Authentication |
 
**Scope / Statement of Work**
Enable and configure Firebase Authentication in the Firebase Console using Email/Password as the sign-in provider. Integrate the `firebase_auth` package into the Flutter project and create an `AuthService` class wrapping all authentication operations. **Email addresses are restricted to the `@mail.kmutt.ac.th` domain** — any other domain is rejected before Firebase Auth is called. An `OTPService` class handles OTP generation, Firestore storage, email dispatch (via Firebase Extension), and verification.
 
**Deliverables**
- Firebase Authentication enabled with Email/Password provider in Firebase Console
- `firebase_auth` package added to `pubspec.yaml`
- `AuthService` Dart class with `signUp()`, `signIn()`, and `signOut()` methods
- `AuthService.signUp()` enforces `@mail.kmutt.ac.th` domain before calling Firebase — throws `InvalidDomainException` for any other domain
- `OTPService` Dart class with:
  - `sendOTP(String email)` — generates a 6-digit code, stores it in Firestore `otp_verifications/{uid}` with `expiresAt` (now + 10 min) and `attempts: 0`, then writes to the `mail/` collection to trigger the Firebase Extension email
  - `verifyOTP(String uid, String code)` — reads from Firestore, checks expiry, checks attempts ≤ 5, returns `true` on match and marks `emailVerified: true` on the `users/{uid}` document
  - `resendOTP(String email)` — invalidates the existing code and calls `sendOTP()` again
- Firebase Extension **"Trigger Email from Firestore"** installed and configured with a valid SMTP provider (e.g., Gmail App Password or SendGrid)
- OTP email template: subject "Campus Lost & Found — Verify your email", body includes the 6-digit code and 10-minute expiry notice

**Associated Activities**
- Enable Email/Password sign-in in the Firebase Console under Authentication
- Add `firebase_auth` to `pubspec.yaml` and run `flutter pub get`
- Create `auth_service.dart` with `FirebaseAuth.instance` reference
- Implement domain validation: `if (!email.endsWith('@mail.kmutt.ac.th')) throw InvalidDomainException()`
- Implement `signUp(email, password)` using `createUserWithEmailAndPassword()` — called only after domain validation passes
- Implement `signIn(email, password)` using `signInWithEmailAndPassword()` — also enforces domain check; additionally checks `users/{uid}.emailVerified == true` before allowing access (handled by route guard in 4.3)
- Implement `signOut()` using `FirebaseAuth.instance.signOut()`
- Create `otp_service.dart`
- Implement `sendOTP()`: generate 6-digit code with `Random.secure()`, write to `otp_verifications/{uid}` in Firestore, write to `mail/{docId}` to trigger email extension
- Implement `verifyOTP()`: read code, check `expiresAt`, check `attempts`, compare code, on success write `emailVerified: true` to `users/{uid}`
- Implement `resendOTP()`: delete existing `otp_verifications/{uid}` doc, call `sendOTP()` again
- Install Firebase Extension "Trigger Email from Firestore" from the Firebase Console Extensions Hub
- Configure SMTP credentials for the extension (store in Secret Manager, not plaintext)

**Firestore schema additions (otp_verifications collection)**
```
otp_verifications/{uid}
  - code: String          // 6-digit code
  - expiresAt: Timestamp  // now + 10 minutes
  - attempts: int         // incremented on each wrong guess, max 5
  - createdAt: Timestamp
```
 
**Testing**
- Unit test: `AuthService.signUp()` with `@mail.kmutt.ac.th` email — verify `createUserWithEmailAndPassword()` is called
- Unit test: `AuthService.signUp()` with `@gmail.com` email — verify `InvalidDomainException` is thrown and Firebase Auth is NOT called
- Unit test: `AuthService.signIn()` with non-KMUTT email — verify `InvalidDomainException`
- Unit test: `OTPService.verifyOTP()` with correct code within expiry — returns `true`, writes `emailVerified: true`
- Unit test: `OTPService.verifyOTP()` with expired code — returns `false`
- Unit test: `OTPService.verifyOTP()` with wrong code 5 times — returns `false` on 6th attempt (locked out)
- Unit test: `OTPService.verifyOTP()` with correct code but `attempts >= 5` — returns `false`

---

### 0.2 User Profile Schema

| Field | Detail |
|---|---|
| **WBS Code** | 0.2 |
| **Type** | Work Package |
| **Requirement** | Firebase Authentication · Data Storage |

**Scope / Statement of Work**
Design and initialize a `users` collection in Firestore to store additional user data that Firebase Authentication does not natively support. Each document is keyed by the user's Firebase Auth `uid` and created at registration time. The schema includes first name, last name, student ID, and telephone number — all collected during registration.

**Deliverables**
- Defined `users` collection schema: `uid`, `email`, `firstName`, `lastName`, `studentId`, `telephone`, `avatarUrl`, `createdAt`
- `UserService` Dart class with `createUserProfile()`, `updateUserProfile()`, and `getUserById()` methods
- Firestore security rules allowing users to read/write only their own document

**Associated Activities**
- Design the `users` collection schema including all profile fields
- Create `user_service.dart` with `createUserProfile(uid, email, firstName, lastName, studentId, telephone)` method
- Implement `createUserProfile()` using `.collection("users").doc(uid).set(data)`
- Implement `updateUserProfile(uid, data)` using `.doc(uid).update(data)` for profile edits
- Set `createdAt` using `FieldValue.serverTimestamp()`
- Configure Firestore security rules for user profile documents

**Testing**
- Unit test: `UserService.createUserProfile()` — verify `.set()` is called on the correct doc path `users/{uid}` with all required fields (`firstName`, `lastName`, `studentId`, `telephone`, `email`)
- Unit test: `UserService.createUserProfile()` — verify `createdAt` uses `FieldValue.serverTimestamp()`
- Unit test: `UserService.getUserById()` — verify returned map contains all expected profile fields
- Firestore rules test: read/write to another user's doc — verify access is denied

---
 
### 0.3 Login & Register Screen
 
| Field | Detail |
|---|---|
| **WBS Code** | 0.3 |
| **Type** | Work Package |
| **Requirement** | Firebase Authentication · Pages & Navigation |
 
**Scope / Statement of Work**
Build the Login and Register screens in Flutter. The Register screen collects first name, last name, student ID, telephone number, email, and password. **The email field is restricted to `@mail.kmutt.ac.th` — any other domain shows a validation error and blocks submission.** On successful registration, the app navigates to the **Email OTP Verification Screen (0.5)** instead of the Feed. The Login screen uses email and password. Both screens include full input validation and error handling per the Firebase Authentication requirement.
 
**Deliverables**
- Register screen: first name, last name, student ID, telephone number, email, password, confirm password fields
- Email field validation: must end with `@mail.kmutt.ac.th` — shown as inline error "Invalid email domain. Use @mail.kmutt.ac.th only" if domain is wrong
- Login screen: email and password fields (also validates @mail.kmutt.ac.th domain)
- Client-side validation on both screens
- Student ID saved to Firestore `users` collection on successful registration
- Error messages via `SnackBar` on failed auth (invalid credentials, network failure, etc.)
- On successful **registration**: navigate to **OTP Verification Screen (0.5)**, NOT the Feed
- On successful **login** (with `emailVerified == true`): navigate to Feed Screen
- On successful **login** (with `emailVerified == false`): navigate to OTP Verification Screen (0.5) with resend option

**Associated Activities**
- Build Register screen UI based on wireframe
- Build Login screen UI based on wireframe
- Implement `Form` validation (required fields, email format, `@mail.kmutt.ac.th` domain check — show "Invalid email domain. Use @mail.kmutt.ac.th only", password length, student ID format)
- On register: call `AuthService.signUp()` — on success call `UserService.createUserProfile()` — call `OTPService.sendOTP()` — navigate to OTP Verification Screen
- On login: call `AuthService.signIn()` — check `emailVerified` flag — navigate accordingly
- Display appropriate `SnackBar` messages for each error type

**Testing**
- Widget test: Register screen with empty required fields — verify validation errors block submission
- Widget test: Register screen with `@gmail.com` email — verify "Invalid email domain. Use @mail.kmutt.ac.th only" error appears
- Widget test: Register screen with `@mail.kmutt.ac.th` email — validation passes
- Widget test: Register screen with mismatched password and confirm password — verify validation error appears
- Widget test: Login screen with invalid email format — verify validation error appears
- Widget test: successful register — verify navigation goes to OTP Verification Screen (not Feed) and `OTPService.sendOTP()` is called
- Widget test: successful login with `emailVerified == false` — verify navigation to OTP Verification Screen

---

### 0.4 Auth State & Route Guard

| Field | Detail |
|---|---|
| **WBS Code** | 0.4 |
| **Type** | Work Package |
| **Requirement** | Firebase Authentication |

**Scope / Statement of Work**
Expose the Firebase Authentication state as a Riverpod stream provider (`currentUserProvider`, defined in **4.2**) and implement route-level authentication guards via the GoRouter `redirect` callback (defined in **4.3**). Unauthenticated users are redirected to `/login`; authenticated users flow to their requested route (default `/feed`). Session persistence across app restarts is handled automatically by the Firebase Auth SDK. **This WP is superseded by 4.2 + 4.3 for its routing mechanics** — it remains as the functional requirement anchor.

**Deliverables**
- `currentUserProvider` — a Riverpod `Stream<User?>` provider wrapping `FirebaseAuth.instance.authStateChanges()` (implementation: **4.2**)
- GoRouter `redirect` callback consuming `currentUserProvider`: unauth → `/login`; auth → requested route (implementation: **4.3**)
- Session persistence across app restarts (handled by Firebase Auth SDK)
- Current `User` accessible anywhere in the widget tree via `ref.watch(currentUserProvider)`
- No `StreamBuilder`-based routing remains in `main.dart`

**Associated Activities**
- Define `currentUserProvider` in the providers layer (see **4.2** for setup)
- Wire the GoRouter `redirect` callback to consume the provider (see **4.3**)
- Remove any residual `StreamBuilder` routing from `main.dart`
- Test redirect behavior on fresh launch, after logout, and after session expiry

**Testing**
- Widget test: mock `currentUserProvider` returning `null` — verify redirect to `/login`
- Widget test: mock `currentUserProvider` returning a valid `User` — verify requested authed route renders
- Integration test: sign out from Settings — verify router redirects to `/login` automatically

---
 
### 0.5 Email OTP Verification Screen 
 
| Field | Detail |
|---|---|
| **WBS Code** | 0.5 |
| **Type** | Work Package |
| **Requirement** | Firebase Authentication · Pages & Navigation |
 
**Scope / Statement of Work**
Build the screen that receives a 6-digit OTP sent to the user's `@mail.kmutt.ac.th` inbox and verifies it in-app before granting access to the Feed. The OTP is valid for 10 minutes and allows a maximum of 5 attempts before locking the code. A resend option is available after a 60-second cooldown. This screen is shown after registration and also when a user logs in with an unverified email.
 
**Deliverables**
- OTP Verification Screen with:
  - Display of partially masked email (e.g., `s*****@mail.kmutt.ac.th`)
  - 6 individual digit input boxes (or a single 6-digit `TextField`)
  - "Verify" button
  - Countdown timer showing remaining expiry time (10:00 → 0:00)
  - "Resend code" button — disabled with 60-second cooldown after each send
  - "Back to Login" link (signs out the current unverified user and returns to Login)
- On correct OTP: `OTPService.verifyOTP()` called — on success navigate to Feed Screen
- On wrong OTP: show inline error "Incorrect code. Please try again." with remaining attempts count
- On 5 failed attempts: show "Too many incorrect attempts. Please request a new code." and disable Verify button
- On expired OTP (timer reaches 0:00): disable Verify button, prompt user to resend
- Loading indicator shown while `verifyOTP()` is running

**Associated Activities**
- Build OTP screen UI based on wireframe (from 1.1)
- Accept `uid` and masked email via GoRouter route params (passed from Register / Login)
- Implement 6-digit input: either 6 separate `TextFormField` widgets with auto-focus-next, or a single field with `inputFormatters: [LengthLimitingTextInputFormatter(6)]`
- Implement countdown timer using `Timer.periodic`; disable Verify button on expiry
- Implement resend button with 60-second cooldown using a separate `Timer`
- Call `OTPService.verifyOTP(uid, code)` on Verify tap
- On success: navigate to `/feed` via GoRouter
- On failure: increment displayed attempts counter
- On "Back to Login": call `AuthService.signOut()` then navigate to `/login`

**Testing**
- Widget test: enter correct 6-digit code — verify `OTPService.verifyOTP()` called with correct args — verify navigation to Feed
- Widget test: enter wrong code — verify error message and attempts counter shown
- Widget test: enter wrong code 5 times — verify Verify button is disabled and lock message shown
- Widget test: timer reaches 0:00 — verify Verify button is disabled and resend is prompted
- Widget test: tap Resend — verify `OTPService.resendOTP()` called and 60-second cooldown starts
- Widget test: tap "Back to Login" — verify `AuthService.signOut()` called and navigation to `/login`
- Integration test: full register → receive OTP → enter correct code → arrive at Feed Screen

---

## Phase 1.0 — Flutter UI

---

### 1.1 UI/UX Design & Interactive Prototype

| Field | Detail |
|---|---|
| **WBS Code** | 1.1 |
| **Type** | Work Package |
| **Requirement** | Pages & Navigation |

**Scope / Statement of Work**
Design and deliver an interactive prototype of the app covering all screens, based on the prototype already established by the team. The prototype defines navigation flows, component styles, and visual structure that all developers will reference during implementation.

**Deliverables**
- Interactive prototype covering all screens: Login, Register, Feed, Post Form, Detail (Poster × Seeker Post, Poster × Founder Post, Visitor × Seeker Post, Visitor × Founder Post), Claim Request Form, Found Report Form, Request Detail, My Posts, Settings, Edit Profile
- Navigation flow between all screens
- Component style guide (colors, typography, button styles, spacing, status badges)

**Associated Activities**
- Review the existing prototype established by the team as the baseline
- Create interactive prototype in Figma covering all screens and navigation flows
- Define component style guide: color palette, typography scale, button variants, spacing tokens, status badges

---

### 1.2 Item Listing Feed Screen

| Field | Detail |
|---|---|
| **WBS Code** | 1.2 |
| **Type** | Work Package |
| **Requirement** | Pages & Navigation |

**Scope / Statement of Work**
Build the main home screen displaying all active lost-and-found posts in real time using `StreamBuilder`. Only `status == "active"` (Active) documents are shown. Accessible to authenticated users only.

**Deliverables**
- Feed screen with `StreamBuilder` connected to Firestore `items` collection
- Reusable `ItemCard` widget: title, category tag (Seeker / Founder), date, contact info
- Filter showing only Active items
- Navigation to Item Detail Screen on card tap
- Sign-out button

**Associated Activities**
- Implement screen layout based on wireframe
- Create `ItemCard` widget in Dart with Seeker/Founder category label
- Set up `StreamBuilder` with `.where("status", isEqualTo: "active")` query
- Add tap navigation to Item Detail Screen
- Add sign-out button calling `AuthService.signOut()`

**Testing**
- Widget test: mock Firestore stream with Active + Resolved items — verify only Active items render in the list
- Widget test: tap an `ItemCard` — verify navigation to Item Detail Screen with the correct item payload
- Widget test: empty stream — verify empty-state UI is displayed

---

### 1.3 Item Detail Screen

| Field | Detail |
|---|---|
| **WBS Code** | 1.3 |
| **Type** | Work Package |
| **Requirement** | Pages & Navigation |

**Scope / Statement of Work**
Build a dedicated screen showing full details of a selected lost-and-found item. Displays all fields from the Firestore document. The screen adapts based on post type (Seeker Post / Founder Post) and user role (Poster / Visitor).

**Deliverables**
- Detail screen showing: title, category, description, location, date & time occurred, contact, photo gallery (up to 3 images), posted date
- "Edited · [time]" label shown when `editedAt` field is present
- **Poster view**: edit icon and trash icon in app bar; request inbox with truncated descriptions and "Read more" link; tapping a request opens full request detail view (message + photo if any)
- Photo thumbnail shown on Seeker Post request cards (Found Reports)
- **Visitor / Founder Post**: "Claim Request" button
- **Visitor / Seeker Post**: "Found Report" button
- Back navigation to Feed Screen

**Associated Activities**
- Build detail screen layout based on wireframe
- Accept item data passed via navigation arguments
- Display all item fields including image from Firebase Storage URL
- Compare `userId` with current `uid` to show Poster controls vs Visitor controls
- Show "Claim Request" button for Visitors on Founder Posts; "Found Report" for Seeker Posts
- Show Poster request inbox below item details when requests exist
- Wire edit icon to Edit Post screen and trash icon to Post Delete flow

> **Note**: There is no standalone "Mark as Resolved" button on this screen. An item's `status` transitions to `resolved` **only** when the Poster approves a request (see 2.4).

**Testing**
- Widget test: render Detail Screen with `item.userId == currentUser.uid` — verify edit and trash icons are visible; Claim Request / Found Report buttons are hidden
- Widget test: render Detail Screen as a Visitor on a Founder Post — verify "Claim Request" button is visible; edit/trash are hidden
- Widget test: render Detail Screen as a Visitor on a Seeker Post — verify "Found Report" button is visible
- Widget test: item with `editedAt` present — verify "Edited · [time]" label is rendered

---

### 1.4 Post Form Screen

| Field | Detail |
|---|---|
| **WBS Code** | 1.4 |
| **Type** | Work Package |
| **Requirement** | Pages & Navigation · Data Storage |

**Scope / Statement of Work**
Create the form screen for submitting a new Seeker Post (lost item) or Founder Post (found item). Uses Flutter `Form` and `TextFormField` with validation. The authenticated user's `uid` is attached automatically. The form includes a date and time picker for when the item was lost or found. For the contact number field, users can choose to auto-fill their registered telephone number or enter a different one. Up to 3 photos can be optionally attached and uploaded to Firebase Storage.

**Deliverables**
- Form screen with fields: title, category (Seeker Post / Founder Post), description, location, contact
- `userId` from Firebase Auth attached to each submission
- Optional image picker with Firebase Storage upload (max 3 photos)
- Success/error feedback via `SnackBar`
- **Recommend Similar Posts panel** (see 2.8): displayed before submission when category is "Seeker Post"

**Associated Activities**
- Build form UI using `Form` and `TextFormField`
- Implement client-side validation
- Retrieve `userId` and telephone from `FirebaseAuth.instance.currentUser` and Firestore `users` document
- Pre-fill contact field with user's telephone when "Use my number" is selected
- Show a manual text input when "Use other number" is selected
- Integrate `image_picker` package for optional photo
- Upload image to Firebase Storage and retrieve download URL
- Write document to Firestore via `ItemService.addItem()`
- Trigger Similar Posts recommendation when title/description fields have input (see 2.8)

**Testing**
- Widget test: submit with empty title — verify validation error blocks submission
- Widget test: select "Use my number" — verify contact field is pre-filled with profile telephone
- Widget test: select "Use other number" — verify contact field becomes an empty editable input
- Widget test: attach 4 photos — verify the 4th is rejected (max 3)
- Widget test: successful submission — verify `ItemService.addItem()` is called with `userId` and `category` attached

---

### 1.5 Search Bar Widget

| Field | Detail |
|---|---|
| **WBS Code** | 1.5 |
| **Type** | Work Package |
| **Requirement** | Pages & Navigation |

**Scope / Statement of Work**
Develop a search widget embedded in the Feed Screen. As the user types, the widget queries Firestore via `ItemService.searchItems()` and updates the displayed list in real time. Only Active items are shown.

**Deliverables**
- `TextField` search widget integrated into the Feed Screen
- Real-time filtering of items by keyword
- Empty-state UI when no results match

**Associated Activities**
- Build search `TextField` widget in Dart
- Implement debounce logic using `Timer`
- Trigger `ItemService.searchItems()` on text change
- Update feed state with filtered results
- Display "No results found" widget on empty response

**Testing**
- Widget test: type a keyword — verify `ItemService.searchItems()` is called after the debounce interval (not on every keystroke)
- Widget test: empty search result — verify "No results found" widget is rendered
- Widget test: clear search text — verify feed returns to the full Active items list

---

### 1.6 Settings & Profile Screen

| Field | Detail |
|---|---|
| **WBS Code** | 1.6 |
| **Type** | Work Package |
| **Requirement** | Pages & Navigation · Data Storage |

**Scope / Statement of Work**
Build the Settings and Profile screen where users can view their profile info (from Firestore `users` collection) and manage app preferences stored locally via `shared_preferences`. Local data must persist across app restarts.

**Deliverables**
- Settings screen displaying: avatar image (from Firebase Storage), full name, email, student ID, telephone number (from Firestore)
- "Edit profile" button navigating to Edit Profile & Avatar Screen
- Preferences persist across app restarts via `shared_preferences`
- Sign-out button
- **Developer section** — rendered only when `currentUser.isAdmin == true` (see **2.18**); contains links to Remote Config viewer and Rollback Plan screens

**Associated Activities**
- Build settings screen layout based on wireframe
- Fetch user profile from Firestore `users` collection using current `uid`
- Add sign-out button calling `AuthService.signOut()`

**Testing**
- Widget test: load screen with mocked `UserService.getUserById()` — verify all profile fields render (name, email, student ID, telephone)
- Widget test: tap "Edit profile" — verify navigation to Edit Profile & Avatar Screen
- Widget test: change a preference toggle — verify `PreferenceService.set()` is called with the new value
- Widget test: tap sign-out — verify `AuthService.signOut()` is called

---

### 1.7 My Posts Screen

| Field | Detail |
|---|---|
| **WBS Code** | 1.7 |
| **Type** | Work Package |
| **Requirement** | Pages & Navigation · Data Storage |

**Scope / Statement of Work**
Build a dedicated screen where authenticated users can view only the posts they have created. The screen queries Firestore for items matching the current user's `userId` and displays them in a list. Users can tap any post to navigate to the Detail screen where they can delete or mark it as Resolved.

**Deliverables**
- My Posts screen with a `StreamBuilder` filtered by `userId == currentUser.uid`
- Item list showing all own posts regardless of status (Active and Resolved)
- Status badge per item (Active / Resolved) so users can track resolution
- Tap to navigate to Item Detail Screen
- Entry point accessible from the Feed screen (e.g. icon button in app bar)

**Associated Activities**
- Build screen layout reusing the `ItemCard` widget from the Feed Screen
- Set up `StreamBuilder` with Firestore `.where("userId", isEqualTo: currentUser.uid)` query
- Show both Active and Resolved items (no status filter)
- Add a status indicator badge distinguishing Active vs Resolved posts
- Add navigation entry point in the Feed Screen app bar
- Tap on card navigates to the Detail Screen passing item data

**Testing**
- Widget test: mock Firestore stream with current user's posts (mixed Active + Resolved) — verify both render with correct status badges
- Widget test: mock stream filtered to another user's posts — verify those posts do NOT appear (query uses `currentUser.uid`)
- Widget test: tap an item card — verify navigation to Item Detail Screen

---

### 1.8 Edit Profile & Avatar Screen

| Field | Detail |
|---|---|
| **WBS Code** | 1.8 |
| **Type** | Work Package |
| **Requirement** | Pages & Navigation · Data Storage |

**Scope / Statement of Work**
Build a screen that allows authenticated users to edit their profile information (first name, last name, telephone number) and upload or change their profile avatar photo. Email and student ID are displayed as read-only since they are identity credentials. Changes are saved to both Firestore (`users` collection) and Firebase Storage (for the avatar image).

**Deliverables**
- Edit Profile screen with editable fields: first name, last name, telephone number
- Read-only display of student ID and email
- Avatar section: shows current avatar (or initials fallback), with a button to pick and upload a new photo
- Save button that updates Firestore `users` document and uploads new avatar to Firebase Storage
- Success/error feedback via `SnackBar`

**Associated Activities**
- Build screen layout based on wireframe, accessible from the Settings Screen
- Pre-populate all fields with current values fetched from Firestore
- Implement `TextFormField` validation for first name, last name, telephone
- Display avatar using `CircleAvatar` with `NetworkImage` from `avatarUrl` or initials fallback
- Integrate `image_picker` for avatar photo selection
- Upload selected avatar to Firebase Storage under `avatars/{uid}.jpg` and retrieve download URL
- Call `UserService.updateUserProfile()` with updated fields and new `avatarUrl`
- Display `SnackBar` confirmation on success or error message on failure

**Testing**
- Widget test: open screen with existing profile — verify all editable fields are pre-populated and email/studentId render as read-only
- Widget test: save with empty first name — verify validation error blocks submission
- Widget test: pick a new avatar — verify image is uploaded to `avatars/{uid}.jpg` and `UserService.updateUserProfile()` is called with the new `avatarUrl`
- Widget test: save succeeds — verify success `SnackBar` is shown

---

## Phase 2.0 — Data Layer

---

### 2.1 Firebase Project & Firestore Schema

| Field | Detail |
|---|---|
| **WBS Code** | 2.1 |
| **Type** | Work Package |
| **Requirement** | Data Storage |

**Scope / Statement of Work**
Create and configure the Firebase project, connect it to Flutter, and define the Firestore schema for both `items` and `users` collections, plus the `requests` sub-collection used by the request system. Security rules must restrict access to authenticated users only. Note that some fields on the `items` document are introduced by later work packages (see cross-references below); this task establishes the baseline schema and those fields are added as their respective features are implemented.

**Deliverables**
- Firebase project connected to Flutter via `google-services.json` / `GoogleService-Info.plist`
- Firestore `items` schema (baseline): `title`, `description`, `category` (seeker/founder), `status` (active/resolved), `location`, `contact`, `imageUrls`, `occurredAt` (when the item was lost/found — user-supplied), `createdAt`, `userId`
- Firestore `items` schema (fields added by later tasks — documented here for completeness):
  - `editedAt` — Timestamp, added in **2.6** (Post Edit)
  - `claimedBy` — String (requesterId), added in **2.4** (Request & Approval)
  - `secretQuestion`, `secretAnswer` — String?, added in **2.10** (Secret Question), only on Founder Posts
- Firestore `users` schema: `uid`, `email`, `studentId`, `firstName`, `lastName`, `telephone`, `avatarUrl`, `createdAt`, `isAdmin: bool` (default `false`, granted manually via Firebase Console — see **2.18**)
- Firestore `requests` sub-collection schema (under each item) — full detail in **2.4**: `requestId`, `requesterId`, `requesterName`, `requesterContact`, `message`, `status`, `createdAt`, plus `visitorAnswer` (added in **2.10**) and `editedAt` (Timestamp?, added in **2.17** — Request Edit)
- Firestore security rules: read/write for authenticated users only (field-level rules for `secretAnswer` and `visitorAnswer` are defined in **2.10**)

**Associated Activities**
- Create Firebase project in Firebase Console
- Add Flutter app and download config files
- Add `cloud_firestore` and `firebase_core` to `pubspec.yaml`
- Initialize Firebase in `main.dart`
- Design and document all collection schemas including the `requests` sub-collection
- Write and deploy Firestore security rules
- Document field-ownership table (which work package introduces which field) in the team-shared schema doc

**Testing**
- Manual test: connect Flutter app to Firebase — verify `Firebase.initializeApp()` succeeds on launch
- Firestore rules test: unauthenticated read on `items` — verify access is denied
- Firestore rules test: authenticated read on `items` — verify access is allowed

---

### 2.2 Firestore CRUD for Items

| Field | Detail |
|---|---|
| **WBS Code** | 2.2 |
| **Type** | Work Package |
| **Requirement** | Data Storage |

**Scope / Statement of Work**
Write an `ItemService` Dart class encapsulating all Firestore create, read, update, and delete operations for the `items` collection. All write operations must include the authenticated user's `userId`.

**Deliverables**
- `ItemService` with:
  - `addItem(Map data)` — create new document with `userId` and `category` (seeker/founder)
  - `getItems()` — real-time `Stream` of Active items
  - `editItem(String id, Map data)` — update document fields including `editedAt`
  - `deleteItem(String id)` — delete a document by ID
- Service integrated with Feed and Form screens

**Associated Activities**
- Create `item_service.dart` with `FirebaseFirestore.instance` reference
- Implement all four CRUD methods
- Ensure `userId`, `category`, `occurredAt` (Timestamp), and `imageUrls` (List of download URLs) are included in `addItem()`
- Implement `getItems()` filtered by `status == "active"`
- Test all operations via Firestore Console

**Testing**
- Unit test: `addItem()` with valid data — verify Firestore `.add()` called with `userId` field present
- Unit test: `getItems()` stream — verify result excludes documents where `status == "resolved"`
- Unit test: `editItem()` — verify `editedAt` is included in the update payload
- Unit test: `deleteItem()` — verify `.delete()` is called on correct document reference

---

### 2.3 Keyword Search — Firestore Query

| Field | Detail |
|---|---|
| **WBS Code** | 2.3 |
| **Type** | Work Package |
| **Requirement** | Data Storage |

**Scope / Statement of Work**
Implement keyword search in `ItemService` using Firestore queries. Must return relevant Active items matching the keyword.

**Deliverables**
- `searchItems(String keyword)` method in `ItemService`
- Firestore prefix range query on `title` field
- Results filtered to Active items only
- Method integrated with Search Bar Widget

**Associated Activities**
- Implement prefix range query pattern for keyword matching
- Filter out Resolved items
- Connect to Search Bar Widget
- Validate against 10 keyword test cases

**Testing**
- Unit test: `searchItems("wallet")` — verify the Firestore query uses a `title` prefix range and filters by `status == "active"`
- Unit test: `searchItems("")` (empty keyword) — verify behavior is defined (either return empty list or return all Active items per agreed spec)
- Unit test: `searchItems()` returns a result set that includes only Active items (never Resolved)

---

### 2.4 Request & Approval System

| Field | Detail |
|---|---|
| **WBS Code** | 2.4 |
| **Type** | Work Package |
| **Requirement** | Data Storage |

**Scope / Statement of Work**
Implement the request and approval flow for both Seeker Posts and Founder Posts. For a **Founder Post**, Visitors send a **Claim Request** containing their name and contact info. For a **Seeker Post**, Visitors send a **Found Report** with a brief description of the item to verify they actually have it. The Poster receives requests and can approve or reject each one. Approving a request closes the post (status → "resolved"). Visitors can also **cancel (undo) their own pending request** at any time before it is approved or rejected. If a pending request exists, the Poster cannot delete the post until all requests are resolved.

**Deliverables**
- Firestore `requests` sub-collection under each item document:
  `requestId`, `requesterId`, `requesterName`, `requesterContact`, `message` (for Seeker Posts), `status` (pending / approved / rejected / cancelled), `createdAt`, `visitorAnswer` (for Claim Requests on Founder Posts with a secret question — see **2.10**), `editedAt` (Timestamp?, set when the requester edits a pending request — see **2.17**; approve/reject/cancel flows do not modify `editedAt`)
- Parent `items` document gains a `claimedBy` (requesterId) field when a request is approved (status → "resolved")
- `RequestService` Dart class: `submitRequest()`, `getRequestsForItem()`, `approveRequest()`, `rejectRequest()`, **`cancelRequest()`**
- "Claim Request" button on Founder Post Detail Screen (Visitors only)
- "Found Report" button on Seeker Post Detail Screen (Visitors only)
- Mini-form for Found Reports: description of item found (what it looks like, where found) + optional photo (max 1, uploaded to Firebase Storage)
- Request cards in Poster's inbox show attached photo thumbnail (Found Reports)
- Long descriptions truncated with "Read more" tap to open full request detail view
- Guard: if the Poster tries to delete a post with pending requests, show warning dialog — "Cannot delete post — resolve all pending requests first" with "View requests" and "Cancel" buttons
- Poster's request inbox on Detail Screen: list of pending requests with approve/reject buttons
- Approving a request sets item `status` to "resolved" and stores `claimedBy` (requesterId)
- **Visitor can cancel their own pending request**: "Cancel Request" button shown on the request detail view if `status == "pending"` and `requesterId == currentUser.uid`
- **Visitor can edit their own pending request** — see **2.17** (Request Edit) for full details; the Edit button shares the same visibility guard as Cancel

**Associated Activities**
- Design `requests` sub-collection schema in Firestore (including `visitorAnswer` for secret-question verification — see **2.10**)
- Create `request_service.dart` with all CRUD methods for requests including `cancelRequest()`
- Add "Claim Request" button to Founder Post Detail Screen for Visitors
- Build Claim Request form: requester name (auto-filled from profile), contact, optional message
- Add "Found Report" button to Seeker Post Detail Screen for Visitors
- Build Found Report form: text field for item description/location found, plus optional photo attachment (max 1 image uploaded to Firebase Storage)
- Build Poster request inbox view on Detail Screen: list of requests with approve/reject actions
- Implement approve flow: update request `status` → "approved", item `status` → "resolved", set `claimedBy`
- Implement reject flow: update request `status` → "rejected"
- **Implement cancel flow**: update request `status` → "cancelled"; show "Cancel Request" button only when `status == "pending"` and `requesterId == currentUser.uid`
- Guard deletion when pending requests exist

**Testing**
- Unit test: `RequestService.submitRequest()` — verify the new request doc includes `requesterId`, `requesterName`, `status == "pending"`, and `createdAt`
- Unit test: `RequestService.approveRequest()` — verify it performs a batched write that (a) sets request `status` to `approved`, (b) sets parent item `status` to `resolved`, and (c) writes `claimedBy` on the parent item
- Unit test: `RequestService.cancelRequest()` — verify `status` is updated to `cancelled`
- Widget test: render request detail as the requester with `status == "pending"` — verify "Cancel Request" button is visible
- Widget test: render request detail as a different user — verify "Cancel Request" button is hidden
- Widget test: Poster taps delete on a post with pending requests — verify warning dialog appears and deletion is blocked

---

### 2.4.1 Request Resubmit Policy

| Field | Detail |
|---|---|
| **WBS Code** | 2.4.1 |
| **Type** | Sub-Work Package (under 2.4) |
| **Requirement** | Request Lifecycle / Anti-Abuse |

**Scope / Statement of Work**
Define and enforce the policy for what happens after a request is rejected by the Poster — specifically whether and how a Visitor can submit a new request on the same post. WBS 2.4 specifies behavior for the `cancel` and `approve` flows but leaves the post-rejection state undefined. This sub-package fills that gap with two distinct policies based on the post's risk profile:

- **Claim Requests on Founder Posts with a Secret Question (high-risk — brute-force vector for `secretAnswer`):** maximum **3 rejected attempts** per Visitor per post (lifetime), then **permanent block** for that Visitor on that post.
- **All other requests** (Found Reports on Seeker Posts, and Claim Requests on Founder Posts *without* a Secret Question): **6-hour cooldown** between rejection timestamp and the next allowed submission. No permanent block.

The policy is enforced both in the Flutter client (UX feedback) and in Firestore security rules (defense in depth). No schema change is required — attempt counts are derived by querying the existing `requests` sub-collection filtered by `requesterId` and `status == "rejected"`.

**Deliverables**
- `RequestService.canResubmit(String itemId, String requesterId)` method returning a `ResubmitDecision` object: `{ allowed: bool, reason: String?, attemptsRemaining: int?, retryAfter: Timestamp? }`
- `RequestService.submitRequest()` updated to call `canResubmit()` before write — throws `ResubmitNotAllowedException` if denied
- `ResubmitDecision.reason` enum: `"allowed"`, `"permanent_block"`, `"cooldown"`, `"already_active"` (the last delegated to the existing 2.10 rule for active Claim Requests)
- Detail Screen UI updates (Visitor view):
  - When 1+ rejected attempts exist on a Secret Question post: button shows `"Incorrect answer. {n} attempt(s) remaining"` (`n` = attempts remaining)
  - When `permanent_block`: button replaced with disabled state showing `"You can no longer submit a request on this post"`
  - When `cooldown`: button replaced with countdown `"You can submit a new request in {hours}h {minutes}m"`
- Firestore security rules update (extends **5.2**) — `requests` create operation denied when:
  - For posts with `secretQuestion != null`: `requesterId` already has ≥ 3 documents with `status == "rejected"` in the same `requests` sub-collection, OR
  - For other posts: `requesterId` has a `status == "rejected"` document with `createdAt` newer than `now - 6h`
- Policy documented in `CONVENTIONS.md` (or team-shared schema doc per **2.1**) with rationale and enforcement layers

**Associated Activities**
- Implement `canResubmit()` in `request_service.dart` — uses Firestore query `where("requesterId", "==", currentUid).where("status", "==", "rejected")` and counts / sorts by `createdAt`
- Branch logic in `canResubmit()` based on the parent item's `secretQuestion` field (read once, cached for the call)
- Update `submitRequest()` to invoke `canResubmit()` first; convert `ResubmitNotAllowedException` to a user-facing error in the Claim Request / Found Report form
- Refactor Detail Screen Visitor button state to consume `ResubmitDecision` via a Riverpod provider
- Implement a countdown-timer widget for the cooldown state — refreshes once per minute and on screen-focus regain
- Add Firestore security-rule clauses for both policies; consult Firebase docs for query-in-rules constraints — may require a Cloud Function `beforeCreate` fallback if rules-side aggregate queries are unsupported
- Document policy and reasoning in the team conventions doc

**Notes & Out-of-Scope Decisions**
- **Poster cannot undo a rejection.** A rejected request stays rejected. If the Poster rejects by accident, the Visitor must wait for cooldown or use remaining attempts. Rationale: keep the state machine simple and avoid "undo" race conditions with the notification fired by **2.16 T4**.
- **Account-switching abuse is out of scope.** A locked Visitor could theoretically register a different `@mail.kmutt.ac.th` account and retry. This is accepted residual risk because (a) KMUTT accounts are non-trivial to provision and (b) cross-account identity correlation is outside the current threat model.
- **Cooldown duration (6h) and attempt limit (3) are constants** — not Remote Config flags. If tunability is needed later, a separate WP should add them to **2.13**.

**Acceptance Criteria**
- [ ] AC1: A Visitor with 3 rejected Claim Requests on a Secret Question post cannot submit a 4th — enforced in both the Flutter client and Firestore security rules
- [ ] AC2: A Visitor with a rejected Found Report (or rejected Claim Request on a non-Secret-Question post) must wait 6 hours from the rejection timestamp before the submit button becomes available again
- [ ] AC3: The Detail Screen displays the attempts-remaining message (Secret Question case) or the cooldown countdown (other cases) using the exact English copy specified in Deliverables
- [ ] AC4: Firestore security rules deny the `create` operation on the `requests` sub-collection when policy is violated, verified independently of the client via the Firebase Emulator
- [ ] AC5: All unit, widget, integration, and security-rules test cases listed in the Testing section pass
- [ ] AC6: Policy and rationale are documented in `CONVENTIONS.md`

**Dependencies**
- **Upstream (must be complete before starting):**
  - **2.4** Request & Approval System — provides `RequestService`, `submitRequest()`, and the `rejected` status flow
  - **2.10** Secret Question for Claim Request Verification — provides the `secretQuestion` field on items, needed to branch policy
  - **5.2** Security & Dependency Scans — provides the baseline Firestore security rules that this WP extends
- **Downstream (will be affected by this WP):**
  - **2.16** Push Notifications — T4 (Request rejected) notification copy may be updated in a follow-up iteration to mention remaining attempts
  - **7.1** Test Scripts — new test cases added to the test suite

**Risks & Mitigations**
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Firestore security rules cannot perform aggregate count queries, blocking rule-side enforcement | Medium | High | Fallback to a Cloud Function `beforeCreate` trigger that performs the count and rejects the write; client-side check remains the first line of defense |
| Legitimate item owner mistypes `secretAnswer` 3 times and is permanently locked out of a post | Low | High | Poster can be contacted manually via the item's `contact` field; a future WP may introduce a "Poster manual unlock" action — out of scope here |
| Cross-account abuse: a locked Visitor registers a second `@mail.kmutt.ac.th` account to retry | Low | Medium | Accepted residual risk; KMUTT accounts are non-trivial to provision and cross-account correlation is out of scope for this WP |
| Race condition: two near-simultaneous submits both pass `canResubmit()` on the client | Low | Low | Firestore security rules act as the final gatekeeper — at most one write succeeds; the second receives a permission-denied error |
| Cooldown countdown drifts during long-lived Detail Screen sessions | Low | Low | Refresh `ResubmitDecision` from `RequestService` whenever the screen regains focus, in addition to the 1-minute timer |

**Testing**
- Unit test: `canResubmit()` on Secret Question post with 0 rejected — verify returns `{ allowed: true, attemptsRemaining: 3 }`
- Unit test: `canResubmit()` on Secret Question post with 2 rejected — verify returns `{ allowed: true, attemptsRemaining: 1 }`
- Unit test: `canResubmit()` on Secret Question post with 3 rejected — verify returns `{ allowed: false, reason: "permanent_block" }`
- Unit test: `canResubmit()` on non-Secret-Question post with most-recent rejection 4 h ago — verify returns `{ allowed: false, reason: "cooldown" }` and `retryAfter` is approximately 2 h from now
- Unit test: `canResubmit()` on non-Secret-Question post with most-recent rejection 7 h ago — verify returns `{ allowed: true }`
- Unit test: `submitRequest()` when `canResubmit()` returns `{ allowed: false }` — verify `ResubmitNotAllowedException` is thrown and no document is written
- Widget test: render Detail Screen as Visitor on a Secret Question post with 2 rejected — verify button label contains `"1 attempt remaining"`
- Widget test: render Detail Screen as Visitor on a Secret Question post with 3 rejected — verify button is disabled and shows the permanent-block message
- Widget test: render Detail Screen as Visitor on a Seeker Post with rejection 4 h ago — verify countdown widget renders and shows approximately `"2h"`
- Integration test: with 3 rejected requests in Firestore, attempt to submit a 4th — verify both the client throws `ResubmitNotAllowedException` AND the Firestore security rule denies the write
- Security-rules test (Firebase Emulator): simulate authenticated user with 3+ rejected requests in the sub-collection — verify rule denies `create` on a new request document
- Security-rules test (Firebase Emulator): simulate authenticated user with most-recent rejection 4 h ago on a non-Secret-Question post — verify rule denies `create`

---

### 2.5 Local Storage (Preferences)

| Field | Detail |
|---|---|
| **WBS Code** | 2.5 |
| **Type** | Work Package |
| **Requirement** | Data Storage |

**Scope / Statement of Work**
Implement local storage using `shared_preferences` for **lightweight user preferences only** (e.g., theme choice, notification toggles, last-viewed category). Preferences are loaded at app startup and applied before first render. **The offline item-cache responsibility has been moved to 2.11 (Hive Offline-First Cache)** — this WP no longer caches Firestore data.

**Deliverables**
- `PreferenceService` Dart class wrapping `shared_preferences`, exposed through a Riverpod provider (see **4.2**)
- Typed getters/setters for defined preference keys (e.g., `themeMode`, `notificationsEnabled`)
- Preferences loaded on app startup and applied before first render
- Settings & Profile Screen (1.6) binds directly to `PreferenceService`

**Associated Activities**
- Add `shared_preferences` to `pubspec.yaml`
- Create `preference_service.dart` with typed get/set methods for each preference key
- Expose `PreferenceService` via a Riverpod provider
- Wire Settings Screen preference toggles to call the service on change
- Remove any references to item-caching from this WP (that work moves to **2.11**)

**Testing**
- Unit test: `PreferenceService.setThemeMode('dark')` followed by `getThemeMode()` — verify round-trip persistence
- Unit test: `getThemeMode()` on a fresh install (no saved value) — verify the documented default is returned
- Widget test: change a preference toggle in Settings — verify `PreferenceService.set*()` is called with the new value

---

### 2.6 Post Edit — Firestore Update

| Field | Detail |
|---|---|
| **WBS Code** | 2.6 |
| **Type** | Work Package |
| **Requirement** | Data Storage |

**Scope / Statement of Work**
Allow Posters to edit the details of their own posts after submission. The edit form pre-fills current values and saves changes back to Firestore. The item document stores an `editedAt` timestamp displayed on the Detail Screen as "Edited · [time]".

**Deliverables**
- Edit Post screen (reuses Post Form layout, pre-filled with existing data)
- Editable fields: title, description, location, occurredAt (date/time), contact, photos
- `editItem(String id, Map data)` method in `ItemService`
- Firestore update adds `editedAt: FieldValue.serverTimestamp()` on every save
- Detail Screen displays "Edited · [relative time]" label when `editedAt` is present
- Edit button visible only to Poster

**Associated Activities**
- Add edit icon to Detail Screen app bar (visible to Poster only)
- Navigate to Edit Post screen passing current item data
- Pre-populate all form fields with existing values
- Implement `ItemService.editItem()` using `.doc(id).update(data)` including `editedAt`
- Handle photo changes: upload new photos, remove deselected ones from Firebase Storage
- Display `editedAt` timestamp on Detail Screen using a relative time formatter

**Testing**
- Unit test: `ItemService.editItem()` — verify `editedAt: FieldValue.serverTimestamp()` included in payload
- Widget test: open Edit Post screen — verify all fields pre-populated with existing item values
- Widget test: save with empty title — verify validation error appears

---

### 2.7 Post Delete — Firestore Delete

| Field | Detail |
|---|---|
| **WBS Code** | 2.7 |
| **Type** | Work Package |
| **Requirement** | Data Storage |

**Scope / Statement of Work**
Allow Posters to delete their own posts. If the post has pending requests in its sub-collection, deletion is blocked and the Poster must resolve all requests first. If no pending requests exist, deletion proceeds after a confirmation dialog.

**Deliverables**
- Delete (trash) icon in Detail Screen app bar, visible to Poster only
- Confirmation dialog before deletion
- Guard: if pending requests exist, block deletion and show warning dialog with "View requests" button
- `deleteItem(String id)` method in `ItemService`
- Post removed from Feed in real time after deletion

**Associated Activities**
- Add trash icon to Detail Screen app bar (visible to Poster only)
- On tap: check `requests` sub-collection for any `status == "pending"` documents
- If pending requests exist: show warning dialog — "Resolve all requests before deleting" with "View requests" and "Cancel" buttons
- If no pending requests: show confirmation dialog — "Delete this post?" with confirm and cancel
- On confirm: call `ItemService.deleteItem()` using `.doc(id).delete()`
- Navigate back to Feed Screen after successful deletion

**Testing**
- Unit test: `ItemService.deleteItem()` — verify `.delete()` called on correct document ID
- Widget test: mock pending requests — verify delete shows warning dialog instead of confirmation
- Widget test: mock no pending requests — verify confirmation dialog appears before deletion

---

# WBS 2.8 (Revised) — Similar Posts Recommendation (Category-based)

> **Drop-in replacement** for the existing WBS 2.8 in `wbs_dictionary.md`, Phase 2.0 — Data Layer.
> **Replaces** the prefix-query implementation entirely with category-based filtering.
> Numbering preserved as **2.8** so all existing cross-references remain valid.

---

### 2.8 Similar Posts Recommendation

| Field | Detail |
|---|---|
| **WBS Code** | 2.8 |
| **Type** | Work Package |
| **Requirement** | Data Storage · Pages & Navigation |

**Scope / Statement of Work**

When a Visitor is composing a new **Seeker Post** (lost item) on the Post Form Screen, the app surfaces recently posted **Active Founder Posts** in the same item category, so the user can check whether their item has already been found before submitting a duplicate. This reduces feed clutter and helps users find their item faster.

Matching uses a single signal: the `itemCategory` field. When the Visitor selects a category from a fixed dropdown (e.g. `electronics`, `bag_wallet`, `documents_cards`), the panel queries Firestore for Active Founder Posts in that same category, sorted by `createdAt` descending, limited to 5 results. There is no keyword matching, no synonym handling, no scoring, and no AI/ML component — the algorithm is intentionally a simple bucket filter.

The category taxonomy is defined as a hard-coded enum in Dart (single source of truth in `lib/features/post/domain/entities/item_category.dart`). Adding or removing categories requires a code change and re-release.

When the Visitor selects category = "Founder Post" instead of "Seeker Post", the panel is hidden — recommendations are only shown to users searching for their lost items.

Sensitive items (per WBS 2.14) are always excluded from results regardless of category match.

**Deliverables**

- `ItemCategory` enum in `lib/features/post/domain/entities/item_category.dart` with the agreed taxonomy:
  - `electronics`, `bag_wallet`, `clothing`, `stationery`, `documents_cards`, `keys`, `accessory`, `other`
  - Each value carries a `displayNameTh` and `displayNameEn` (English shown in UI per CLAUDE.md rule)
- New Firestore field on `items/{itemId}`: `itemCategory: String` — required on every new post; stores the enum's `id`
- `ItemModel.fromJson` / `toJson` updated to round-trip the new field
- Category dropdown widget on Post Form Screen (`lib/features/post/presentation/widgets/category_picker.dart`) — required field, blocks submission if not selected
- `ItemRepository.getRecentInCategory({required String categoryId, int limit = 5})` method that returns Active Founder Posts in the given category, sorted by `createdAt` desc, with `isSensitive == false` filter mandatory
- `SimilarPostsPanel` widget (`lib/features/post/presentation/widgets/similar_posts_panel.dart`) that:
  - Renders nothing when post type is "Founder Post"
  - Renders nothing when no category selected
  - Renders nothing when query returns empty
  - Renders up to 5 cards with title, location, image thumbnail, and "Posted X minutes/hours/days ago" label
  - Tapping a card navigates to Detail Screen
- `similarItemsProvider` Riverpod provider (`@riverpod` codegen) wrapping the repository call, reactive to category selection changes
- Composite Firestore index: `(category ASC, itemCategory ASC, isSensitive ASC, status ASC, createdAt DESC)` deployed via `firestore.indexes.json`
- Backfill: existing items in Firestore (created before this WP) are missing `itemCategory`. Treat them as `other` via a one-shot lazy backfill — when an old item is read by any service, set its `itemCategory` to `other` if missing. No admin script needed at the project's current scale.
- Migration guard: `ItemService.createItem()` rejects writes that omit `itemCategory` (assertion in code; also enforced by Firestore rule)
- Firestore security rule: writes to `items/{itemId}` require `itemCategory` to be present and to be one of the enum values
- `wbs_dictionary.md` updated; `test_scripts.md` matrix gains rows for new tests

**Associated Activities**

- Define `ItemCategory` enum with `id`, `displayNameTh`, `displayNameEn` per value; commit to `domain/entities/`
- Add `itemCategory` field to `ItemModel` (`fromJson` reading the string, `toJson` writing the string)
- Build `CategoryPicker` widget — `DropdownButtonFormField<ItemCategory>` with validation
- Wire the category picker into Post Form Screen as a required field above the Description field
- Implement `ItemRepository.getRecentInCategory()` in the data layer with the four-filter query: `category == 'founder'`, `itemCategory == <selected>`, `isSensitive == false`, `status == 'active'`, ordered by `createdAt` desc, limit 5
- Implement `similarItemsProvider` using `@riverpod` codegen — re-fetches whenever the category dropdown value changes (no debounce needed; dropdown is discrete, not text input)
- Implement `SimilarPostsPanel` widget with the four conditional render rules above
- Deploy the composite Firestore index via `firebase deploy --only firestore:indexes`
- Update Firestore security rules to assert `itemCategory in [...]` on create
- Update Post Form widget tests to cover the required-field validation
- Implement lazy backfill in `ItemRepository.getById()` and `ItemRepository.getItems()`: if a returned item lacks `itemCategory`, write `itemCategory: 'other'` via a fire-and-forget update; this happens once per legacy item naturally as users browse
- Delete the old prefix-query implementation from the codebase
- Update `CROSS_PLATFORM.md` with screenshots of the category picker on Android and Web
- Update Weekly Orchestration Log in `ORCHESTRATION.md`

**Testing**

Unit tests:
- `test/features/post/data/repositories/item_repository_impl_test.dart` — `getRecentInCategory()` builds the correct Firestore query (verify `where` clauses include `category == 'founder'`, `itemCategory == <param>`, `isSensitive == false`, `status == 'active'`, `orderBy('createdAt', descending: true)`, `limit(5)`)
- `test/features/post/data/repositories/item_repository_impl_test.dart` — `getRecentInCategory()` with empty result → returns empty list, no exception
- `test/features/post/data/models/item_model_test.dart` — `ItemModel.fromJson` parses `itemCategory` correctly; `toJson` writes it correctly
- `test/features/post/data/models/item_model_test.dart` — `ItemModel.fromJson` with missing `itemCategory` → defaults to `other` (lazy backfill behavior)

Widget tests:
- `test/features/post/presentation/widgets/category_picker_test.dart` — submit Post Form without selecting category → validation error blocks submission
- `test/features/post/presentation/widgets/category_picker_test.dart` — select a category → form value updates and validation passes
- `test/features/post/presentation/widgets/similar_posts_panel_test.dart` — post type = Founder → panel returns `SizedBox.shrink()` regardless of category
- `test/features/post/presentation/widgets/similar_posts_panel_test.dart` — post type = Seeker, no category selected → panel hidden
- `test/features/post/presentation/widgets/similar_posts_panel_test.dart` — post type = Seeker, category selected, query returns empty → panel hidden
- `test/features/post/presentation/widgets/similar_posts_panel_test.dart` — post type = Seeker, category selected, query returns 3 items → panel renders 3 cards in `createdAt` desc order
- `test/features/post/presentation/widgets/similar_posts_panel_test.dart` — tap a card → navigates to Detail Screen with correct item id

Provider tests:
- `test/features/post/presentation/providers/similar_items_provider_test.dart` — when category provider value changes, `getRecentInCategory()` is called once with the new category
- `test/features/post/presentation/providers/similar_items_provider_test.dart` — when post type is Founder, provider returns empty without calling the repository

Firestore rules tests:
- `test/firestore_rules/item_category.test.js` — create item without `itemCategory` field → denied
- `test/firestore_rules/item_category.test.js` — create item with `itemCategory: "invalid_value"` → denied
- `test/firestore_rules/item_category.test.js` — create item with valid `itemCategory: "electronics"` → allowed

Sensitive item integration:
- `test/features/post/data/repositories/item_repository_impl_test.dart` — `getRecentInCategory()` always filters `isSensitive == false`, even when the candidate category contains sensitive items (e.g. `documents_cards`)

---

## Cross-references to update in other WBS documents

Because this is a **revision in place** (still WBS 2.8), no other WBS numbering changes. However:

- **WBS 1.4 (Post Form Screen)** — add bullet to Deliverables: "Category dropdown (required) above Description field; values from `ItemCategory` enum"
- **WBS 2.1 (Firestore Schema)** — add `itemCategory: String (required)` to the `items/{itemId}` schema documentation
- **WBS 2.2 (Firestore CRUD)** — note that `addItem()` now requires `itemCategory` in the data map; assertion added
- **WBS 2.14 (Sensitive Items)** — confirm the `getRecentInCategory()` query filters `isSensitive == false`. The mandatory test in WBS 2.14 (sensitive items never appear) now also covers similar-posts results. No taxonomy change — sensitive subcategories are not part of the new enum; the existing `isSensitive` boolean remains the source of truth.
- **WBS 7.1 (Test Scripts & Traceability Matrix)** — add 4 unit tests + 7 widget tests + 2 provider tests + 3 rules tests = **16 new test files** to the matrix under Phase 2.0
- **`CLAUDE.md`** — no change needed; no new flags, no new services, no new layer rules

---

## What changed from the previous WBS 2.8

| Aspect | Old WBS 2.8 | New WBS 2.8 |
|---|---|---|
| Match algorithm | Firestore prefix range query on `title` field | Category-based filter (`itemCategory` field equality) |
| Required user input | Just type a title | Type title + select category from dropdown |
| Cross-language match | ❌ | ✅ (same category regardless of language) |
| Match quality | Low (string-based) | Medium (category bucket — wide net) |
| False positive rate | Medium | Higher — all items in category appear, no narrowing |
| Sensitive item filter | Not enforced | Mandatory, server-side |
| Cloud Functions added | 0 | 0 |
| New Firestore fields | 0 | 1 (`itemCategory`) |
| New Remote Config keys | 0 | 0 |
| Cost | $0 | $0 |
| Effort estimate | 2-3 days (original) | **0.5-1 day** |

---

## Counts (for v5.x change summary)

- Existing work package revised in place: 1 (WBS 2.8)
- New Cloud Functions: 0
- New Firestore fields on `items`: 1 (`itemCategory`)
- New Remote Config keys: 0
- New Flutter files: 4 (1 enum, 1 picker widget, 1 panel widget, 1 provider)
- New tests: 4 unit + 7 widget + 2 provider + 3 rules = **16**
- Estimated effort: **0.5-1 day** for one developer
- WBS total work-package count: **unchanged at 37**

---

## Suggested taxonomy (subject to team review)

```dart
enum ItemCategory {
  electronics(id: 'electronics',      th: 'อุปกรณ์อิเล็กทรอนิกส์',     en: 'Electronics'),
  bagWallet(id: 'bag_wallet',         th: 'กระเป๋าและกระเป๋าสตางค์',  en: 'Bag & Wallet'),
  clothing(id: 'clothing',            th: 'เสื้อผ้า',                  en: 'Clothing'),
  stationery(id: 'stationery',        th: 'เครื่องเขียนและหนังสือ',    en: 'Stationery & Books'),
  documentsCards(id: 'documents_cards', th: 'เอกสารและบัตร',           en: 'Documents & Cards'),
  keys(id: 'keys',                    th: 'กุญแจ',                    en: 'Keys'),
  accessory(id: 'accessory',          th: 'เครื่องประดับและของใช้',    en: 'Accessory'),
  other(id: 'other',                  th: 'อื่นๆ',                    en: 'Other');
}
```

8 categories — small enough that the dropdown does not need search, large enough to give meaningful narrowing.

**Note on sensitive categories:** `documents_cards` and `keys` are commonly sensitive (per WBS 2.14 default list), but `itemCategory` and `isSensitive` are independent fields. The user can still select `documents_cards` for a non-sensitive subset (e.g., a notebook with handwritten notes that happens to be in the documents bucket), and the post-form's "is sensitive" toggle (WBS 2.14) controls the sensitive flag separately.

---

### 2.9 REST API for External Integration

| Field | Detail |
|---|---|
| **WBS Code** | 2.9 |
| **Type** | Work Package |
| **Requirement** | Data Storage · External Integration |

**Scope / Statement of Work**
Expose a read-only REST API on top of Firestore using **Firebase Cloud Functions** (Node.js), allowing external tools (e.g. modlink or other integrations) to query the `items` collection without direct Firestore SDK access. The API is protected by an **API Key** passed in the request header. Only Active items are returned. This is a read-only endpoint — no write operations are exposed.

**Deliverables**
- Firebase Cloud Function (`functions/index.js`) exposing `GET /items` endpoint
- Query params: `category` (seeker/founder), `keyword` (optional title filter), `limit` (default 20)
- Response: JSON array of Active items `{ id, title, category, description, location, contact, imageUrls, createdAt }`
- API Key validation via `x-api-key` request header (key stored in Firebase environment config / Secret Manager)
- Returns `401 Unauthorized` when API key is missing or invalid
- Returns `400 Bad Request` on invalid query params
- API Key document shared with the team (stored securely — not committed to git)

**Associated Activities**
- Set up Firebase Cloud Functions in the project (`firebase init functions`)
- Install dependencies: `firebase-functions`, `firebase-admin`, `cors`
- Implement `GET /items` handler with Firestore query filtered by `status == "active"`
- Add `category` and `keyword` filter support
- Generate API Key string and store via `firebase functions:config:set` or Secret Manager
- Implement header-based API Key validation middleware
- Deploy function with `firebase deploy --only functions`
- Document endpoint URL, query params, and API Key in a `API_DOCS.md` file
- Share API Key securely with team members (e.g. via encrypted message — never commit to git)

**Testing**
- Test `GET /items` with valid API Key — verify JSON response with Active items only
- Test `GET /items` with missing/invalid API Key — verify `401` response
- Test `GET /items?category=founder` — verify only Founder Posts returned
- Test `GET /items?keyword=wallet` — verify keyword filtering works

---

### 2.10 — Secret Question for Claim Request Verification

| Field | Detail |
|-------|--------|
| WBS Code | 2.10 |
| Type | Work Package |
| Requirement | Data Storage · Pages & Navigation |

---

**Scope / Statement of Work**

When a Poster creates a Founder Post (found item), they may optionally set a Secret Question — a short question whose correct answer only the true owner of the item would know (e.g. "What brand is printed on the inside of the wallet?"). The Poster also privately records the expected answer at post-creation time. No answer is shown to anyone publicly.

When a Visitor (potential owner) submits a Claim Request on that Founder Post, they must provide their own answer to the secret question before the request can be sent — without any hints from the app. **A Visitor may only have one active Claim Request per post at a time. To submit a new request, the Visitor must first cancel their existing one.**

The Poster then reviews each Claim Request and manually compares the Visitor's submitted answer against the expected answer they set. Answer comparison is **manual and case-insensitive at the Poster's discretion** — the app displays both answers side by side but does not auto-match or score them. The Poster uses it as one verification factor before approving or rejecting. The expected answer is never exposed to Visitors at any point.

Secret Question is **not applicable when `isSensitive: true`** on a Founder Post — the `secretQuestion` and `secretAnswer` fields are hidden on the Post Form, and no answer field is shown on the Claim Request form.

Found Reports on Seeker Posts do not involve Secret Questions — Seeker Posts do not have a secret question field and no answer is required from the Visitor.

---

**Photo Safety Guard (sub-plan within 2.10)**

A Poster who sets a Secret Question could accidentally undermine the verification by attaching a photo that visually reveals the answer (e.g. a close-up of the wallet interior showing the brand name). The guard covers two directions:

**Case 1 — Secret Question filled first, then photo added**
Whenever the Poster taps "Add Photo" on a Founder Post form where the Secret Question field is already filled, the app intercepts the file-picker launch and displays a Photo Safety Warning dialog. The Poster must explicitly confirm before the image picker opens.

**Case 2 — Photo added first, then Secret Question filled**
Whenever the Poster fills in the Secret Question field and photos already exist on the form, the app immediately displays the same Photo Safety Warning dialog — this time as a review prompt, asking the Poster to check that existing photos do not reveal the answer. The Poster must confirm or remove the photos before proceeding.

Both cases use the same `PhotoSafetyWarningDialog` widget. The guard applies on both the initial post-creation form and the post-edit form. It is skipped when no Secret Question has been entered, and skipped entirely for Seeker Posts and sensitive posts.

---

**Deliverables**

- Optional `secretQuestion` field and a private `secretAnswer` field added to the Founder Post creation form (Post Form Screen), shown only when category is "Founder Post" and `isSensitive` is false
- `secretQuestion (String?)` and `secretAnswer (String?)` stored as plain text in the Firestore items document; `secretAnswer` is readable only by the Poster (Firestore security rules)
- `secretQuestion` is displayed on the Claim Request form when the target Founder Post has one set, requiring the Visitor to fill in their own answer before submitting — no hints or expected answer shown
- **One active Claim Request per Visitor per post enforced** — if a Visitor already has a pending or approved request on a post, the Claim Request button is replaced with a "Cancel Request" option. A new request can only be submitted after cancellation
- Visitor's submitted answer stored as `visitorAnswer` in the requests sub-collection document
- `visitorAnswer` is editable by the requester while `status == "pending"` (see **2.17** — Request Edit). The Verification section the Poster sees re-renders with the latest answer, and the request's `editedAt` timestamp signals that the answer changed since the Poster last looked. Editing reuses the same request document, so the "one active Claim Request per Visitor per post" rule is preserved
- Request Detail screen (Poster view only) displays a "Verification" section: the question, the Poster's expected answer, and the Visitor's submitted answer side by side for manual comparison. A note in the UI reminds the Poster that comparison is manual
- `secretQuestion` and `secretAnswer` are hidden from all Visitor-facing views (Feed, Detail Screen, Claim Request form result)
- Found Report form on Seeker Posts has no answer field — Secret Question does not apply
- `PhotoSafetyWarningDialog` widget — used in both guard cases:
  - **Title:** "Check your photo before adding"
  - **Body:** "Make sure the photo you are about to add does not show, contain, or hint at the answer to your secret question. If it does, anyone who sees the post could guess the answer and submit a fraudulent claim."
  - **Examples to avoid (bulleted):** close-ups that show a distinguishing mark, brand label, serial number, colour pattern, or any detail that the question is asking about
  - **Actions:** "Cancel" (secondary) and "I understand, add photo" (primary)
  - For Case 2 (existing photos when Secret Question is filled), the dialog body is adjusted: "You already have photos on this post. Please make sure none of them show, contain, or hint at the answer to your secret question."
  - Dialog fires every qualifying time — not suppressed after first confirmation

---

**Associated Activities**

- Add optional `secretQuestion (String?)` and `secretAnswer (String?)` fields to the Post Form Screen UI, shown only when category is "Founder Post" and `isSensitive` is false
- Store both fields in the Firestore items document via `ItemService.createItem()`
- In `RequestService.submitClaimRequest()`:
  - Check if Visitor already has an active request on this post — if yes, block submission and prompt to cancel first
  - Check if the target Founder Post has a `secretQuestion` set
  - If a question exists, require a non-empty `visitorAnswer` before allowing submission; do not display or hint at the expected answer
- Save `visitorAnswer` as a field on the request document in the requests sub-collection
- Update Request Detail Screen (Poster view) to show a "Verification" section: question, expected answer (`secretAnswer`), and the Visitor's answer (`visitorAnswer`) side by side with a manual comparison note
- Apply Firestore security rules so `secretAnswer` is readable only by the document owner (Poster); `visitorAnswer` is readable only by the Poster
- Hide the `secretQuestion` display and all answer fields from the Detail Screen when the viewer is a Visitor
- On Detail Screen (Visitor view): if Visitor already has an active request, show "Cancel Request" instead of "Send Claim Request"
- Photo Safety Guard — Case 1 (add photo while Secret Question is filled):
  - Intercept every "Add Photo" tap (create and edit flows)
  - Guard condition: `category == FounderPost && isSensitive == false && secretQuestionController.text.isNotEmpty`
  - If true, `await showDialog(PhotoSafetyWarningDialog)` — open picker only if confirmed; abort if cancelled
  - If false, open picker directly
- Photo Safety Guard — Case 2 (Secret Question filled while photos already exist):
  - Listen to `secretQuestionController` changes in Post Form Screen
  - When `secretQuestion` becomes non-empty and `imageList.isNotEmpty` and `category == FounderPost` and `isSensitive == false` → show `PhotoSafetyWarningDialog` (review variant)
  - Poster must confirm or remove photos before the form allows further interaction
- Build `PhotoSafetyWarningDialog` as a stateless `AlertDialog` widget accepting a `isReview: bool` parameter to switch between Case 1 and Case 2 body text
- No persistent flag — dialog fires on every qualifying event by design

---

## Testing

**Secret Question core:**
- Unit test: `ItemService.createItem()` with `secretQuestion` set — verify both `secretQuestion` and `secretAnswer` saved to Firestore
- Widget test: Post Form with category = Founder Post, `isSensitive` = false — verify fields appear; switch to Seeker Post — verify hidden; set `isSensitive` = true — verify hidden
- Widget test: Claim Request form on a Founder Post with secret question — verify answer field required, blocks if empty, expected answer not shown
- Widget test: Claim Request form on a Founder Post without secret question — verify no answer field
- Unit test: `RequestService.submitClaimRequest()` — verify `visitorAnswer` saved to request document
- Widget test: Request Detail Screen as Poster — verify Verification section shows question, expected answer, visitor answer, and manual comparison note

**One active request per Visitor per post:**
- Unit test: `RequestService.submitClaimRequest()` when Visitor already has active request — verify blocked
- Widget test: Detail Screen (Visitor view) with active request — verify "Send Claim Request" replaced with "Cancel Request"
- Widget test: Visitor cancels → verify "Send Claim Request" reappears

**Found Report (no secret question):**
- Widget test: Found Report form on Seeker Post — verify no answer field

**Photo Safety Guard — Case 1 (photo added after Secret Question):**
- Widget test: secret question non-empty → tap "Add Photo" → verify dialog appears
- Widget test: dialog → tap "Cancel" → verify picker not launched
- Widget test: dialog → tap "I understand, add photo" → verify picker launched
- Widget test: secret question empty → tap "Add Photo" → verify no dialog, picker launches directly
- Widget test: category = Seeker Post → tap "Add Photo" → verify no dialog
- Widget test: `isSensitive` = true → tap "Add Photo" → verify no dialog
- Widget test: tap "Add Photo" twice with secret question non-empty → verify dialog appears both times
- Widget test: Post Edit Screen with existing secret question → tap "Add Photo" → verify dialog appears

**Photo Safety Guard — Case 2 (Secret Question filled after photos exist):**
- Widget test: photos already added → fill Secret Question field → verify review dialog appears immediately
- Widget test: review dialog → tap "Cancel" → verify photos remain and Secret Question field is cleared
- Widget test: review dialog → tap "I understand, add photo" → verify dialog dismissed and form proceeds normally
- Widget test: photos exist but category = Seeker Post → fill any field → verify no dialog
- Widget test: photos exist, `isSensitive` = true → fill Secret Question → verify no dialog
- Widget test: no photos on form → fill Secret Question → verify no dialog triggered
---

### 2.11 Hive Offline-First Cache

| Field | Detail |
|---|---|
| **WBS Code** | 2.11 |
| **Type** | Work Package |
| **Requirement** | Data Storage · Offline-First |

**Scope / Statement of Work**
Implement offline-first caching using **Hive** as the local NoSQL store. The `items` feed and the current user's profile are mirrored to Hive on every successful Firestore fetch (write-through pattern). When online, Firestore is the source of truth. When offline, the UI reads from Hive and shows an "Offline · Showing cached data" banner. **Supersedes the item-cache portion of 2.5.**

**Deliverables**
- `hive`, `hive_flutter`, `hive_generator`, `connectivity_plus` added to `pubspec.yaml`
- Hive boxes: `items_box`, `user_profile_box`, `sync_metadata_box`
- `@HiveType` adapters generated for `Item` and `User` Domain entities (from **4.1**) via `build_runner`
- Hive initialized in `main.dart` before `runApp()`
- `ItemRepository` (implementation layer of **4.1**) updated to: (1) on Firestore fetch success, write-through to Hive; (2) when offline, read from Hive
- "Offline · Showing cached data" banner on Feed Screen when the data source is Hive
- `last_synced_at` timestamp stored in `sync_metadata_box` and surfaced on the offline banner
- Connectivity stream via `connectivity_plus` drives online/offline switching

**Associated Activities**
- Add Hive and `connectivity_plus` packages; run `flutter pub get`
- Initialize Hive in `main.dart` with `await Hive.initFlutter()`
- Annotate Domain entities (`Item`, `User`) with `@HiveType` and `@HiveField`; run `dart run build_runner build`
- Register adapters at startup
- Update `ItemRepository` concrete class to implement write-through on success + read-from-Hive on offline
- Subscribe to `Connectivity().onConnectivityChanged`; expose connectivity as a Riverpod provider
- Update Feed Screen to render the offline banner when connectivity provider reports offline
- Remove item-cache logic from 2.5 (`PreferenceService`)

**Testing**
- Unit test: `ItemRepository.getItems()` with mocked offline state — verify read from Hive, not Firestore
- Unit test: `ItemRepository.getItems()` with online state — verify Firestore fetch and Hive write-through both occur
- Widget test: simulate offline via provider override — verify offline banner is visible and cached items render
- Integration test: kill network connectivity after Feed loads — verify app remains functional and shows cached data with the offline banner

---

### 2.12 Crashlytics & Structured Logging

| Field | Detail |
|---|---|
| **WBS Code** | 2.12 |
| **Type** | Work Package |
| **Requirement** | Observability |

**Scope / Statement of Work**
Integrate Firebase Crashlytics to capture fatal and non-fatal errors from production builds, with a structured logging layer (`AppLogger`) that attaches breadcrumbs and custom keys (user ID, current route, app version, action). All uncaught Flutter and zone errors are routed to Crashlytics. Debug builds log to console only; release builds also report to Crashlytics. Note: Crashlytics is **not supported on Web**; Web platform errors are captured via structured logging to a separate sink.

**Deliverables**
- `firebase_crashlytics` added to `pubspec.yaml`
- Crashlytics initialized in `main.dart`:
  - `FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError`
  - `PlatformDispatcher.instance.onError` forwards to `recordError()`
  - `runApp` wrapped in `runZonedGuarded`
- Custom keys attached at session start: `userId`, `appVersion`, `platform`; `currentRoute` updated by GoRouter observer
- `AppLogger` class with `info / warn / error` methods: debug → console; release → Crashlytics breadcrumb + (for `error`) `recordError()`
- Hidden debug-menu buttons for triggering a test fatal and a test non-fatal crash
- `OBSERVABILITY.md` documenting log levels, breadcrumb conventions, platform scope (Crashlytics on mobile; console-only on Web), and how to view the Crashlytics dashboard

**Associated Activities**
- Add the `firebase_crashlytics` package
- Configure native Crashlytics for Android (Web note: log to console only)
- Implement the error-routing setup in `main.dart` with a `kIsWeb` guard for Crashlytics calls
- Implement `AppLogger` with debug/release switching via `kReleaseMode`
- Hook a GoRouter observer to update the `currentRoute` custom key
- Add debug-only "trigger test crash" buttons in Settings
- Write `OBSERVABILITY.md`

**Testing**
- Manual test: trigger test fatal in a release build on Android — verify it appears in the Crashlytics dashboard within the documented window
- Manual test: trigger test non-fatal — verify it appears with correct custom keys attached
- Unit test: `AppLogger.error()` in release mode — verify `FirebaseCrashlytics.instance.recordError()` is called
- Unit test: `AppLogger.info()` in debug mode — verify it only prints to console and does NOT call Crashlytics

---

### 2.13 Feature Flag via Remote Config & Rollback Plan

| Field | Detail |
|---|---|
| **WBS Code** | 2.13 |
| **Type** | Work Package |
| **Requirement** | Reliability · Feature Flags |

**Scope / Statement of Work**
Gate at least one major feature behind a Firebase Remote Config boolean flag so it can be disabled remotely within minutes without a rebuild. **The flagged feature is 2.10 Secret Question** (`secret_question_enabled`). A documented rollback plan specifies exact steps to disable the feature, expected rollback time, and post-rollback verification steps.

**Deliverables**
- `firebase_remote_config` added to `pubspec.yaml`
- Remote Config parameter defined in Firebase Console: `secret_question_enabled` (boolean, default `true`)
- In-app default values shipped with the binary as a safety net (used when Remote Config has never been fetched)
- `FeatureFlagService` Dart class with typed getters, exposed via Riverpod provider
- `FeatureFlagService.fetchAndActivate()` called in `main.dart`; minimum fetch interval documented (e.g., 1 hour in production, 0 in debug)
- Secret Question UI and logic (2.10) conditionally rendered based on the flag
- `ROLLBACK_PLAN.md` containing:
  - Exact click-path to toggle `secret_question_enabled` to `false` in Firebase Console
  - Expected propagation time (depends on min-fetch-interval)
  - Post-rollback verification checklist
  - On-call contact list
- **In-app surfaces** — the `RemoteConfigViewerScreen` (read-only viewer) and `RollbackPlanScreen` (interactive runbook mirroring `ROLLBACK_PLAN.md`) are scoped under **2.18** and gated by the admin role. The Firebase Console remains the only place Remote Config values can be **edited**; the in-app screen exists for visibility, not for writing.

**Associated Activities**
- Enable Remote Config in Firebase Console; create `secret_question_enabled` parameter
- Add `firebase_remote_config` package
- Implement `FeatureFlagService` with defaults registered via `setDefaults()`
- Call `fetchAndActivate()` at app startup with graceful fallback
- Expose as Riverpod `featureFlagsProvider`
- Wrap all 2.10 UI and service code paths in `ref.watch(featureFlagsProvider).isSecretQuestionEnabled` checks
- Write `ROLLBACK_PLAN.md`

**Testing**
- Unit test: `FeatureFlagService.isSecretQuestionEnabled` with mocked Remote Config = `true` — verify enabled path
- Unit test: same with mocked value = `false` — verify disabled path (fields hidden, request submits without `visitorAnswer`)
- Widget test: Post Form Screen with flag disabled — verify secret-question fields are hidden even on Founder Post category
- Manual test: toggle the flag in Firebase Console, wait for fetch interval, cold-restart app — verify UI reflects the change
- Manual test: cold-start with no network — verify in-app default is applied (fail-safe)

---

### 2.14 Sensitive Item Handling & Auto-Expire

| Field | Detail |
|-------|--------|
| **WBS Code** | 2.14 |
| **Type** | Work Package |
| **Requirement** | Data Storage · Pages & Navigation |

**Scope / Statement of Work**
Some found items (financial cards, ID cards, passports, keys, documents) cannot safely or reliably be verified or returned through an in-app flow. For these items, the app's role is notification only — directing the Seeker to contact the security office rather than facilitating an in-app handover.

When a Founder creates a post, they choose between **General** or **Sensitive** as the item type. Sensitive posts disable the Claim Request flow entirely and display a security office contact number instead. The sensitive item taxonomy (list of categories that count as sensitive) is managed via Firebase Remote Config so it can be updated without releasing a new app version.

Sensitive posts are resolved either manually by the Founder (after handing the item to security) or automatically after **14 days** via a scheduled Cloud Function.

**Deliverables**
- Item type selector (General / Sensitive) added to Post Form Screen, shown only on Founder Posts
- Sensitive Founder Posts: `description` and `contact` fields hidden; Secret Question disabled; only `category`, `location`, and `photo` allowed
- Feed and Detail Screen: sensitive posts display a warning banner — "This is a sensitive item — cannot be claimed through the app" — plus a "Contact Security Office" button with phone number pulled from Remote Config
- No Claim Request or Found Report buttons shown on sensitive posts
- Founder retains the Resolve button on sensitive posts
- Scheduled Cloud Function (`autoExpireSensitivePosts`) runs daily — queries Firestore for sensitive posts where `expiresAt <= now` and `status == "active"`, batch-updates them to `status: "expired"`
- Expired posts hidden from Feed and search results but remain in Firestore for audit
- `isSensitive: bool` and `expiresAt: Timestamp?` added to items Firestore schema
- `sensitive_categories` string array added to Remote Config (e.g. `["credit_card","id_card","passport","key","document"]`)
- Security office phone number stored in Remote Config as `security_office_contact`

**Associated Activities**
- Add `isSensitive` and `expiresAt` fields to `ItemModel` (`fromJson`/`toJson`) and `Item` entity
- Add item type selector widget to Post Form Screen; on selection of Sensitive, hide description/contact/Secret Question fields and set `expiresAt = now + 14 days`
- Update `ItemService.createItem()` to write `isSensitive` and `expiresAt`
- Update Feed Screen and Detail Screen to read `isSensitive` and conditionally render warning banner + security office contact button
- Remove Claim Request / Found Report buttons from Detail Screen when `isSensitive == true`
- Add `sensitive_categories` and `security_office_contact` keys to Firebase Remote Config; read via `FeatureFlagService`
- Write `autoExpireSensitivePosts` Cloud Function (Node 22, scheduled via Firebase Cloud Scheduler, `asia-southeast1`)
- Update Firestore security rules: `isSensitive` and `expiresAt` may only be set at creation, not mutated by client after the fact
- Update REST API (`GET /items`) to redact `contact`, `description`, and personal fields for sensitive items — expose only `category`, `location`, `createdAt`, `isSensitive`

**Testing**
- Unit test: `ItemService.createItem()` with `isSensitive: true` — verify `expiresAt` is set to approximately now + 14 days
- Widget test: Post Form with category = Founder Post → select Sensitive type → verify description, contact, and Secret Question fields are hidden
- Widget test: Detail Screen with `isSensitive: true` (Visitor view) — verify warning banner shown, Claim Request button absent, security office contact button present
- Widget test: Detail Screen with `isSensitive: true` (Poster view) — verify Resolve button still present
- Unit test: `autoExpireSensitivePosts` Cloud Function — mock Firestore with one post where `expiresAt < now` and `status: "active"` → verify status updated to `"expired"`
- Unit test: `autoExpireSensitivePosts` — post where `expiresAt > now` → verify status unchanged
- API test: `GET /items` with a sensitive item in Firestore — verify response omits `contact` and `description`, includes `isSensitive: true`
- Firestore rules test: client tries to update `isSensitive` after creation — verify denied

---

### 2.15 QR Walk-in Web Form

| Field | Detail |
|-------|--------|
| **WBS Code** | 2.15 |
| **Type** | Work Package |
| **Requirement** | Data Storage · Pages & Navigation |

**Scope / Statement of Work**
A lightweight bilingual (Thai/English) web form accessible via a static QR code placed at physical lost & found drop-off points on campus (security office, library, canteen, etc.). Anyone — including non-students and visitors — can scan the QR, fill in a short form, and submit a found item directly into Firestore without needing a KMUTT account or the app.

Walk-in submissions are written as Founder Posts with `source: "qr_walk_in"` and publish immediately with no moderation step. The sensitive item taxonomy applies — if a sensitive category is selected, a warning message is shown recommending the finder hand the item to the security office, but submission is not blocked.

Spam protection is handled via rate limiting per IP and Google reCAPTCHA v3. The QR code is a static printable link with no expiry.

**Deliverables**
- Bilingual (TH/EN) HTML web form hosted on Firebase Hosting
  - Fields: item category (dropdown), location found (text), description (optional), contact (optional), photo upload (optional)
  - Language toggle button (TH ↔ EN)
  - Sensitive category warning message (shown if sensitive category selected, does not block submit)
- `POST /items` endpoint added to Cloud Functions — accepts anonymous walk-in submissions, writes to Firestore with `source: "qr_walk_in"`, `status: "active"`, and `isSensitive` derived from the category
- Rate limiting: max 5 submissions per IP per hour
- Google reCAPTCHA v3 integration on the web form
- `source: "app" | "qr_walk_in"` field added to items Firestore schema
- Static QR code image + A4 print template (PDF) linking to the web form URL
- Optional: "Walk-in" badge on Founder Posts in the app Feed where `source == "qr_walk_in"`

**Associated Activities**
- Write bilingual HTML/CSS/JS web form; deploy to Firebase Hosting
- Add `POST /items` Cloud Function endpoint with input validation and rate limiting
- Integrate reCAPTCHA v3: verify token server-side in the Cloud Function before writing to Firestore
- Add `source` field to `ItemModel` (`fromJson`/`toJson`) and `Item` entity
- Update `ItemService` and Feed Screen to handle `source` field
- Generate static QR code linking to the hosted form URL
- Design and export A4 print template for physical placement
- Update Firestore security rules: `source` field writable only by Cloud Function service account, not by app clients

**Testing**
- Integration test: submit valid form via `POST /items` → verify Firestore document created with correct fields including `source: "qr_walk_in"`
- Integration test: submit with missing required fields (category, location) → verify 400 response
- Integration test: submit 6 times from same IP within 1 hour → verify 6th request returns 429 Too Many Requests
- Integration test: submit with invalid reCAPTCHA token → verify request rejected
- Integration test: submit with sensitive category → verify `isSensitive: true` in Firestore document
- Widget test (app): Feed Screen with a walk-in post in the list — verify "Walk-in" badge rendered when `source == "qr_walk_in"`
- Firestore rules test: app client tries to write `source: "qr_walk_in"` directly — verify denied

---

### 2.16 Push Notifications

| Field | Detail |
|-------|--------|
| **WBS Code** | 2.16 |
| **Type** | Work Package |
| **Requirement** | Data Storage · Pages & Navigation |

**Scope / Statement of Work**
Notify users via Firebase Cloud Messaging (FCM) push notifications when activity occurs on their posts or requests. Notifications are delivered through Cloud Functions triggered by Firestore document events — no in-app notification inbox is included in this scope.

Four events trigger a notification:

- **T1 — New Claim Request:** a Visitor submits a Claim Request on a Founder Post → notify the Poster. Only triggered when `source == "app"`; walk-in submissions (`source: "qr_walk_in"`) do not trigger a notification because the submitter is a guest with no app account.
- **T2 — New Found Report:** a Visitor submits a Found Report on a Seeker Post → notify the Poster.
- **T3 — Request approved:** Poster approves a request → notify the Visitor (requester).
- **T4 — Request rejected:** Poster rejects a request → notify the Visitor (requester).

Notification text is in English only, matching the app language. For sensitive posts (`isSensitive: true`), the item title is included in the notification body — the notification itself does not expose any redacted fields (contact, description). FCM tokens are stored as an array on the user's Firestore document and are cleaned up automatically when stale.

**Deliverables**
- `firebase_messaging` package added to `pubspec.yaml`
- FCM token management in `NotificationService`:
  - `registerToken()` — calls `FirebaseMessaging.instance.getToken()` and writes the token to `users/{uid}.fcmTokens` via `arrayUnion`; called after every successful login
  - `unregisterToken()` — removes the current token from `users/{uid}.fcmTokens` via `arrayRemove`; called on `signOut()`
- Notification permission request shown to the user after first successful login (required on iOS; required on Android 13+)
- Notification toggle ("Receive notifications") in Settings & Profile Screen (1.6) bound to `users/{uid}.notificationsEnabled`; Cloud Functions check this flag before sending
- `users/{uid}` Firestore document gains two new fields: `fcmTokens: [String]` and `notificationsEnabled: bool` (default `true`)
- Cloud Function `onNewRequest` — `onDocumentCreated` trigger on `items/{itemId}/requests/{requestId}`:
  - Skips if `request.source == "qr_walk_in"` (guest submission — no Poster account to notify)
  - Reads `items/{itemId}.userId` to identify the Poster
  - Reads `users/{posterId}.fcmTokens` and `notificationsEnabled`
  - Sends FCM notification to all Poster tokens if `notificationsEnabled == true`
  - Stale token cleanup: on `messaging/registration-token-not-registered` error, removes the token from `fcmTokens` via `arrayRemove`
- Cloud Function `onRequestStatusChange` — `onDocumentUpdated` trigger on `items/{itemId}/requests/{requestId}`:
  - Fires only when `status` field changes from `pending` → `approved` or `pending` → `rejected`
  - Reads `users/{requesterId}.fcmTokens` and `notificationsEnabled`
  - Sends FCM notification to all Visitor tokens if `notificationsEnabled == true`
  - Same stale token cleanup as above
- Notification payloads (all in English):

  | Event | Title | Body |
  |-------|-------|------|
  | T1 Claim Request | `"New Claim Request"` | `"{requesterName} submitted a Claim Request on your post '{itemTitle}'"` |
  | T2 Found Report | `"Someone found your item"` | `"{requesterName} reported finding '{itemTitle}'"` |
  | T3 Approved | `"Your request was approved"` | `"'{itemTitle}' — contact the poster to arrange a handover"` |
  | T4 Rejected | `"Your request was declined"` | `"The poster declined your request on '{itemTitle}'"` |

- `data` payload on every notification: `{ type, itemId, requestId }` — used to deep-link into the Detail Screen (`/items/{itemId}`) when the user taps the notification
- GoRouter handles the incoming notification tap via `FirebaseMessaging.onMessageOpenedApp` and `getInitialMessage()` streams

**Associated Activities**
- Add `firebase_messaging` to `pubspec.yaml`; run `flutter pub get`
- Configure `AndroidManifest.xml` for FCM (notification channel, permissions)
- Create `notification_service.dart` with `registerToken()`, `unregisterToken()`, and `requestPermission()` methods
- Call `NotificationService.requestPermission()` and `registerToken()` after successful login (in `AuthService.signIn()` / registration flow)
- Call `NotificationService.unregisterToken()` inside `AuthService.signOut()`
- Add `fcmTokens` and `notificationsEnabled` fields to `UserService.createUserProfile()` defaults
- Add notification toggle to Settings Screen; bind to `UserService.updateUserProfile()` for `notificationsEnabled`
- Write `onNewRequest` Cloud Function with `source` guard and stale-token cleanup
- Write `onRequestStatusChange` Cloud Function with status-diff guard and stale-token cleanup
- Handle notification tap navigation: wire `FirebaseMessaging.onMessageOpenedApp` and `getInitialMessage()` to GoRouter push `/items/{itemId}`
- Update Firestore security rules: `fcmTokens` writable only by the owning user; `notificationsEnabled` writable only by the owning user

**Testing**
- Unit test: `NotificationService.registerToken()` — verify `arrayUnion` called on `users/{uid}.fcmTokens` with the current token
- Unit test: `NotificationService.unregisterToken()` — verify `arrayRemove` called on `users/{uid}.fcmTokens`
- Unit test: `onNewRequest` Cloud Function — mock request doc with `source: "app"`, Poster has `notificationsEnabled: true` and one valid token → verify FCM `sendEachForMulticast()` called with correct payload
- Unit test: `onNewRequest` — mock request doc with `source: "qr_walk_in"` → verify FCM is NOT called
- Unit test: `onNewRequest` — Poster has `notificationsEnabled: false` → verify FCM is NOT called
- Unit test: `onNewRequest` — FCM returns `messaging/registration-token-not-registered` for one token → verify `arrayRemove` called on that token and other tokens are still attempted
- Unit test: `onRequestStatusChange` — status changes `pending` → `approved` → verify FCM called for Visitor with T3 payload
- Unit test: `onRequestStatusChange` — status changes `pending` → `rejected` → verify FCM called for Visitor with T4 payload
- Unit test: `onRequestStatusChange` — status changes `approved` → `resolved` (non-qualifying change) → verify FCM is NOT called
- Widget test: Settings Screen — toggle "Receive notifications" off → verify `UserService.updateUserProfile()` called with `notificationsEnabled: false`
- Integration test: submit a Claim Request → verify the Poster's device receives a push notification with correct title and body
- Integration test: tap incoming notification → verify app navigates to the correct Detail Screen (`/items/{itemId}`)

---

### 2.17 Admin Role & In-App Admin Screens

| Field | Detail |
|---|---|
| **WBS Code** | 2.17 |
| **Type** | Work Package |
| **Requirement** | Data Storage · Pages & Navigation · Reliability |

**Scope / Statement of Work**

Introduce an admin role so the Remote Config viewer and Rollback Plan screens designed in the prototype (under Settings → Developer) can ship to the Flutter app behind proper access control. Admin status is a single boolean on the user document — granted **manually** by an existing admin editing `users/{uid}.isAdmin = true` in the Firebase Console. There is no in-app flow to grant or revoke admin; this matches the small-team admin pool and keeps the auth surface area minimal.

The in-app Remote Config screen is **read-only**. It surfaces the currently-fetched values of `secret_question_enabled`, `sensitive_categories`, and `security_office_contact`, plus the last-fetched timestamp, so on-call admins can confirm what the app is actually using without opening the Firebase Console. To **change** a value, the screen links out to the Firebase Console — the source of truth for Remote Config remains the console, and there is no app-to-Remote-Config write path. This avoids needing a Cloud Function with Remote Config admin credentials and removes the risk of a stolen admin device flipping flags.

The in-app Rollback Plan screen is the interactive equivalent of `ROLLBACK_PLAN.md` (WBS 2.13): it shows the current flag state, when to invoke the plan, the 5-step procedure, propagation timing, an interactive post-rollback verification checklist (local UI state only), and on-call contacts.

**Deliverables**
- `isAdmin: bool` field added to `users/{uid}` (default `false`); admin granted manually by editing the user document in Firebase Console
- `currentUserProvider` (in `features/auth/presentation/providers/`) exposes `isAdmin` so UI and route guards can read it
- GoRouter routes:
  - `/admin/remote-config`
  - `/admin/rollback-plan`
- Route guard: any `/admin/*` route redirects non-admin users to `/feed` with a snackbar "Admin access required"
- Settings & Profile screen (1.6): a **Developer** section is rendered only when `currentUser.isAdmin == true`; rows link to the two admin screens
- `RemoteConfigViewerScreen` (read-only):
  - Header card: last fetched timestamp, min-fetch-interval reminder
  - Feature flags section: `secret_question_enabled` with current value badge (no toggle)
  - Configuration values section: `security_office_contact`, `sensitive_categories` (chips)
  - "Edit in Firebase Console" button — opens `console.firebase.google.com/.../config` in an external browser
  - "Fetch & activate now" button — calls `FeatureFlagService.fetchAndActivate()` and refreshes displayed values
- `RollbackPlanScreen`:
  - Current flag status banner (ENABLED / DISABLED) — derived from live `FeatureFlagService` state
  - "When to invoke" criteria list
  - Numbered rollback procedure (mirrors `ROLLBACK_PLAN.md`)
  - Propagation time table (Production / Debug / Force-fetch)
  - Post-rollback verification checklist with local checked state (state is screen-local; no persistence)
  - On-call contacts (Tech Lead handle, Firebase Console URL, Crashlytics URL)
- Firestore security rules:
  - `users/{uid}.isAdmin` is writable **only** by another admin or via Firebase Console (i.e. not by the user themselves) — clients cannot self-elevate
  - Rule helper `function isAdmin() { return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true; }` available for any future admin-gated writes
- A short `ADMIN_ROLE.md` runbook in the repo root documenting how to grant `isAdmin` via Firebase Console (click-path) and how to revoke it

**Associated Activities**
- Add `isAdmin: bool` (default `false`) to the user model (`UserModel.fromJson`/`toJson`) and `User` entity
- Update `UserService.createUserProfile()` to set `isAdmin: false` on new accounts
- Update `currentUserProvider` to expose `isAdmin` from the user document
- Add the two routes to `lib/config/router/app_router.dart` with the admin guard
- Build `RemoteConfigViewerScreen` reusing tokens and components from the Figma prototype (`screens-admin.jsx`); replace the prototype's toggle with a value badge + "Edit in Firebase Console" deep link
- Build `RollbackPlanScreen` mirroring the prototype design (`screens-admin.jsx` `RollbackPlanScreen`); rollback step content sourced from `ROLLBACK_PLAN.md` (single source of truth — keep the markdown and the screen text in sync)
- Add the Developer section to Settings (1.6) gated on `currentUser.isAdmin`
- Update Firestore security rules: `isAdmin` cannot be written by the user themselves; add `isAdmin()` helper for future use
- Write `ADMIN_ROLE.md` with the manual-grant procedure
- Update `ROLLBACK_PLAN.md` (WBS 2.13) to cross-reference the in-app Rollback Plan screen

**Testing**
- Unit test: `currentUserProvider` returns `isAdmin: true` when the user doc has `isAdmin: true` — verify
- Unit test: `currentUserProvider` returns `isAdmin: false` when the field is missing (default behaviour)
- Widget test: render Settings screen with `currentUser.isAdmin == false` — verify Developer section is **not** rendered
- Widget test: render Settings screen with `currentUser.isAdmin == true` — verify Developer section is rendered with two rows linking to `/admin/remote-config` and `/admin/rollback-plan`
- Widget test: navigate to `/admin/remote-config` as a non-admin user — verify redirect to `/feed` and "Admin access required" snackbar
- Widget test: render `RemoteConfigViewerScreen` with mocked `FeatureFlagService` — verify all three keys render with current values and last-fetched relative time
- Widget test: tap "Fetch & activate now" — verify `FeatureFlagService.fetchAndActivate()` is called
- Widget test: render `RollbackPlanScreen` with `secret_question_enabled == true` — verify status banner shows ENABLED; with `false` — verify DISABLED banner
- Widget test: tap a checklist item — verify the row toggles to the checked state
- Firestore rules test: a non-admin user tries to set `isAdmin: true` on their own document — verify denied
- Firestore rules test: a non-admin user tries to set `isAdmin: true` on another user's document — verify denied

**Cross-references to update**
- **2.1 (Firestore Schema)** — add `isAdmin: bool` (default `false`) to the `users/{uid}` schema
- **2.13 (Feature Flag & Rollback Plan)** — note that the in-app `RemoteConfigViewerScreen` and `RollbackPlanScreen` are implemented in **2.17** behind the admin role; `ROLLBACK_PLAN.md` remains the source of truth for rollback step content
- **1.6 (Settings & Profile Screen)** — note that an admin-gated Developer section appears in Settings when `currentUser.isAdmin == true`
- **CLAUDE.md** — add `isAdmin?: bool (default false)` to the `users/{uid}` row in the Firestore Collections table; mention `ADMIN_ROLE.md` in Key Files

---

## Phase 3.0 — Cross-Platform

---

### 3.1 Android Build, Testing & Verification

| Field | Detail |
|---|---|
| **WBS Code** | 3.1 |
| **Type** | Work Package |
| **Requirement** | Cross-Platform Execution · Testing & Test Scripts |

**Scope / Statement of Work**
Run the complete test suite to verify all committed features pass, then build and verify the Flutter app on Android (physical device or emulator). Unit and widget tests are written within each feature's work package. This task consolidates test execution and Android verification as the final quality gate before submission.

**Deliverables**
- All tests passing: `flutter test` exits with zero failures
- Test coverage report generated via `flutter test --coverage`
- App running successfully on Android (physical device or emulator)
- All core features verified on Android: auth, feed, post form, search, request flow (including cancel), recommendation panel, settings, local storage
- Screenshots or screen recording as evidence of successful Android execution

**Associated Activities**
- Ensure all team members have committed their tests to the repository
- Run `flutter test` and fix any remaining failures across the full suite
- Generate coverage report via `flutter test --coverage` and review gaps
- Configure `google-services.json` for Android build
- Run `flutter run` on Android device or emulator
- Verify all screens and navigation work correctly on Android
- Capture screenshots as evidence of execution

---

### 3.2 Web Build, Testing & Verification

| Field | Detail |
|---|---|
| **WBS Code** | 3.2 |
| **Type** | Work Package |
| **Requirement** | Cross-Platform Execution · Testing & Test Scripts |

**Scope / Statement of Work**
Build and verify the Flutter app on Web with feature parity to Android. Includes Firebase Web SDK configuration, Web-compatible photo upload (`image_picker_for_web`), Firebase Storage CORS setup, and integration tests running via `chromedriver`. Parallel to **3.1** — together they complete the cross-platform quality gate.

**Deliverables**
- Firebase Web app registered in Firebase Console; `firebase_options.dart` regenerated via `flutterfire configure` to include Web
- `flutter build web --release` completes with zero errors
- `image_picker_for_web` installed and photo upload verified on Chrome and Firefox
- Firebase Storage CORS configured on the bucket via `gsutil cors set cors.json gs://<bucket>`
- All features verified on Web with parity to Android: auth, feed, post form (incl. photo upload), search, request flow (incl. cancel), similar-posts panel, settings, Hive offline cache (Hive uses IndexedDB on Web automatically)
- Integration test suite running on Chrome target via `flutter drive --target=... -d chrome`
- Screenshots of every screen on Web captured as evidence
- Cross-platform regression matrix documented in `CROSS_PLATFORM.md`: Android × Web feature-status table

**Associated Activities**
- Run `flutterfire configure` and include the Web platform
- Add `image_picker_for_web` to `pubspec.yaml`
- Configure Storage CORS using `gsutil cors set`
- Install `chromedriver`; document version pinning
- Run integration tests against Chrome target
- Walk through every screen manually on Chrome and Firefox; capture screenshots
- Document any deliberate platform differences (e.g., Crashlytics not on Web, see 2.12) in `CROSS_PLATFORM.md`
- Confirm GoRouter deep links work with the Web `<base href>` set correctly

**Testing**
- Integration test: `flutter drive --target=test_driver/app.dart -d chrome` — full auth → feed → detail → submit request flow passes
- Smoke test: `flutter build web --release` exits with zero errors and generates a deployable bundle
- Manual test: upload a photo on Chrome — verify the image lands in Firebase Storage
- Manual test: open a deep link URL on Web (e.g. `/item/{id}`) from a new tab — verify the correct Detail Screen renders after auth
- Regression: side-by-side Android emulator vs Chrome on the same Firestore data — verify Feed renders consistently

---

## 🛡️ Anti-Fraud Brainstorm: Protecting Against Bad Actors in the System

The Lost & Found system carries a risk that malicious users may attempt to claim items they do not actually own. The following outlines prevention strategies categorized by complexity:

---

### Level 1 — Immediately Actionable (Requires Few or No New Features)

| Method | Details | Used in WBS |
|---|---|---|
| **Student ID verification** | Login requires a real university student ID — outsiders cannot access the system | 0.2, 0.3 |
| **Must prove possession of the item** | Found Report (section 2.4) requires the reporter to describe the item's appearance and where it was found — someone without the actual item cannot answer | 2.4 |
| **Requester information is transparent** | The Poster can see the name and student ID of the person who submitted the request — helps assess credibility | 2.4 |
| **Poster approves manually** | No automatic handover — the Poster must personally press approve | 2.4 |

---

### Level 2 — Additional Features (Recommended for WBS Inclusion)

> **Status note**: Of the 3 items listed below, only **2.10 Secret Question** has been formally accepted into the WBS (as a Work Package in Phase 2.0).
> **2.11 Report / Flag user** and **2.12 Rating system** remain as **Backlog / Future Work** — they are not in scope for the current sprint and have no WBS entry or owner. If they are to be implemented, they must first be created as new Work Packages with Scope/Deliverables/Testing defined.

| Method | Details | WBS Task |
|---|---|---|
| **Secret Question** | When creating a Founder Post, the Poster sets a secret question (e.g., "What brand is printed on the inside of the wallet?") and records the correct answer privately — the Visitor (person claiming to be the owner) must answer it before submitting a Claim Request, with no hints given — the Poster manually verifies the answer | **2.10** (accepted into WBS) |
| **Report / Flag user** | A "Report" button on a request card — notifies the admin that this person is suspicious | _Backlog_ (not yet in WBS — originally proposed as 2.11) |
| **Rating system** | After a post is resolved, both parties rate each other — users who are reported or rated poorly appear less trustworthy | _Backlog_ (not yet in WBS — originally proposed as 2.12) |

---

### Level 3 — Beyond App Scope (Process Recommendations)

- **Arrange item pickup in a public place** — Include an in-app notice: "We recommend arranging pickup in a populated area, such as the library or in front of the admin office."
- **Contact via verified phone number only** — Require use of the telephone number registered with the student ID only.

---

> **Summary of recommended immediate WBS additions**: Most Level 1 items are already being implemented — at a minimum, **2.10 Secret Question** should be added, as it is easy to implement and provides genuine protection.

---

## Phase 4.0 — Enterprise Architecture & Tooling

---

### 4.1 Clean Architecture Skeleton

| Field | Detail |
|---|---|
| **WBS Code** | 4.1 |
| **Type** | Work Package |
| **Requirement** | Enterprise Architecture |

**Scope / Statement of Work**
Establish the Clean Architecture folder structure with strict separation of **Data / Domain / Presentation** layers. Domain contains pure Dart business logic with **zero Flutter or Firebase imports**, enforced by a `custom_lint` rule. Data implements repositories using the Firebase SDK. Presentation uses Riverpod providers and Flutter widgets. Foundational — all feature work packages (0.x, 1.x, 2.x) must be refactored into this structure.

**Deliverables**
- `lib/` restructured: `domain/` (entities, repository interfaces, use cases), `data/` (repository implementations, Firebase DTOs, mappers), `presentation/` (screens, widgets, providers)
- Domain entities as immutable Dart classes: `Item`, `User`, `Request`, `AuthUser` — zero Flutter/Firebase imports
- Repository interfaces in Domain: `ItemRepository`, `UserRepository`, `AuthRepository`, `RequestRepository`
- Concrete repository implementations in Data, using Firebase SDK
- `custom_lint` rule banning `package:flutter/*` and `package:firebase_*/*` imports under `/lib/domain/`
- `ARCHITECTURE.md` with a layer diagram and one end-to-end example (e.g., the auth flow)

**Associated Activities**
- Define Domain entities as plain Dart classes (immutable, value-based equality)
- Define abstract repository interfaces in Domain
- Implement concrete repositories in Data that map Firestore snapshots to Domain entities
- Add `custom_lint` package and author the import-ban rule
- Write `ARCHITECTURE.md`

**Testing**
- Static check: `custom_lint` passes with zero violations in `/lib/domain/`
- Unit test: Domain entity constructors work without Firebase being initialized
- Unit test: a Data-layer mapper converts a Firestore document to a Domain `Item` correctly and vice versa

---

### 4.2 Riverpod 2.x State Management

| Field | Detail |
|---|---|
| **WBS Code** | 4.2 |
| **Type** | Work Package |
| **Requirement** | Enterprise Architecture · State Management |

**Scope / Statement of Work**
Set up **Riverpod 2.x with code generation** as the app-wide state management framework. All state — auth, feed, form inputs, request status, profile — flows through Riverpod providers. `@riverpod` annotations with `riverpod_generator` reduce boilerplate. Supersedes the routing mechanics of 0.4 by providing `currentUserProvider`.

**Deliverables**
- `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `build_runner`, `custom_lint`, `riverpod_lint` added to `pubspec.yaml`
- `ProviderScope` wrapping the root widget in `main.dart`
- Core providers implemented and documented:
  - `authRepositoryProvider`, `itemRepositoryProvider`, `userRepositoryProvider`, `requestRepositoryProvider`
  - `currentUserProvider` — `Stream<User?>` from `FirebaseAuth.instance.authStateChanges()`
  - `itemsFeedProvider` — `Stream<List<Item>>` of Active items
  - Form-state `NotifierProvider` example (used by 1.4 Post Form)
- `dart run build_runner watch` verified working and generated `.g.dart` files committed per team convention
- Provider-naming and layering conventions documented in `ARCHITECTURE.md`

**Associated Activities**
- Add Riverpod dependencies; run `flutter pub get`
- Wrap root widget in `ProviderScope`
- Implement the core providers listed above
- Run `dart run build_runner watch` to generate provider code
- Build one end-to-end example feature (auth flow) using Riverpod as a reference pattern
- Update team conventions doc with provider-naming rules and override patterns

**Testing**
- Unit test: `itemsFeedProvider` with a fake `ItemRepository` override — verify emitted state matches the repository stream
- Widget test: `ProviderScope.overrides` replaces `authRepositoryProvider` with a fake — verify UI reads from the fake
- Static check: `riverpod_lint` passes with zero violations

---

### 4.3 GoRouter & Authentication Guards

| Field | Detail |
|---|---|
| **WBS Code** | 4.3 |
| **Type** | Work Package |
| **Requirement** | Enterprise Architecture · Pages & Navigation |

**Scope / Statement of Work**
Replace the `StreamBuilder`-based routing with **GoRouter**. All routes are declaratively defined; a single `redirect` callback gates every route behind authentication using the `currentUserProvider` from **4.2**. Deep links work consistently on Android and Web. Supersedes the routing mechanics of **0.4**.

**Deliverables**
- `go_router` added to `pubspec.yaml`
- `GoRouter` configured with all routes: `/login`, `/register`, `/feed`, `/item/:id`, `/post`, `/post/:id/edit`, `/my-posts`, `/settings`, `/settings/edit-profile`
- Global `redirect` callback reading from `currentUserProvider`: unauth → `/login`; auth → requested route (default `/feed`)
- Typed route extensions (e.g., `ItemDetailRoute(id: ...).go(context)`) for compile-time-safe navigation
- Deep-link support: Android intent filters configured; Web `<base href>` set
- `main.dart` uses `MaterialApp.router` — no `StreamBuilder`-based routing remains

**Associated Activities**
- Add `go_router` to `pubspec.yaml`
- Configure the router in `lib/app/router.dart`
- Implement `redirect` that consumes the Riverpod `currentUserProvider`
- Configure Android manifest intent filters and Web `<base href>` for deep links
- Update `main.dart` to `MaterialApp.router`
- Update 0.4 Deliverables to reference this WP (already done)

**Testing**
- Widget test: navigate to `/feed` unauthenticated — verify redirect to `/login`
- Widget test: navigate to `/feed` authenticated — verify Feed renders
- Integration test: cold-start with deep link `/item/{id}` on an authenticated session — verify Detail Screen loads with the right data
- Integration test: sign out from Settings — verify router redirects to `/login` automatically

---

## Phase 5.0 — Quality Gates

---

### 5.1 Accessibility Sweep — WCAG 2.2 AA

| Field | Detail |
|---|---|
| **WBS Code** | 5.1 |
| **Type** | Work Package |
| **Requirement** | Accessibility · Quality Gates |

**Scope / Statement of Work**
Pass **WCAG 2.2 AA** for all user-facing screens. Includes semantic labels, color contrast ≥ 4.5:1 for text and 3:1 for UI components, dynamic type support, focus order, and screen-reader traversal. Uses `flutter_test`'s `meetsGuideline()` helpers for automated checks and manual walkthrough with platform screen readers.

**Deliverables**
- Every interactive widget has a meaningful `Semantics(label: ...)` or uses a widget that provides one (e.g., `IconButton` with `tooltip`)
- Color palette audited: all text/background pairs meet ≥ 4.5:1 contrast (documented in `A11Y_AUDIT.md`)
- Dynamic type: all `Text` widgets honor `MediaQuery.textScaleFactor`; no hard-coded `fontSize` that breaks at 1.5× scale
- All screens pass `tester.meetsGuideline(androidTapTargetGuideline)`, `labeledTapTargetGuideline`, and `textContrastGuideline` as widget-test assertions
- Screen-reader walkthrough verified on TalkBack (Android) and VoiceOver-style reader on Chrome (Web)
- `A11Y_AUDIT.md` with per-screen before/after evidence and remediation notes

**Associated Activities**
- Audit every 1.x screen: add `Semantics` labels, fix contrast, test at 1.5× text scale
- Update the style guide from 1.1 to bake in accessibility tokens (contrast, tap-target size)
- Add `flutter_test` accessibility-guideline assertions to widget tests for each screen
- Manual TalkBack walkthrough on Android; Chrome screen-reader walkthrough for Web
- Write `A11Y_AUDIT.md`

**Testing**
- Widget test per screen: `await tester.meetsGuideline(textContrastGuideline)` — pass
- Widget test per screen: `meetsGuideline(androidTapTargetGuideline)` — pass
- Widget test per screen: `meetsGuideline(labeledTapTargetGuideline)` — pass
- Manual test: enable TalkBack, navigate each screen — verify logical reading order and every interactive element is announced

---

### 5.2 Security & Dependency Scans

| Field | Detail |
|---|---|
| **WBS Code** | 5.2 |
| **Type** | Work Package |
| **Requirement** | Security · Quality Gates |

**Scope / Statement of Work**
Enforce the security quality gate via automated scans in CI: dependency vulnerability scanning, secret scanning in the repo, and a tightened granular Firestore security rules pass (deepening what was sketched in 0.2 / 2.1). Scans run on every pull request and block merges on High/Critical findings.

**Deliverables**
- Dependency scan step in CI (`dart pub outdated --mode=security`) that fails the build on High/Critical vulnerabilities
- Secret scanning via `gitleaks` (or equivalent) in CI, failing on any finding
- Firestore security rules upgraded to use:
  - `request.resource.data.diff(resource.data).affectedKeys()` to restrict which fields a client may change in an update
  - Role-based access control (RBAC): only the Poster can edit/delete their own item; only authenticated users whose `uid` matches `requesterId` may cancel their own request; only the Poster may approve/reject
  - Server-side timestamp enforcement: `request.time` used to validate `createdAt` and `editedAt` are not client-forged
- `SECURITY.md` with threat model and the RBAC matrix
- CI workflow file (e.g., `.github/workflows/security.yml`) wired up

**Associated Activities**
- Add `dart pub outdated --mode=security` step to CI workflow
- Add gitleaks scan step; configure allowlist for known false positives
- Rewrite Firestore rules with `diff().affectedKeys()`, per-collection RBAC, and `request.time` checks
- Deploy updated rules; test via Firebase Emulator
- Write `SECURITY.md` with threat model and role matrix

**Testing**
- Firestore rules test (via emulator): user tries to edit another user's item — verify denied
- Firestore rules test: user tries to set `createdAt` directly — verify denied (must come from `request.time`)
- Firestore rules test: user tries to change `userId` on their own doc via update — verify denied via `diff().affectedKeys()` rule
- CI test: PR with a planted fake secret in code — verify gitleaks blocks the PR
- CI test: PR declaring a dependency with a known High vulnerability — verify the security scan blocks the PR

---

## Phase 6.0 — Orchestration & Tooling

---

### 6.1 Multi-Agent Orchestration Setup

| Field | Detail |
|---|---|
| **WBS Code** | 6.1 |
| **Type** | Work Package |
| **Requirement** | Multi-Agent Orchestration (R3) |

**Scope / Statement of Work**
Establish the `.claude/agents/` structure with role-scoped subagent definitions so that code generation, review, and QA are delegated to distinct agents. Plan Mode drives complex task breakdown. The writer agent must not be the reviewer agent — separation is enforced by role assignment in the orchestration workflow. This WP is owned by the PM / Orchestrator; it is a prerequisite for all other development work.

**Deliverables**
- `.claude/agents/` directory at the repo root, with at minimum:
  - `architect.md` — Clean Architecture rules, layer constraints, entity shapes
  - `flutter_engineer.md` — Flutter + Riverpod + GoRouter conventions, coding style, do-not-do list
  - `qa_engineer.md` — test-pattern authoring (unit / widget / integration / golden), coverage rules
  - `security_reviewer.md` — read-only review role: rule-set audits, RBAC checks, secret scanning
- `CLAUDE.md` at the repo root: project memory, stack, conventions, do-not-do list
- Prompt templates per role documented: inputs, outputs, constraints
- Evidence of Plan Mode usage: at least one saved transcript showing the Orchestrator decomposing a complex task before execution
- Documented writer/reviewer separation policy: the agent that writes a module must not be the agent that approves it
- Weekly orchestration-loop log showing: plans approved, parallel agent tasks, handoffs, and findings the human reviewer caught that agents missed

**Associated Activities**
- Write each agent definition in `.claude/agents/`
- Write `CLAUDE.md` with stack, conventions, and do-not-do list
- Run at least one complex task via Plan Mode; capture the transcript
- Document the orchestration workflow in `ORCHESTRATION.md`
- Weekly: update the orchestration-loop log with the current sprint's evidence

**Testing**
- Manual review: all four agent definitions present in `.claude/agents/` with clearly separated roles
- Evidence check: Plan Mode transcript exists and shows decomposition steps before execution
- Evidence check: at least one PR reviewed by a different agent role than the one that generated the code
- Evidence check: `CLAUDE.md` passes a team-review checklist (stack accurate, conventions enforced, do-not-do list complete)

---

## Phase 7.0 — Test Scripts & Quality Evidence

> **QA phase.** Owns the test traceability matrix, execution scripts, and coverage evidence submitted alongside the project. See the full run guide and per-WBS status table in [`test_scripts.md`](test_scripts.md).

---

### 7.1 Test Scripts & Traceability Matrix

| Field | Detail |
|---|---|
| **WBS Code** | 7.1 |
| **Type** | Work Package |
| **Requirement** | Testing & Test Scripts |

**Scope / Statement of Work**
Maintain a living traceability matrix that maps every test case listed in each WBS work package's **Testing** section to an actual test file in the repository. The matrix tracks implementation status (written / not yet written / known failure) for all phases. The dedicated file `test_scripts.md` is the single source of truth for how to run tests, what scripts exist, and what their current status is. This WP is updated whenever a new test file is added or a test status changes.

**Deliverables**
- `test_scripts.md` at the project root containing:
  - Run commands for each test type (`flutter test`, `npm test`, `flutter drive`)
  - `test/` directory structure with file-to-WBS mapping
  - Writing conventions for unit, widget, and integration tests
  - Traceability matrix: one table per phase, columns — WBS code, description, test file, type, status
  - Coverage summary table updated each sprint
- All test files located under `test/` mirroring the `lib/` folder structure
- `test/` directory committed to the repository and included in submission

**Associated Activities**
- Create `test_scripts.md` with the initial run guide and traceability matrix
- Update `test_scripts.md` whenever a new test file is added (add a row to the matrix)
- Update status column (⬜ → ✅ or ⚠️) as each WBS work package's tests are implemented
- Run `flutter test --coverage` at the end of each sprint and update the Coverage Summary table
- Ensure `test/firestore_rules/rules.test.js` is runnable via `npm test` from the `test/firestore_rules/` directory
- Flag known failures with a ⚠️ status and document the root cause inline in the matrix

**Testing**
- All test files listed in the matrix must exist at the paths stated — no phantom entries
- `flutter test` exits with zero failures before each PR to `develop` is merged
- `flutter test --coverage` is run and the coverage report is committed for WBS 3.1 / 3.2 submission
- `cd test/firestore_rules && npm test` passes all 9 Firestore rules tests

---

*WBS Dictionary v5.0 — Campus Lost & Found Digital Bulletin Board*
*Tech Stack: Flutter (Dart) + Riverpod 2.x + GoRouter + Firebase (Auth, Firestore, Storage, Cloud Functions, Crashlytics, Remote Config) + Hive + shared_preferences*
*Total Work Packages: 37 | Changes since v4.1: added Phase 2.14 (Sensitive Item Handling & Auto-Expire), Phase 2.15 (QR Walk-in Web Form), Phase 2.16 (Push Notifications); updated existing WBS per v5.0 change summary*
