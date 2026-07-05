# Master Build Prompt — School Fee Management App (Flutter + Node.js + MongoDB)
### For use in Google Antigravity — split into sequential parts

---

## How to use this document

1. This is **not one prompt** — it's **15 prompts (Part 0 → Part 14)** meant to be pasted into Antigravity **one at a time, in order**.
2. Paste **Part 0** first. Let Antigravity finish and acknowledge before pasting **Part 1**.
3. Wait for each part to fully complete (files created, no errors) before moving to the next. Each part builds directly on top of the previous one — skipping ahead will break references.
4. If Antigravity asks a clarifying question mid-part, answer it using the spec already written in that part — don't let it invent new features.
5. Every part ends with an **Acceptance Checklist** — Antigravity should satisfy every line before you move on.
6. Nothing in here adds a feature beyond your two source documents (`mrj_school.docx` + the client brief). Where your documents were silent on a pure implementation detail (which exact backend framework, which state manager, etc.), I made one explicit, documented decision — listed below — instead of leaving it ambiguous for Antigravity to guess differently each time.

### Assumptions made to remove ambiguity (read before starting)

| Topic | Your documents said | Decision locked in below |
|---|---|---|
| Frontend | "Flutter (iOS, Android, Web Admin Portal)" | **Mobile only** (Android + iOS) — per your instruction. Web admin portal is dropped. |
| Backend | "Node.js / Dart Edge middleware" | **Node.js + Express** (the concrete option named) |
| State management | "e.g. Riverpod or BLoC" | **Riverpod** |
| DB | MongoDB Atlas, 4 collections specified | Kept exactly as specified, plus one minimal `admins` collection (your doc requires a Login page but never defined where the login credentials live — this is the smallest possible addition to make the explicitly-required login work, not a new feature) |
| Bulk WhatsApp | "must route through a cloud gateway API (Twilio or Meta Business API)" | Built as a **pluggable provider interface** with a safe mock/stub implementation, so it builds and runs without real API keys today, and you drop in real Twilio/Meta credentials later via `.env` |
| AI Draft Message | "Triggers an AI prompt" — provider unspecified | Built as a **pluggable AI provider interface** (env-configurable API key), default wired for Google Gemini API since no provider was named |
| Excel/CSV exports | Mixed "EXCEL" and "CSV" wording across pages | Backend generates real `.xlsx` (via `exceljs`) wherever your doc says "EXCEL", and RFC-4180-safe `.csv` wherever your doc says "CSV"/"export the log" |
| Dashboard aggregation | Doc suggests Atlas Triggers / Materialized Views for scale | Implemented as a single isolated `dashboardService` aggregation pipeline (correct for 450 students); the service is structured so it can be swapped for a materialized view later without touching the API or UI — Atlas Triggers themselves are an infra/console setup task, not app code, so they're called out as a future ops step, not built into the MVP |

| Distribution | Not in original docs — added per your follow-up request | **Android only, no Play Store.** Distributed as a direct-download signed APK served from the same backend you're already hosting (Part 14) — one URL is both the API and the install link. No Firebase/Play Store account needed. |

If any of these don't match what you want, edit that line in Part 0 before pasting it.

---

## PART 0 — Master Project Brief (paste this first, always)

```
You are building a production-ready mobile fee-management application for an Indian school (LKG to Grade 8, 450+ students). This is a multi-step build — I will give you the requirements in sequential numbered parts. For every part from now on:
- Do NOT invent, add, or assume any feature that isn't explicitly written in that part's instructions.
- Do NOT remove or break anything built in a previous part.
- Ask me before making any architectural decision not already specified.

TECH STACK (fixed for the entire project, do not deviate):
- Frontend: Flutter, targeting Android and iOS only (no web target).
- State management: Riverpod.
- Navigation: go_router.
- Networking: dio.
- Secure local storage: flutter_secure_storage (for JWT token only — never store raw credentials).
- Charts: fl_chart.
- File save/share on device: path_provider + share_plus.
- Backend: Node.js + Express.
- Database: MongoDB Atlas, accessed via Mongoose.
- Auth: stateless JWT (jsonwebtoken) + bcrypt for password hashing.
- Backend Excel generation: exceljs. Backend CSV generation: a small custom RFC 4180-safe CSV builder (wrap every field that could contain a comma, quote, or line break in double quotes).

PROJECT STRUCTURE (create this now, two top-level folders in the repo root):
- /backend  → Node.js + Express + Mongoose API
- /mobile_app → Flutter application

GLOBAL DESIGN PRINCIPLE — "Zero-Tolerance Data Integrity":
This app handles real school money. Every numeric financial value shown anywhere in the app (cards, charts, lists, exports) must come from one single source-of-truth calculation per screen — never two different code paths computing the same number. Every currency value displayed to the user must be formatted as Indian Rupees with lakh/thousand separators (₹1,25,000 style), and must NEVER render as NaN, null, undefined, or a raw floating point like 4250000.0001 — always fall back to ₹0 cleanly. Every destructive action (delete) requires explicit typed confirmation, never a simple Yes/No dialog. Every bulk/mass financial action requires a secondary "review impact before confirming" modal. These rules apply to every part below even when not repeated explicitly.

Acknowledge this brief and confirm the /backend and /mobile_app skeleton folders are created. Then wait for Part 1.
```

**Acceptance checklist for Part 0:** `/backend` and `/mobile_app` folders exist. No code written yet beyond empty scaffolds. Antigravity has confirmed it understands it will receive sequential parts.

---

## PART 1 — Backend & Mobile App Scaffolding

