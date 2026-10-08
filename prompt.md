You are now responsible for bringing my "Kahraman Dostum" Flutter/Firebase application back to a stable, production-ready state.

You must act simultaneously as:

1. Senior Flutter Architect
2. Senior Dart Engineer
3. Senior Firebase Engineer
4. Firebase Cloud Functions Engineer
5. Firestore Security Rules Engineer
6. Mobile QA / End-to-End Test Engineer
7. Android UI/UX Engineer
8. Application Security Engineer
9. Release / Google Play Engineer
10. Regression Testing Engineer

This is NOT a simple bug-fixing task.

The application already has real test users.

Your changes must therefore prioritize:
- preserving existing user data
- preserving existing working functionality
- avoiding regressions
- security
- backward compatibility
- reliable Firebase synchronization
- production stability

============================================================
CRITICAL CONTEXT
============================================================

The current application has a known architectural regression.

A previous refactor moved scenario/detective completion, scoring and badge logic from the Flutter client toward Cloud Functions.

However:

- Flutter calls a callable Cloud Function named `completeTask`
- `completeTask` is currently missing from the local `functions/index.js`
- Firestore Rules prevent the client from directly modifying protected fields such as:
  - toplam_puan
  - tamamlanan_bolumler
  - rozetler
- Therefore scenario completion currently fails silently.
- The UI can show success even though Firebase did not save the completion.
- Points remain 0.
- The next scenario remains locked.
- Detective progression is also affected.
- Badge awarding was removed from the client but was not successfully implemented in the backend.
- The Firebase project currently has an active `onUserCreated` function that is NOT present in the local `functions/index.js`.

The existing audit identified these regressions.

DO NOT assume this information is correct blindly.

VERIFY EVERYTHING AGAINST THE ACTUAL PROJECT FILES.

============================================================
ABSOLUTE SAFETY RULES
============================================================

Before changing anything:

1. Inspect the entire project.
2. Inspect the current git state.
3. Inspect relevant git history if available.
4. Inspect:
   - functions/index.js
   - firestore.rules
   - firebase.json
   - pubspec.yaml
   - lib/services/analytics_service.dart
   - lib/screens/senaryo_detay_ekrani.dart
   - lib/screens/senaryo_bolum_listeleme_ekrani.dart
   - lib/screens/siber_dedektif_oyunu.dart
   - lib/screens/rozet_listeleme_ekrani.dart
   - lib/screens/video_detay_ekrani.dart
   - lib/main.dart
   - lib/screens/ana_navigation_ekrani.dart
   - lib/screens/ana_ekran.dart
   - android/app/src/main/res/values/styles.xml
   - relevant models
   - relevant Firebase configuration

3. Do NOT delete Firestore data.
4. Do NOT delete Firebase users.
5. Do NOT reset production data.
6. Do NOT weaken Firestore Rules as a shortcut.
7. Do NOT disable App Check.
8. Do NOT expose Gemini/API secrets.
9. Do NOT remove security controls.
10. Do NOT deploy anything until the backend source has been reconciled and validated.
11. Do NOT replace working architecture unnecessarily.
12. Do NOT rewrite the entire application.

If a change could affect existing users, explain the risk before making it.

============================================================
PHASE 1 — FULL CURRENT-STATE AUDIT
============================================================

Inspect the actual current code.

Build a dependency/data-flow map:

Flutter UI
→ service
→ Firebase SDK
→ Cloud Function
→ Firestore
→ UI refresh

For every critical feature determine:

WHO CALLS IT?
WHAT DOES IT CALL?
WHAT PARAMETERS ARE SENT?
WHAT DOES THE BACKEND EXPECT?
WHAT DOES FIREBASE WRITE?
WHAT DOES THE UI READ AFTERWARD?
WHAT HAPPENS IF THE REQUEST FAILS?

Do not guess.

============================================================
PHASE 2 — FIREBASE FUNCTION RECONCILIATION
============================================================

This is extremely important.

Inspect every exported Cloud Function in the local source.

Then inspect every Cloud Function referenced by Flutter.

Create a matrix:

FUNCTION
LOCAL SOURCE
FLUTTER CALLER
EXPECTED REGION
EXPECTED PARAMETERS
EXPECTED RESULT
SECURITY
STATUS