```
PART 1 of 13 — Project Scaffolding (Backend + Flutter)

CONTEXT: Continue in the same repo from Part 0. Do not build any feature logic yet — this part is pure scaffolding.

BACKEND (/backend):
1. Initialize a Node.js + Express project (package.json, npm).
2. Install: express, mongoose, dotenv, cors, jsonwebtoken, bcrypt, exceljs, helmet, morgan.
3. Create this folder structure:
   /backend
     /src
       /config      → db.js (Mongoose connection using process.env.MONGODB_URI)
       /models      → (empty for now, filled in Part 2)
       /routes      → (empty for now)
       /controllers → (empty for now)
       /middleware  → (empty for now)
       /utils       → (empty for now)
       app.js       → Express app setup: helmet, cors, morgan logger, JSON body parsing
       server.js    → starts the HTTP server, connects to MongoDB first
     .env.example   → list MONGODB_URI, JWT_SECRET, PORT, AI_API_KEY, AI_PROVIDER, WHATSAPP_PROVIDER, WHATSAPP_API_KEY, WHATSAPP_API_SECRET (all placeholders, no real values)
     .gitignore     → node_modules, .env
4. Create a standard JSON API response envelope used by every endpoint going forward:
   Success: { "success": true, "data": <payload>, "message": "..." }
   Error:   { "success": false, "error": "..." }
5. Create a global Express error-handling middleware that catches thrown errors and always returns the envelope above with an appropriate HTTP status code — never let a raw stack trace leak to the client.

FLUTTER (/mobile_app):
1. Create a new Flutter project named "school_fee_manager", Android + iOS platforms only.
2. Add dependencies: flutter_riverpod, go_router, dio, flutter_secure_storage, fl_chart, path_provider, share_plus, url_launcher, intl (for ₹ currency formatting and dates), open_filex.
3. Create this folder structure under /lib:
   /lib
     /core
       /api          → dio_client.dart (base Dio instance, reads base URL from a constants file, attaches JWT bearer token automatically from secure storage if present)
       /constants    → app_constants.dart (API base URL placeholder, e.g. http://localhost:5000/api)
       /theme        → app_theme.dart (a clean, professional light theme — primary color suited to an institutional/financial app, consistent typography scale)
       /utils        → currency_formatter.dart (formats integers as ₹ with Indian digit grouping, e.g. ₹8,45,000) and date_formatter.dart
     /router         → app_router.dart (go_router setup, currently a single placeholder splash route)
     /features       → empty folder, will hold one subfolder per feature added in later parts
     main.dart       → wraps app in ProviderScope, applies app_theme, uses app_router
4. Confirm the Flutter app builds and runs to a blank placeholder screen with no errors.

Do not implement any database models, any API endpoints, or any UI screens beyond the placeholder splash screen in this part. Stop and wait for Part 2.
```

**Acceptance checklist for Part 1:** Backend boots with `npm start` and connects to a Mongo URI without crashing (even if URI is a placeholder, the connection code path must exist and fail gracefully if missing). Flutter app compiles and launches to a blank screen. Folder structures match exactly what's listed above.

---

## PART 2 — Database Schemas & Core Backend Infrastructure

```
PART 2 of 13 — MongoDB Schemas + Core Backend Infrastructure

CONTEXT: Continuing in /backend from Part 1. Build the data layer now.

Create these Mongoose schemas exactly as specified — do not add extra fields beyond what's listed:

1. /src/models/Student.js
{
  student_id: String (unique, required, e.g. "ST001"),
  full_name: String (required),
  grade_id: ObjectId (ref: MasterConfig, required),
  section_id: ObjectId (ref: MasterConfig, required),
  phone_number: String (required, must be exactly 10 numeric digits — enforce with a Mongoose validator),
  avatar_url: String (optional),
  transport_route_id: ObjectId (ref: MasterConfig, default: null, representing "None"),
  balances: {
    tuition:   { paid: Number default 0, due: Number default 0 },
    transport: { paid: Number default 0, due: Number default 0 },
    other:     { paid: Number default 0, due: Number default 0 }
  },
  custom_fees: [ { fee_description: String, amount: Number, status: String } ],
  status: String (e.g. "cleared" / "pending", derived/stored field),
  timestamps: true
}

2. /src/models/Transaction.js  (kept as its OWN collection, never nested inside Student, to avoid MongoDB's 16MB document limit over a student's multi-year history)
{
  transaction_id: String (unique, required, e.g. "TXN_10045"),
  student_id: ObjectId (ref: Student, required, indexed),
  timestamp: Date (default now),
  fee_category: String (enum: ["tuition", "transport", "other"], required),
  amount_collected: Number (required, must be > 0),
  timestamps: true
}
Add a compound index on { student_id: 1, timestamp: -1 } for fast per-student history lookups, and an index on { timestamp: -1 } for the Master Ledger's date filtering.

3. /src/models/MasterConfig.js
{
  type: String (enum: ["grade", "section", "route"], required),
  name: String (required, trimmed),
  parent_id: ObjectId (ref: MasterConfig, default: null — only Sections use this, pointing to their parent Grade),
  timestamps: true
}
Add a unique compound index on { type: 1, name: 1 } using a case-insensitive collation so "Grade X" and "grade x" are treated as the same entry and cannot both be saved.

4. /src/models/AllocationLog.js
{
  log_id: String (unique, required, e.g. "ALC_1005"),
  timestamp: Date (default now),
  fee_category: String (enum: ["tuition", "transport", "other"], required),
  target_scope: Object (flexible — stores whatever cohort was targeted, e.g. { grade_id, section_id, route_id, label }),
  amount: Number (required, must be > 0),
  description: String (required, trimmed, cannot be empty or whitespace-only),
  timestamps: true
}

5. /src/models/Admin.js  (minimal addition required to make the Login Page in Part 3 functional — your spec describes login behavior but not where credentials are stored)
{
  username: String (unique, required),
  password_hash: String (required),
  timestamps: true
}
Add a one-time seed script /src/utils/seedAdmin.js that creates a single admin user from ADMIN_USERNAME / ADMIN_PASSWORD environment variables if no admin exists yet (hash the password with bcrypt before saving). Add these two variables to .env.example.

CORE INFRASTRUCTURE:
6. /src/middleware/auth.js — Express middleware that verifies the JWT from the Authorization: Bearer header on every protected route, attaches the decoded admin id to req.admin, and returns a 401 using the standard error envelope if missing/invalid/expired.
7. /src/utils/idGenerator.js — small helper to generate the human-readable IDs used across collections (ST### for students, TXN_##### for transactions, ALC_#### for allocation logs) by finding the current max and incrementing, so IDs are sequential and collision-free.
8. /src/utils/exportHelpers.js — two shared utility functions used by every export feature in later parts:
   - generateExcelBuffer(sheetName, columns, rows) using exceljs, returns an in-memory buffer.
   - generateCsvString(columns, rows) — your own RFC 4180-safe builder: wrap any field containing a comma, double-quote, or newline in double quotes (and escape internal double quotes by doubling them).
   Both helpers must accept a "filters applied" metadata object and embed it as a header row/section in the output, plus the generation timestamp.

Wire MasterConfig, Student, Transaction, AllocationLog, and Admin models into the app — confirm the backend still boots cleanly. Do not build any routes, controllers, or Flutter screens yet. Stop and wait for Part 3.
```

**Acceptance checklist for Part 2:** All five models exist with the exact fields above. The case-insensitive unique index on MasterConfig works (verify by trying to insert "Grade X" twice in different casing and confirming the second insert fails). Backend still boots with no route logic yet.

---

## PART 3 — Authentication (Login-Only, Zero-Tolerance Security)

```
PART 3 of 13 — Authentication Epic

CONTEXT: Continuing in both /backend and /mobile_app. Build the complete login flow — this is the ONLY entry point to the app. There is no registration, no public access, no guest mode anywhere.

BACKEND:
1. POST /api/auth/login — accepts { username, password }.
   - Look up the Admin by username. Compare password with bcrypt.
   - On success: return a signed JWT (reasonable expiry, e.g. 12h) and the admin's username in the success envelope.
   - On failure (wrong username OR wrong password): return the exact same generic error message "Invalid Credentials" with the same HTTP status code in both cases — never reveal which part was wrong (prevents username enumeration).
   - Do NOT implement any account lockout state on the backend in this part — lockout is a pure frontend session-state behavior per the spec below (re-checked after refresh), so keep the backend stateless and simple here.
2. Apply the auth.js middleware from Part 2 to every route you will build from Part 4 onward (do this incrementally as you build each route file — note it here so you don't forget).

FLUTTER:
1. Create /lib/features/auth with: login_screen.dart, auth_provider.dart (Riverpod), auth_repository.dart (calls POST /api/auth/login via dio_client).
2. Login screen UI: username field, password field (type: password, masked dots/asterisks ALWAYS — do not add a "show password" eye icon anywhere on this screen, this is a deliberate security requirement, not an oversight), Login button. No "Sign Up", "Forgot Password", "Create Account", or any other link on this screen — login form only.
3. Zero-Tolerance behavior to implement exactly:
   - Maintain a local (in-memory, not persisted) failedAttemptCount starting at 0.
   - On a failed login: increment failedAttemptCount, clear the password field completely, show the generic message "Invalid Credentials" (never anything more specific).
   - When failedAttemptCount reaches 5: disable the Login button entirely (disabled=true) and make the whole form inert/unresponsive. The only way out of this locked state is a full app restart / screen reload (i.e., re-navigating to the login screen resets the counter — do not persist the lockout across restarts).
   - On successful login: reset failedAttemptCount, store the JWT in flutter_secure_storage (never in plain shared preferences, never in any local/session storage equivalent), and navigate to the app's main shell (a placeholder home screen for now — full Dashboard comes in Part 9).
4. Update go_router: unauthenticated users always land on /login. Add a simple auth guard/redirect using the Riverpod auth state so a logged-in user skipping back to /login is redirected to the main shell, and a logged-out/expired-token user trying to reach any other route is redirected to /login.
5. Add a logout action (simple icon/button on the placeholder home screen) that clears the secure-stored JWT and returns to /login.

Stop and wait for Part 4.
```

**Acceptance checklist for Part 3:** Wrong username and wrong password both show identical "Invalid Credentials" text. Password field empties after every failed attempt. 5th consecutive failure visibly disables the login button. No password visibility toggle exists anywhere on the screen. JWT is stored only via flutter_secure_storage. No registration UI exists anywhere in the app.

---

## PART 4 — Master Configuration (Grades, Sections, Routes)

```
PART 4 of 13 — Master Configuration Epic

CONTEXT: This page defines the school's taxonomy (Grades → Sections, and independent Transport Routes) that every other module will reference via dropdowns. Build it completely now, before Student Management, because Part 5 depends on these existing.

BACKEND (all routes protected by the auth.js middleware from Part 3):
1. GET /api/master-config?type=grade|section|route&parent_id=<id> — list entries, optionally filtered by type and/or parent (for fetching sections under one grade).
2. POST /api/master-config — create a new entry.
   - name is required, trim it server-side before validating.
   - Reject empty or whitespace-only name.
   - If type is "section", parent_id (a valid existing Grade's id) is required — reject creation if missing or if the referenced grade doesn't exist.
   - If type is "grade" or "route", parent_id must be null.
   - Enforce case-insensitive duplicate rejection using the index from Part 2 (catch the duplicate-key error and return a clean "already exists" message via the error envelope, not a raw Mongo error).
3. PUT /api/master-config/:id — edit name. Same trim + duplicate validation as above.
4. DELETE /api/master-config/:id — before deleting, check:
   - If deleting a Grade: check whether any Sections have this grade as parent_id, OR any Students reference this grade_id. If either exists, block deletion and return a clear error explaining what's still linked (don't auto-cascade-delete silently).
   - If deleting a Section or Route: check whether any Students reference this section_id / transport_route_id. If so, block deletion with the same kind of explanatory error, forcing the admin to reassign those students first.

FLUTTER:
1. Create /lib/features/master_config with a tabbed screen: "Grades" | "Sections" | "Routes".
2. Grades tab: simple list + floating "Add Grade" button opening a small dialog (name field, trimmed, inline validation message on duplicate).
3. Sections tab: a "Parent Grade" dropdown must be selected FIRST before the section list/add controls become usable at all (lock the Add button until a grade is chosen). Once a grade is selected, show that grade's sections with Add/Edit/Delete.
4. Routes tab: same simple list + Add/Edit/Delete pattern as Grades (routes are independent, no parent).
5. Edit and Delete actions on every row. Delete always opens a confirmation dialog (standard Yes/No is fine here — the harder typed "DELETE" confirmation from your spec is reserved specifically for deleting a Student record in Part 6, not for config items). If the backend blocks a delete because students are linked, surface that backend message clearly to the user in the dialog.
6. All three tabs' data should be fetched through a shared master_config_provider.dart (Riverpod) so later parts (Student forms, Fee Allocation, Dashboard filters) can reuse the same cached grade/section/route lists instead of re-fetching everywhere.

Stop and wait for Part 5.
```