Especially investigate:

- completeTask
- onUserCreated
- geminiChat
- textToSpeech
- deleteSelfAccount
- grantAdReward
- clearGeminiHistory
- syncAdminClaim

CRITICAL:

`onUserCreated` is reportedly active in Firebase but missing from the local source.

Do NOT deploy `functions/index.js` until you have reconciled this discrepancy.

We must NOT accidentally overwrite or remove a currently working production Cloud Function.

The final `functions/index.js` must contain every required production function.

============================================================
PHASE 3 — IMPLEMENT COMPLETE TASK CORRECTLY
============================================================

Implement or restore:

exports.completeTask

using the project's existing architecture and Firebase Functions version.

Do NOT blindly copy old code.

Adapt it to the CURRENT codebase.

It must:

1. Verify request.auth exists.
2. Verify the authenticated UID.
3. Validate taskId.
4. Validate taskType.
5. Validate proof.
6. Validate the requested scenario/detective task against trusted Firestore data.
7. Never trust client-provided score.
8. Calculate the score server-side.
9. Prevent score manipulation.
10. Prevent duplicate rewards.
11. Be idempotent.
12. Atomically update progress.
13. Update:
    - tamamlanan_bolumler
    - toplam_puan
    - sonGuncelleme
14. Handle detective progression correctly.
15. Handle scenario progression correctly.
16. Evaluate badges safely.
17. Avoid duplicate badges.
18. Preserve all unrelated fields.
19. Handle malformed requests safely.
20. Return a predictable result to Flutter.
21. Handle retries safely.
22. Handle duplicate callable requests safely.

IMPORTANT:

Do NOT use client-provided points as the authoritative score.

The server must remain authoritative.

============================================================
PHASE 4 — SCENARIO COMPLETION
============================================================

Trace:

SenaryoBolumListelemeEkrani
→ SenaryoDetayEkrani
→ answer validation
→ success calculation
→ AnalyticsService
→ completeTask
→ usersProgress
→ next scenario unlock

Fix the complete flow.

Requirements:

If scenario succeeds:

- backend confirms completion
- score is persisted
- tamamlanan_bolumler is persisted
- badge logic executes
- Flutter receives confirmed success
- next scenario becomes unlocked

If backend synchronization fails:

THE UI MUST NOT SHOW A FALSE SUCCESS STATE.

Do not show:

"TEBRİKLER KAHRAMAN!"

until the required backend operation has succeeded.

Instead:

- clearly show synchronization failure
- provide a retry option
- do not duplicate points on retry
- preserve the user's answers when possible

============================================================
PHASE 5 — DETECTIVE SYSTEM
============================================================

Apply the same architecture to:

SiberDedektifOyunu

Verify:

- question completion
- correct answer tracking
- progress
- points
- known questions
- duplicate completion
- persistence
- unlock/progression
- retry behavior

Ensure the detective system cannot get stuck because of the same missing backend function.

============================================================
PHASE 6 — BADGES
============================================================

Investigate the old badge implementation if available in git history.

Find:

rozetKontrolEt

Determine what criteria existed previously.

Do NOT invent random badge criteria.

If the previous implementation exists, preserve its intended behavior and port it safely to the backend.

Badges must:

- be calculated from trusted server-side state
- not be client-manipulable
- not duplicate
- survive logout/login
- survive app restart
- not disappear after unrelated updates

============================================================
PHASE 7 — VIDEO PROGRESS
============================================================

Inspect video_detay_ekrani.dart.

If the intended application behavior is to track completed videos:

- implement the missing completion call
- ensure it happens at the correct completion point
- avoid repeated rewards
- persist the result safely
- make sure the UI reflects saved progress

Do not mark a video complete merely because it was opened if the intended behavior is completion.

Use the existing project architecture.

============================================================
PHASE 8 — FIRESTORE RULES
============================================================

DO NOT weaken Firestore Rules.

Keep protected fields protected:

- toplam_puan
- tamamlanan_bolumler
- rozetler
- gemini_hakki
- uid
- isAdmin
- other protected server-side fields