**Acceptance checklist for Part 4:** Cannot create a duplicate grade name regardless of casing. Cannot create a Section without first picking a parent Grade. Deleting a Grade/Section/Route that has students linked is blocked with a clear message, not silently cascaded. The Add Section button is genuinely disabled until a parent grade is chosen.

---

## PART 5 — Student Fee Management: Backend & Transport Route Logic

```
PART 5 of 13 — Student Fee Management Epic (Backend) + Transport Route Mapping

CONTEXT: This is the core operational module. Build the complete backend now; the Flutter UI for it comes in Part 6. All routes protected by auth middleware.

ENDPOINTS:
1. GET /api/students — list with query params: grade_id, section_id, status (cleared|pending), search (matches against full_name OR student_id, case-insensitive partial match). Support pagination (page, limit) since there are 450+ students. Return each student with their grade/section/route names populated (not just raw ObjectIds) so the Flutter list doesn't need extra lookups.
2. GET /api/students/:id — single student full profile (populated grade/section/route).
3. GET /api/students/:id/history — that student's transactions from the Transaction collection, sorted newest-first. Return an empty array cleanly if none exist (never an error for zero results).
4. POST /api/students — create a student.
   - full_name is required (non-empty after trim) — block save without it.
   - phone_number: strip all spaces, hyphens, brackets, and a leading country code (+91 or 91 prefix) server-side, then validate exactly 10 numeric digits remain. Block save if not.
   - transport_route_id: defaults to null/"None" if not provided — never left in an undefined state.
   - Generate the student_id using the idGenerator util from Part 2.
   - balances all start at { paid: 0, due: 0 } for tuition/transport/other unless explicitly provided.
5. PUT /api/students/:id — edit student info (name, grade, section, phone, avatar, transport_route_id, and manual override of outstanding balances). Apply the same phone sanitization/validation and name-required rules as create.
   - Transport Route Logic: if transport_route_id changes, this is purely a reassignment — it does NOT itself create or remove a transport fee balance. The actual fee amount changes only ever happen through the Fee Allocation flow (Part 8). Just persist the new route reference here. If the student is moved to "None" (null), no special charge logic triggers — they simply stop being a target for future transport allocations.
6. PUT /api/students/:id/fees — "Update Fees" action (record a payment).
   - Body: { fee_category: "tuition"|"transport", amount: Number }.
   - Reject amount <= 0 immediately.
   - Reject if amount > the current due balance for that category (overpayment block) — return a clear error, do not clamp/auto-correct silently.
   - On success, atomically: decrement balances.<category>.due by amount, increment balances.<category>.paid by amount, AND create a new Transaction document (generate transaction_id via idGenerator) in the same logical operation. Use a Mongo session/transaction if your driver setup supports it, so the balance update and the transaction record never get out of sync.
7. POST /api/students/:id/other-fee — "Add Other Fee" action.
   - Body: { fee_description: String (required, trimmed, non-empty), amount: Number (required, > 0) }.
   - Push to custom_fees array, and increase balances.other.due by amount.
8. DELETE /api/students/:id — delete the student document. (The typed-"DELETE" confirmation is a frontend-only gate built in Part 6; the backend simply performs the deletion when called — but still re-check before deleting that this doesn't violate any "Immutable Dependency" rule from Part 4's master-config protections, i.e. deleting a student is fine, it's deleting a Grade/Section/Route WHILE students reference it that's blocked.)
9. GET /api/students/export — accepts the same filter query params as the list endpoint PLUS a list of specific student IDs (for "export only selected rows"). Returns an .xlsx buffer (via the exportHelpers util from Part 2) containing exactly those filtered/selected rows — never more. Include the active filters and generation timestamp in the sheet header. Filename pattern: Students_Export_<grade-or-All>_<YYYY-MM-DD_HHMM>.xlsx.

VALIDATION RULES TO ENFORCE EVERYWHERE IN THIS PART (re-affirming Zero-Tolerance rules from your spec):
- No negative numbers accepted in ANY fee-related numeric field, ever.
- A field left blank/deleted by the user during edit must parse as 0, never null/NaN — guard this in the request validation layer, not just hope the frontend handles it.
- Overpayment is blocked server-side even if the Flutter app somehow allows it client-side — never trust the client alone for financial rules.

Stop and wait for Part 6.
```

**Acceptance checklist for Part 5:** Attempting to pay more than the due balance is rejected with a clear error. A phone number pasted with spaces/hyphens/+91 is cleanly normalized to 10 digits or the save is blocked. Every successful "Update Fees" call produces exactly one new Transaction document and one balance update — never one without the other. The export endpoint only ever returns the rows matching the filters/selection passed in.

---

## PART 6 — Student Fee Management: Flutter UI