Cloud Functions should use Admin SDK for trusted server-side writes.

After implementation, verify that:

- normal users cannot modify score
- normal users cannot grant themselves badges
- normal users cannot unlock scenarios manually
- normal users cannot change admin status
- normal users cannot modify protected progress
- normal users can still update their legitimate profile data

============================================================
PHASE 9 — AUTHENTICATION / REGISTRATION
============================================================

Do NOT break the registration fix that currently uses:

SetOptions(merge: true)

Verify:

Firebase Auth
→ onUserCreated
→ users/{uid}
→ usersProgress/{uid}
→ client merge

Ensure no race condition causes partial registration.

Very important:

Do not remove or accidentally overwrite the active onUserCreated behavior.

============================================================
PHASE 10 — ERROR HANDLING
============================================================

Search the project for swallowed errors.

Especially:

catch (e)

where the UI continues as if an operation succeeded.

Fix critical cases.

For Firebase operations:

SUCCESS must mean server confirmation.

Failure must mean failure.

Do not hide backend errors behind fake success dialogs.

Use user-friendly Turkish messages in the UI.

Do not expose internal Firebase/server details to the user.

Developer logs may contain technical details.

============================================================
PHASE 11 — ANDROID NAVIGATION BAR
============================================================

Fix the Android bottom navigation layout professionally.

Do NOT use immersive mode.

Do NOT hide Android navigation controls.

Use proper edge-to-edge handling.

Inspect:

main.dart
styles.xml
AnaNavigation
AnaSayfa
SafeArea
BottomAppBar
NavigationBar
FAB
Insets

The goal:

- system navigation controls remain accessible
- no giant black/grey empty area
- no overlapping controls
- no accidental FAB interaction
- no double SafeArea padding
- no nested Scaffold problems
- works with gesture navigation
- works with 3-button navigation

Do not make visual changes unrelated to this problem.

============================================================
PHASE 12 — ACCESSIBILITY
============================================================

Check the important screens with increased system font sizes.

At minimum:

130%
150%
200%

Look for:

- RenderFlex overflow
- clipped text
- inaccessible buttons
- dialog overflow
- bottom navigation overflow
- keyboard overflow
- fixed-height containers
- hardcoded widths

Do not solve accessibility by simply shrinking fonts.

============================================================
PHASE 13 — SECURITY
============================================================

Verify:

- Firebase App Check
- Play Integrity
- Firestore Rules
- Cloud Functions authentication
- rate limiting
- Gemini secret handling
- admin claim handling
- score anti-cheat
- badge anti-cheat
- reward anti-cheat
- account deletion
- duplicate requests

Do not disable security mechanisms to make testing easier.

If debug-only configuration is required for local testing, keep it isolated from release builds.

============================================================
PHASE 14 — TEST EVERYTHING AFTER CHANGES
============================================================

After implementation, do NOT stop after compilation.

Run:

flutter analyze

flutter test

and appropriate Firebase/Functions checks.

Then perform an end-to-end test.

At minimum verify:

TEST 01
Fresh app launch

TEST 02
Registration

TEST 03
Firestore users/{uid}

TEST 04
Firestore usersProgress/{uid}

TEST 05
Logout

TEST 06
Login

TEST 07
Scenario 1

TEST 08
Successful scenario completion

TEST 09
Check toplam_puan

TEST 10
Check tamamlanan_bolumler

TEST 11
Scenario 2 unlock

TEST 12
Repeat scenario completion

TEST 13
Ensure duplicate points are NOT awarded

TEST 14
Failed scenario

TEST 15
Retry scenario

TEST 16
App restart

TEST 17
Login again

TEST 18
Detective completion

TEST 19
Badge awarding

TEST 20
Video completion

TEST 21
AI assistant

TEST 22
Gemini quota

TEST 23
Logout/login persistence

TEST 24
Account deletion

TEST 25
Re-registration after deletion

TEST 26
Network failure during scenario completion

TEST 27
Retry after network failure

TEST 28
Android 3-button navigation

TEST 29
Android gesture navigation

TEST 30
Large font size

TEST 31
Release build

============================================================
CRITICAL TEST: SCENARIO
============================================================

Do not consider the task complete unless this exact flow works:

User opens Scenario 1
→ answers questions
→ achieves passing score
→ backend validates
→ completeTask succeeds
→ Firestore updates
→ toplam_puan increases
→ tamamlanan_bolumler contains Scenario 1
→ badge logic runs
→ Flutter receives success
→ user returns to list
→ Scenario 2 is unlocked
→ app restart
→ Scenario 2 remains unlocked

Verify the actual Firestore document.

Do not infer success from the UI.

============================================================
CRITICAL TEST: FAILURE
============================================================

Simulate/inspect what happens if:

- Cloud Function fails
- internet disappears
- request times out
- app closes during completion
- callable request is duplicated

The user must never receive duplicate points.

The user must never see a false success.

The application must remain recoverable.

============================================================
PHASE 15 — BUILD VALIDATION
============================================================

Before release:

flutter analyze

flutter test

flutter build appbundle --release

Verify:

- release build succeeds
- correct versionCode
- correct versionName
- no debug configuration
- no debug App Check token
- no exposed secrets
- Firebase production configuration is correct
- assets exist
- required permissions are correct

============================================================
PHASE 16 — FINAL REGRESSION AUDIT
============================================================

After all fixes:

Re-check everything you changed.

For every modified file ask:

"Could this change break another existing feature?"

Trace dependencies again.

Especially verify:

- registration
- login
- AI
- TTS
- account deletion
- rewards
- profile
- stories
- videos
- detective
- scenarios
- badges
- navigation

Do not declare success just because the original bug disappeared.

============================================================
IMPORTANT DEPLOYMENT RULE
============================================================

DO NOT deploy Firebase Functions until:

1. Local functions/index.js is reconciled.
2. Existing active functions are preserved.
3. completeTask is implemented.
4. onUserCreated is preserved.
5. Other existing functions are preserved.
6. Functions syntax is validated.
7. Dependencies are valid.
8. No accidental deletion of existing exports exists.

If you discover that the local source is missing a production function and cannot safely reconstruct it, STOP and tell me exactly what is missing.

Do not deploy blindly.

============================================================
DATA SAFETY
============================================================

Never delete or reset existing users.

Never clear usersProgress.

Never wipe Firestore.

Never recreate the Firebase project.

Never change production data just to make tests pass.

Use a dedicated test account for destructive tests.

============================================================
IMPLEMENTATION STYLE
============================================================

Use the existing architecture wherever possible.

Prefer small, controlled changes.

Do not introduce unnecessary packages.

Do not rewrite unrelated screens.

Do not rename fields unless absolutely necessary.

Do not change Firestore schema unnecessarily.

Do not change UI design unnecessarily.

Keep Turkish UI strings.

Keep code clean and production quality.

Add useful developer logs around critical Firebase synchronization.

Remove noisy debugging logs before release where appropriate.

============================================================
FINAL REQUIREMENT
============================================================

After implementation, produce a final report with:

1. WHAT WAS BROKEN
2. ROOT CAUSE
3. WHAT WAS FIXED
4. FILES CHANGED
5. FIREBASE FUNCTIONS CHANGED
6. FIRESTORE RULES CHANGED
7. DATABASE SCHEMA CHANGES
8. TESTS PERFORMED
9. TEST RESULTS
10. FIRESTORE VERIFICATION RESULTS
11. SECURITY VERIFICATION
12. RELEASE BUILD RESULT
13. REMAINING WARNINGS
14. REMAINING RISKS

Use:

PASS
FAIL
WARNING
NOT VERIFIED

for each test.

Do NOT say "everything works" unless it was actually verified.

============================================================
MOST IMPORTANT
============================================================

The application has real testers.

Do not optimize for speed.

Optimize for correctness and stability.

A working feature must not be broken while fixing another feature.

The most important objective is:

NO TEST USER SHOULD BE LEFT WITH A BROKEN REGISTRATION,
BROKEN PROGRESS,
BROKEN SCORE,
BROKEN UNLOCK,
FALSE SUCCESS,
OR LOST DATA.

Work methodically.

Inspect first.
Plan second.
Modify third.
Test fourth.
Verify Firebase fifth.
Build sixth.

Do not skip verification.