```
PART 6 of 13 — Student Fee Management Epic (Flutter UI)

CONTEXT: Build the Flutter screens consuming the endpoints from Part 5. This is the main/most-used screen of the app.

1. Create /lib/features/students with: students_list_screen.dart, student_provider.dart, student_repository.dart, and one file per dialog/sub-screen listed below.

2. students_list_screen.dart layout, top to bottom:
   - Search bar (search by Student ID or Name, debounced, hits GET /api/students with the search param).
   - Filter row: Grade dropdown, Section dropdown (populated from the master_config_provider built in Part 4; Section options narrow to the selected Grade), Status dropdown (All / Cleared / Pending).
   - A bulk-actions bar: "Select All" checkbox (label flips to "Deselect All" once anything is selected), "Export Excel" button (calls GET /api/students/export with the current selection — disabled/hidden when nothing is selected), and a "Bulk WhatsApp Reminder" button (built fully in Part 7 — for now just wire the button and selection state, leave the actual dispatch as a stub that Part 7 will fill in).
   - A scrollable list of student cards (paginated/infinite-scroll given 450+ students).

3. Each student card shows: a leading selection checkbox, avatar, full name, Student ID, Class + Section, a small status dot (green = cleared, orange = pending dues), and three fee-summary rows (Tuition Paid/Balance, Transport Paid/Balance, Other Fees Paid/Balance — all currency-formatted via the util from Part 1, never raw numbers). A trailing three-dot (⋮) menu button.

4. The ⋮ menu opens these actions (each as its own bottom sheet/dialog):
   a. View Student Profile — read-only summary: basic info, formatted phone, total paid (sum across categories), total pending (sum across categories), count of other-fee items, and the assigned Transport Route shown as a visible badge.
   b. View Fee History — chronological list from GET /api/students/:id/history, newest first. Show a clean "No payments yet" empty state if the list is empty — never a blank screen or error.
   c. Update Fees — form pre-filled with current Tuition/Transport balances. Two amount input fields. Client-side: reject negative input instantly (numeric input formatter), and show a live validation message if the entered amount exceeds that field's current due balance, disabling Submit until corrected. On submit, call PUT /api/students/:id/fees per category entered.
   d. Add Other Fee — form: Fee Description (required) + Amount (required, > 0). Calls POST /api/students/:id/other-fee.
   e. Edit Student — form pre-filled with all current data: Name, Class/Grade, Section, Phone, Avatar, Transport Route dropdown (defaults to "None" if unset), plus manual override fields for outstanding balances (Tuition/Transport/Other due). Apply the same not-negative / blank-becomes-zero rules client-side as a first line of defense (the backend in Part 5 is the real guard).
   f. Delete Student — opens a dialog with a text input. The Delete button stays disabled until the user types the exact case-sensitive word DELETE, character-for-character. Only then does it become enabled and call DELETE /api/students/:id.
   (Draft AI Message and Send WhatsApp Reminder menu items go here too, but their full behavior is built in Part 7 — for now add the two menu entries as visible-but-stubbed so the menu layout is final.)

5. Empty/zero states throughout this screen must render "0" or "₹0" cleanly — never NaN, null, or a crash — exactly per the global rule from Part 0.

Stop and wait for Part 7.
```

**Acceptance checklist for Part 6:** Delete button is provably unclickable until "DELETE" is typed exactly. Update Fees form blocks submission live if amount exceeds balance. Select All correctly toggles its own label. Fee History shows a clean empty state for a student with no payments. Every currency value on every card is ₹-formatted.

---

## PART 7 — WhatsApp Reminders & AI Draft Message

```
PART 7 of 13 — WhatsApp Reminder Integration + AI Draft Message

CONTEXT: Fill in the two stubbed menu items from Part 6, plus the Bulk Reminder bar.

BACKEND:
1. POST /api/students/:id/draft-message — builds a short, polite reminder message using the student's exact current name and outstanding balances (tuition/transport/other due), then sends it to a pluggable AI provider for light polishing/drafting.
   - Create /src/utils/aiProvider.js — an interface with one function draftMessage(promptContext) that reads AI_PROVIDER and AI_API_KEY from env. Implement a default Gemini API call path (since no provider was specified in the brief, Gemini is used as the default since it integrates cleanly with this toolchain) AND wrap it in a try/catch that falls back to a clean locally-templated message (no AI call) if the API key is missing or the call fails — the feature must never hard-crash just because no AI key is configured yet.
   - Return the drafted text string in the success envelope.
2. POST /api/whatsapp/send-individual/:id — validates the student has phone_number (valid 10-digit) AND total outstanding balance > 0. If either check fails, return a clear error (do not attempt anything). If both pass, build the wa.me deep link (https://wa.me/91<number>?text=<url-encoded reminder message>) and return that URL string to the frontend — actually opening WhatsApp happens on-device.
3. Create /src/utils/whatsappProvider.js for BULK sends — a pluggable interface (because mobile OS-level anti-spam rules block an app from rapidly firing dozens of native WhatsApp intents in a row, bulk must go through a real cloud gateway, never the device's WhatsApp app). Implement it against env vars WHATSAPP_PROVIDER ("twilio" | "meta") / WHATSAPP_API_KEY / WHATSAPP_API_SECRET, with a safe mock mode (simulates success after a short delay) used automatically whenever those env vars are empty, so the feature is fully testable before real credentials exist.
4. POST /api/whatsapp/send-bulk — body: { student_ids: [...] }.
   - Server-side filtering: silently drop any student in the list with zero outstanding balance OR an invalid/missing phone number — do not error out the whole batch for this, just exclude them.
   - Dispatch the remaining eligible list through whatsappProvider.js.
   - Return a summary: { totalSelected, eligible, sent, skipped } in the success envelope.

FLUTTER:
1. Draft AI Message menu item: calls POST /api/students/:id/draft-message, shows the result in a read-only dialog with a "Copy to Clipboard" button.
2. Send WhatsApp Reminder menu item: calls POST /api/whatsapp/send-individual/:id. If the backend returns its validation error (zero balance / bad phone), show that message to the user and stop — do not attempt to open WhatsApp. If it returns a URL, use url_launcher to open it (this opens the native WhatsApp app or web WhatsApp pre-filled).
3. Bulk WhatsApp Reminder bar button (from Part 6): on tap, call POST /api/whatsapp/send-bulk with the selected student IDs. While the request is in flight, show a progress indicator (e.g. a linear progress bar with a "Sending reminders…" label — this is a backend dispatch, not a literal per-message device animation). On completion, show a summary dialog ("Sent: X, Skipped: Y") and then clear the current selection, returning the list to its normal unselected state.

Stop and wait for Part 8.
```

**Acceptance checklist for Part 7:** Sending an individual reminder to a student with ₹0 due is blocked with a message, never opens WhatsApp. A bulk send silently excludes zero-due/invalid-phone students from the count without failing the whole action. The AI draft endpoint still returns a usable message even with no AI_API_KEY configured. Selection clears after a bulk send completes.

---

## PART 8 — Fee Allocation (Bulk Billing)

```
PART 8 of 13 — Fee Allocation Epic

CONTEXT: This is the highest-risk financial page — it can bulk-bill an entire cohort in one action. Build it with maximum guardrails.

BACKEND:
1. POST /api/allocations/preview — body: { fee_category: "tuition"|"transport"|"other", target: {...scope...}, amount, description }. Does NOT write anything. It just resolves which students match the target scope and returns { matchedCount, sampleStudentNames } so the frontend can show the confirmation modal's impact summary before committing.
   - Target scope rules: Tuition → grade-level scope (a specific grade or "All Grades"). Transport → a specific Route only (never "All Routes" as a single click — see validation rules below). Other Fees → Grade + optional Section.
2. POST /api/allocations — actually executes the allocation. Body shape is the same as preview.
   - Validation (reject before touching the database if any fail):
     - amount must be a positive integer > 0. Reject 0, negative, null, NaN outright.
     - description is required, trimmed, and cannot be empty/whitespace-only.
     - target must be explicitly provided — there is no implicit default; the caller cannot omit target and have it silently mean "All Grades". The admin must have actively chosen a scope.
   - Execution: resolve the matching student IDs (same logic as preview), then perform a single atomic MongoDB bulk update incrementing the relevant balances.<category>.due field for every matched student (use bulkWrite with $inc — never a loop of individual saves).
   - Transport-specific rule: only students whose transport_route_id exactly matches the targeted route are touched. Students with transport_route_id = null ("None"/Dayscholars) are never touched by a transport allocation, no matter how the scope is phrased.
   - After the bulk update succeeds, create one AllocationLog document (generate log_id via idGenerator) recording category/target/amount/description/timestamp. This log is never editable or deletable through any API — do not build PUT/DELETE for it.
3. GET /api/allocations/log — list allocation history, newest first, with pagination.
4. GET /api/allocations/log/export — returns a CSV (via exportHelpers from Part 2) of the full allocation history, RFC-4180 escaped, with a header noting the export timestamp.

FLUTTER:
1. Create /lib/features/fee_allocation with a screen using a top TabBar: Tuition | Transport | Other.
2. Each tab shows the relevant target selector (Grade dropdown for Tuition, Route dropdown for Transport, Grade+optional-Section for Other — all sourced from master_config_provider), an Amount field (numeric keyboard, instantly rejects non-positive input via input formatter — pair this with HTML-style min constraint logic equivalent: clamp/reject at the input layer, never let a non-positive value reach the Submit button enabled state), and a Description field (required, disabled Submit while empty/whitespace).
3. On "Assign Fee" tap: call the /preview endpoint first, then show a confirmation modal stating exactly "You are about to assign ₹<amount> to <matchedCount> students in <target label>." with Cancel / "Yes, Assign" buttons. Only on "Yes, Assign" does it call POST /api/allocations.
4. A "Log" view/tab showing the allocation history list (read-only, no edit/delete affordances anywhere in this UI) with an Export button calling the CSV export endpoint and saving/sharing the file via path_provider + share_plus.
5. After a successful allocation, trigger a refresh of any currently-cached student list / dashboard providers so the rest of the app reflects the new balances immediately rather than showing stale data.

Stop and wait for Part 9.
```

**Acceptance checklist for Part 8:** Submitting with amount = 0 or a blank description is impossible (button stays disabled, not just an error after the fact). Every allocation always shows the preview-confirmation modal first — there is no path that skips it. A Transport allocation to "Route A" never touches a student whose route is "None". The allocation log has no edit or delete option anywhere in the UI.

---

## PART 9 — Dashboard

```
PART 9 of 13 — Dashboard Epic

CONTEXT: Build the executive overview screen. Every number and every chart on this screen must be computed from one single aggregation call per filter state — never two separate calls that could drift apart.

BACKEND:
1. Create /src/services/dashboardService.js — one function getDashboardMetrics(gradeFilter) that runs MongoDB aggregation pipeline(s) against Student + Transaction collections and returns ONE object:
   {
     studentStrength: Number,
     totalPaid: Number,
     pendingDue: Number,
     paidVsUnpaidPercentage: { paid: Number, unpaid: Number },  // must always sum to exactly 100 (integer rounding)
     monthlyCollectionTrend: [ { month: "Jan", amount: Number }, ... ]
   }
   Structure this service as a clean isolated module (not inline in the controller) specifically so it can later be backed by a precomputed/materialized collection without changing the API contract, if the school's data volume grows significantly beyond its current 450 students.
2. GET /api/dashboard?grade_id=<id or omitted-for-all> — calls dashboardService and returns the single metrics object above in the success envelope. This is the ONLY data source the Flutter dashboard screen is allowed to call for its numbers and charts.
3. GET /api/dashboard/export?grade_id=... — generates an .xlsx (via exportHelpers) containing the Student Strength summary, Pending Fee summary, Paid Fee summary, and the raw numbers behind the charts, plus the active grade filter and generation timestamp, exactly mirroring what's on screen for that filter. Filename: Dashboard_Export_<grade-or-All>_<YYYY-MM-DD_HHMM>.xlsx.

FLUTTER:
1. Create /lib/features/dashboard with dashboard_screen.dart and dashboard_provider.dart.
2. Header: "Dashboard" title, a single Grade filter dropdown (default "All Grades", sourced from master_config_provider), and a "Download EXCEL" button calling the export endpoint and saving/sharing the file.
3. Statistics cards (all reading from the one dashboard_provider state, never independently re-fetched): Student Strength, Total Paid Fee, Pending/Unpaid Fee — all ₹-formatted, all showing "0"/"₹0" cleanly for an empty/zero result.
4. Charts (fl_chart), all bound to the exact same provider state as the cards above:
   - Bar or line chart: monthly fee collection trend.
   - Pie/doughnut chart: Paid vs Unpaid percentage (must visually read as summing to 100%).
   - A second paid-vs-unpaid view as a doughnut/progress-ring showing the actual ₹ amounts (not just %).
5. Changing the Grade dropdown re-fetches dashboard_provider once and updates every card and every chart together — never let one card update on a slightly different timing/code path than the charts.
6. Charts must render a visible (even if flat/empty) coordinate system when filtered data is zero — never disappear or throw a layout error on a zero-value dataset.

Stop and wait for Part 10.
```

**Acceptance checklist for Part 9:** Switching the grade filter updates every card and every chart in the same instant, all derived from one fetched object. The Paid/Unpaid pie chart always reads as summing to 100%. Filtering to a grade with zero students still renders clean ₹0 cards and a visible-but-empty chart, never a crash or NaN.

---

## PART 10 — Tuition Fee Page & Transport Fee Page

```
PART 10 of 13 — Dedicated Tuition Fee Page + Transport Fee Page

CONTEXT: These are two separate, simpler pages distinct from the Dashboard and from Student Management — each focused on ONE fee category only.

BACKEND:
1. GET /api/fees/tuition/summary?grade_id=&section_id= — returns { totalPending, totalPaid } computed strictly from balances.tuition across matching students.
2. GET /api/fees/tuition/list?status=paid|unpaid&grade_id=&section_id=&search= — returns the matching student rows (ID, name, class, section, tuition paid, tuition due) for the requested status, with search by Student ID supported.
3. GET /api/fees/tuition/export?status=paid|unpaid&grade_id=&section_id= — .xlsx of exactly the filtered list above.
4. Repeat the same three endpoints under /api/fees/transport/... but computed strictly from balances.transport, with section_id meaningful here too (per your spec) alongside grade.

FLUTTER:
1. Create /lib/features/tuition_fee/tuition_fee_screen.dart:
   - Total Pending (All Grades) summary + Total Paid (All Grades) summary, each independently filterable by Grade then Section (tuition only).
   - Search by Student ID.
   - "Download unpaid student list (Excel)" and "Download paid student list (Excel)" buttons, each respecting whatever Grade/Section filter is currently active.
2. Create /lib/features/transport_fee/transport_fee_screen.dart — identical layout and behavior to the Tuition screen, but every number, filter, and export is scoped to Transport fees only.
3. Both screens are independent, read-focused utility pages — no edit/payment actions live here (that all happens in Student Fee Management from Part 6); these are filtering + reporting views only.

Stop and wait for Part 11.
```

**Acceptance checklist for Part 10:** Tuition page numbers never include transport or other-fee amounts, and vice versa. Both "download paid" and "download unpaid" exports respect the currently selected Grade/Section filter. Student ID search works on both pages independently.

---

## PART 11 — Master Ledger

```
PART 11 of 13 — Master Ledger Epic

CONTEXT: A strictly read-only, immutable chronological feed of every payment ever recorded, used for accounting reconciliation. There must be zero edit or delete affordances anywhere on this page.

BACKEND:
1. GET /api/ledger?search=&dateRange=today|yesterday|thisWeek|thisMonth|allTime — queries the Transaction collection (joined/populated with student name + grade for display), defaulting to "thisWeek" if no dateRange is passed. search matches against student name, student ID, or grade name. Returns the filtered transaction list AND a totalCollection sum of exactly those filtered rows — computed server-side from the same filtered query, never as a separate calculation that could drift from the list.
2. GET /api/ledger/export?search=&dateRange=... — CSV (RFC-4180 safe, via exportHelpers) of exactly the filtered rows currently matching those params, with a header line stating the active filters (e.g. "Filters Applied: Date: Today") and the export timestamp. Never include rows outside the active filter.

FLUTTER:
1. Create /lib/features/ledger/ledger_screen.dart:
   - On load, default to "This Week" and show that period's transactions + total immediately.
   - Search bar (name/ID/grade) and a date-range dropdown (Today / Yesterday / This Week / This Month / All Time) — every change re-fetches the one ledger endpoint and updates both the list and the total-collection banner together, atomically, from the same response.
   - Each row: Transaction ID, timestamp, student name + ID, grade, fee category, amount (₹-formatted).
   - Total Collection banner at the top, always reflecting exactly the currently visible filtered rows.
   - Zero-results state: "No transactions found" with the total reading ₹0 — never a crash or blank screen.
   - Export button calling the CSV export endpoint with the active filters, saved/shared via path_provider + share_plus.
2. There must be NO edit icon, NO delete icon, and NO long-press context menu anywhere on this screen's rows — it is permanently read-only by design.

Stop and wait for Part 12.
```

**Acceptance checklist for Part 11:** No edit/delete control exists anywhere on this screen. Changing the search or date filter updates the list and the total banner in the same instant from one response. An empty result set still shows a clean ₹0 total and a friendly empty message.

---

## PART 12 — Global Hardening, Export Consistency & Final QA Pass

```
PART 12 of 13 — Final Hardening & Cross-Cutting QA

CONTEXT: No new features in this part — this is a full pass back over everything built in Parts 1–11 to verify the Zero-Tolerance rules actually hold end-to-end, and to harden a few cross-cutting concerns that touch every module.

BACKEND:
1. Re-audit every numeric input endpoint across students, fee allocation, and other-fee creation: confirm every single one rejects negative numbers and treats a missing/blank numeric field as 0, never null/NaN/undefined, at the validation layer (not just relying on the model defaults).
2. Re-audit every export endpoint (students, dashboard, tuition, transport, allocation log, ledger): confirm each one only ever returns rows matching the exact filters passed in that specific request, includes a generation timestamp, and uses the shared RFC-4180/exceljs helpers from Part 2 consistently (no export should use a different ad-hoc CSV-building approach).
3. Confirm the JWT auth middleware is applied to every single route across every router file — do a full route-by-route check, there should be no accidentally-public financial endpoint.
4. Add basic rate-limiting (e.g. express-rate-limit) specifically on /api/auth/login to add a real backend-side brute-force deterrent alongside the frontend's 5-attempt UI lockout from Part 3.
5. Confirm no endpoint anywhere ever returns a raw Mongo/stack-trace error to the client — every error path must go through the standard error envelope with a clean message.

FLUTTER:
1. Re-audit every screen built since Part 3 for currency formatting consistency — every ₹ value anywhere in the app must go through the single currency_formatter util from Part 1, never an inline ad-hoc format.
2. Re-audit every list/detail screen for loading states (a visible spinner/skeleton while a dio call is in flight) and error states (a retry-able message if a call fails) — no screen should ever show a frozen blank view on slow network or failure.
3. Confirm flutter_secure_storage is the only place the JWT is ever written, and that logout fully clears it.
4. Confirm the app behaves correctly across a few different phone screen sizes (small phone width up to a large phone/phablet) without overflow errors on the student cards, dashboard cards, or fee allocation tabs — this is a mobile-only app, so this is the relevant "responsive" check (not web breakpoints).
5. Run a full manual pass re-testing each Zero-Tolerance rule from the original brief end-to-end as a single regression list: overpayment block, negative-input block, typed-DELETE gate, generic login error, 5-attempt lockout, transport "None" never billed, allocation preview-before-confirm, ledger immutability, dashboard visual parity, and every empty/₹0 state.

Produce a short final summary of anything found and fixed during this pass.
```

**Acceptance checklist for Part 12:** A written regression summary exists confirming each Zero-Tolerance rule was re-verified. No screen lacks a loading or error state. No currency value in the app bypasses the shared formatter.

---

## PART 13 — Run, Build & Handover

```
PART 13 of 13 — Final Run & Handover

CONTEXT: The application is feature-complete per Parts 1–12. This final part is just getting it into a runnable, demoable state for the client.

1. Confirm the backend starts cleanly with a real (or clearly-documented placeholder) MONGODB_URI and JWT_SECRET, and that the seedAdmin script successfully creates one working admin login from env vars on first run.
2. Confirm the Flutter app's API base URL constant is clearly isolated in one file (from Part 1) so it can be pointed at a local backend during testing and a deployed backend later, without touching any other file.
3. Build the Flutter app for both Android (apk/appbundle) and iOS to confirm there are no platform-specific build errors.
4. Produce a short README in the repo root covering: how to set environment variables for both /backend and /mobile_app, how to seed the first admin account, and a one-paragraph summary of each of the app's pages for a non-technical handover to the school.

This completes the build.
```

**Acceptance checklist for Part 13:** Backend runs locally end-to-end against a real Mongo URI with one seeded admin login. Flutter app builds for both Android and iOS without errors. A README exists explaining setup and a plain-language tour of the app's pages.

---

## PART 14 — Android Release Build + Direct-Download Distribution (No Play Store)

```
PART 14 of 15 — Signed Release APK + Self-Hosted Download Page

CONTEXT: The client does not want this published to the Google Play Store. Instead, the app must be shareable as a single link that downloads a working, installable APK directly — reusing the same backend that's already being hosted, so no separate distribution service (Play Store, Firebase, etc.) is needed.

ANDROID RELEASE CONFIGURATION (/mobile_app):
1. Set the real app name and a proper Android applicationId (not the placeholder "school_fee_manager" package — use a real reverse-domain style id, e.g. com.<schoolname>.feemanager) in android/app/build.gradle and the app manifest.
2. Add flutter_launcher_icons and flutter_native_splash as dev dependencies. Configure both to use a placeholder icon/splash for now (a simple colored background with the app's initial/name) — these are meant to be swapped for the school's real logo later by just replacing one image file, document that in the README.
3. Configure Android release signing properly (NOT using the Flutter debug keystore):
   - Add android/key.properties to .gitignore (this file must never be committed).
   - Add a key.properties.example with placeholder fields: storePassword, keyPassword, keyAlias, storeFile.
   - Update android/app/build.gradle to read signing config from key.properties when present, and define a "release" buildType using it.
   - Add a clear comment block in the README explaining that the actual keystore file must be generated once by the developer locally (not by an AI agent) using the `keytool` command, and that this keystore + its passwords must be backed up safely — losing it means future app updates can't be installed over the existing one without users uninstalling first.
4. Add a small constant in the app, e.g. APP_VERSION_CODE, that mirrors the versionCode set in pubspec.yaml/build.gradle, so the running app always knows its own build number.

SELF-HOSTED DOWNLOAD PAGE (/backend):
5. Add a /backend/public/releases folder (gitignored except for a .gitkeep) where the signed release APK will be placed after each build.
6. Add a small in-memory or simple JSON-file-backed "current release" record in the backend: { version_name, version_code, apk_filename, release_notes, uploaded_at }.
7. POST /api/admin/releases — protected by the auth middleware — lets the admin (you, the developer, logged in) upload a new APK file (multer for the file upload) into /public/releases, and updates the "current release" record above. Old APK files can stay in the folder for rollback, but only the current one is linked from the download page.
8. GET /api/app-version — public, no auth — returns the current release's { version_name, version_code } so the running app can compare against APP_VERSION_CODE and show a simple "A new version is available" banner with a link to the download page if the backend's version_code is higher. This is the only "update mechanism" needed for a sideloaded app with no Play Store.
9. GET / (backend root, public, no auth) — serve one clean static HTML page (plain HTML/CSS, no framework needed) showing: the app/school name, a one-line description, the current version number, and a prominent "Download for Android" button linking to GET /download.
10. GET /download (public, no auth) — streams the current release APK file as a downloadable attachment with the correct Content-Type (application/vnd.android.package-archive) so phone browsers handle it as an installable file rather than trying to open it as text.

Stop and wait — this is the final part. After this, deployment itself (creating hosting accounts, pointing a domain, running the first deploy) is a manual step for you, covered below — not something to paste into Antigravity.
```

**Acceptance checklist for Part 14:** The release build uses a real signing config reading from a gitignored `key.properties`, never the debug keystore. The backend root URL renders a working download page, and `/download` actually streams a valid, installable APK with the right content type. `/api/app-version` returns a real version object with no auth required. No APK or keystore file is committed to git.

---

## After Antigravity finishes: manual steps to actually go live

Antigravity can't create accounts or run interactive logins for you — these last steps are yours, and they're short:

1. **Generate the real signing keystore once**, locally, using a command like:
   `keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias feeapp`
   Store the resulting `.jks` file and the passwords somewhere safe (password manager / school's secure drive) — back it up immediately. If you lose it, future updates can't be installed on top of the existing app.
2. **Build the signed APK**: `flutter build apk --release`. The file appears at `build/app/outputs/flutter-apk/app-release.apk`.
3. **Deploy the backend** to whichever host you choose (Render/Railway are the easiest to start with): connect your GitHub repo, set the environment variables from `.env.example` (your real `MONGODB_URI`, `JWT_SECRET`, admin seed credentials), and deploy. You'll get a live URL like `https://your-app.onrender.com`.
4. **Upload the first release**: call `POST /api/admin/releases` once (e.g. with a tool like Postman, or a tiny one-time script) to push the signed APK to your live backend.
5. **Share one link** with the school: `https://your-app.onrender.com`. That page shows the download button — they tap it, allow "install from unknown sources" the first time Android asks, and they're in. Every time you ship an update, you just upload a new release the same way and their next app-open shows the "update available" banner from Part 14.
