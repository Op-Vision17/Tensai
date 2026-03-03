# Tensai Flutter App — Full Wireframe

**Purpose:** Mobile client for the Tensai AI Study Copilot API (LangGraph learning project). Includes auth and history. Users sign in, upload study materials, ask questions, and get answers with sources; past Q&A are saved in history.

---

## 1. App overview

| Item | Description |
|------|--------------|
| **App name** | Tensai |
| **Tagline** | AI Study Copilot |
| **Backend** | Existing FastAPI app (`POST /ask`, `POST /ingest/upload`, `POST /ingest/text`, `GET /health`) |
| **Users** | Students / learners who want to study from their documents and ask questions |

---

## 2. User flows (high level)

1. **First launch** → Login or Sign up (if no token) → Set backend URL in Settings if needed.
2. **Add sources** → Upload a file (PDF/DOCX/TXT) or paste text → See “ingested” confirmation.
3. **Ask** → Type a question → See answer, key points, confidence, sources → Response saved to History.
4. **History** → Browse past questions and answers (per user when auth is used).

---

## 3. Navigation structure

```
┌─────────────────────────────────────────────────────────────┐
│                      Bottom navigation                       │
│  [  Ask  ]    [  Sources  ]    [  History  ]    [  Settings ] │
└─────────────────────────────────────────────────────────────┘

Default tab: Ask. Shown only when user is logged in.
```

- **Ask** — Main screen: input question, show answer + key points + sources; each response saved to History.
- **Sources** — List of ingested sources (by name) + “Add source” (upload or paste text).
- **History** — List of past Q&A; tap to expand or view full answer.
- **Settings** — Backend URL, connection check, account (email / logout), about.

---

## 4. Screen wireframes

---

### 4.1 Ask (home)

**Goal:** Enter a study question and see Tensai’s answer with key points and sources.

```
┌─────────────────────────────────────────────────────────────┐
│  Tensai                                    [Refresh/Status]  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  What is Newton's first law?                         │   │
│  │  ________________________________________________   │   │
│  │  Ask anything from your study materials             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  [                    Ask Tensai                     ]       │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  Answer (after response)                                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Newton's first law states that an object at rest    │   │
│  │  stays at rest and an object in motion stays in      │   │
│  │  motion at constant velocity unless acted on by      │   │
│  │  a net force...                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  Key points                                                  │
│  • Object at rest stays at rest                             │
│  • Object in motion stays in motion                         │
│  • Unless acted on by a net force                            │
│                                                              │
│  Confidence: 0.92   Sources: physics.pdf (chunk-0)           │
└─────────────────────────────────────────────────────────────┘
```

**Elements:**
- App bar: title “Tensai”, optional connection status or refresh.
- Text field: multi-line, placeholder “Ask anything from your study materials”, max length ~1000.
- Primary button: “Ask Tensai” (disabled until length ≥ 5).
- Loading: full-screen or inline spinner while waiting for `POST /ask`.
- Result section (shown after success):
  - **Answer** (expandable if long).
  - **Key points** (bullet list).
  - **Confidence** (e.g. 0.92 or 92%).
  - **Sources** (e.g. document id or “physics.pdf”).
- Error: snackbar or inline message on network/API error.

**API:** `POST /ask` with `{"question": "..."}` (and auth header if backend supports it). Display `answer`, `key_points`, `confidence`, `sources`. After success, save this Q&A to History (local DB or backend).

---

### 4.2 Sources

**Goal:** See what’s been ingested and add new sources (upload file or paste text).

```
┌─────────────────────────────────────────────────────────────┐
│  Sources                                                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Your study materials                                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  📄 physics.pdf                    Uploaded 2h ago   │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  📄 notes.docx                    Uploaded 1d ago   │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  📝 Pasted text                   Added 3d ago       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  +  Add source (upload or paste)                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Elements:**
- App bar: “Sources”.
- List of sources: each row shows icon (file vs paste), name, optional “added” time. Tapping can show a simple detail (e.g. “X chunks”) or do nothing in v1.
- FAB or card: “Add source (upload or paste)” → opens add-source flow.

**Add source flow (two options):**

**Option A — Upload file**
```
┌─────────────────────────────────────────────────────────────┐
│  ← Add source                                                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Upload a document                                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                      │   │
│  │     [  Choose file  ]   PDF, DOCX, or TXT           │   │
│  │                                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  [              Upload and ingest                    ]       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```
- File picker (PDF, DOCX, TXT). After pick: show filename, then “Upload and ingest” → `POST /ingest/upload` (multipart file). Show “Ingested N chunks” or error.

**Option B — Paste text**
```
┌─────────────────────────────────────────────────────────────┐
│  ← Add source                                                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Paste text (split by paragraphs)                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Newton's first law...                               │   │
│  │                                                      │   │
│  │  Newton's second law...                              │   │
│  │                                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  [              Ingest text                          ]       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```
- Multi-line text field → `POST /ingest/text` with `{"text": "..."}`. Show “Ingested N chunks” or error.

**Note:** Backend doesn’t return a “list of sources” yet. For the list you can either (a) keep only local state (e.g. “last 10 ingested filenames/timestamps” in shared prefs), or (b) add a future “list sources” API and use it here.

---

### 4.3 Auth (login / sign up)

**Goal:** Identify the user so History (and optionally sources) can be scoped per account. Shown when the app has no stored token.

**Login**
```
┌─────────────────────────────────────────────────────────────┐
│  Tensai — Sign in                                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Email                                                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  you@example.com                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│  Password                                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ••••••••                                            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  [              Sign in                              ]       │
│  Don't have an account?  Sign up                             │
└─────────────────────────────────────────────────────────────┘
```

**Sign up**
```
┌─────────────────────────────────────────────────────────────┐
│  Tensai — Create account                                     │
├─────────────────────────────────────────────────────────────┤
│  Email                                                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  you@example.com                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│  Password (min 8 chars)                                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ••••••••                                            │   │
│  └─────────────────────────────────────────────────────┘   │
│  Confirm password                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ••••••••                                            │   │
│  └─────────────────────────────────────────────────────┘   │
│  [              Sign up                              ]       │
│  Already have an account?  Sign in                            │
└─────────────────────────────────────────────────────────────┘
```

**Elements:**
- Login: email, password; “Sign in” → POST to backend auth (e.g. `/auth/login` or `/token`). Store token (e.g. secure storage), then show main app (bottom nav).
- Sign up: email, password, confirm password; “Sign up” → POST (e.g. `/auth/register`). Then auto sign-in or redirect to login.
- If backend has no auth yet: app can use a “guest” mode (no token) and keep History only locally until auth is added.

**Backend (to add later if needed):** Endpoints such as `POST /auth/register`, `POST /auth/login` (or OAuth2 `/token`), and optionally `GET /history`, `POST /history` for syncing. Until then, auth can be mocked or skipped and History kept local-only.

---

### 4.4 History

**Goal:** Browse past questions and answers. Stored locally per device (and optionally synced per user when backend supports it).

```
┌─────────────────────────────────────────────────────────────┐
│  History                                                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  What is Newton's first law?                         │   │
│  │  Newton's first law states that...                   │   │
│  │  92% · 2 sources · 10:30 AM                          │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Explain F = ma                                      │   │
│  │  Force equals mass times acceleration...             │   │
│  │  88% · 1 source · Yesterday                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  (Empty: "No history yet. Ask a question on the Ask tab.")   │
└─────────────────────────────────────────────────────────────┘
```

**Elements:**
- List of cards: question (title), answer (truncated), confidence + sources + time. Tap to expand or open a detail page with full Q&A.
- Data: after each successful `POST /ask`, save `question` + full response to local DB (e.g. SQLite / Hive) keyed by user id if auth is used. Optionally sync to backend via `GET /history` and `POST /history` when available.

---

### 4.5 Settings

**Goal:** Configure backend and app behavior.

```
┌─────────────────────────────────────────────────────────────┐
│  Settings                                                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Account                                                     │
│  you@example.com                        [  Log out  ]       │
│                                                              │
│  Backend                                                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Base URL    https://your-app.herokuapp.com          │   │
│  └─────────────────────────────────────────────────────┘   │
│  [  Check connection  ]   Status: ✓ OK / ✗ Failed           │
│                                                              │
│  About                                                       │
│  Tensai — AI Study Copilot · v1.0.0                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Elements:**
- Text field: backend base URL (default for dev: `http://10.0.2.2:8000` for Android emulator, `http://localhost:8000` for iOS simulator; for real device use your Heroku URL).
- “Check connection” → `GET /health`. Show “OK” with model name or “Failed” with message.
- Account: show logged-in email (if auth is used); **Log out** button (clear token, return to login screen).
- About: app name, version.

---

## 5. API integration summary

| Screen / action | Method | Endpoint | Request | Response |
|-----------------|--------|----------|---------|----------|
| Check connection | GET | `/health` | — | `status`, `service`, `model` |
| Ask question | POST | `/ask` | `{"question": "..."}` + optional `Authorization` | `question`, `answer`, `key_points`, `confidence`, `sources` |
| Upload document | POST | `/ingest/upload` | multipart `file` + optional `Authorization` | `status`, `ingested` |
| Paste text | POST | `/ingest/text` | `{"text": "..."}` + optional `Authorization` | `status`, `ingested` |
| Login (backend TBD) | POST | `/auth/login` or `/token` | email, password | token / user |
| Sign up (backend TBD) | POST | `/auth/register` | email, password | success / user |
| History (optional sync) | GET / POST | `/history` | — / `{question, answer, ...}` | list / saved |

Base URL: configurable in Settings. Auth header (e.g. `Bearer <token>`) sent on all requests when user is logged in, if backend supports it.

---

## 6. Wireframe summary

| Screen | Main elements |
|--------|----------------|
| **Ask** | Question input, “Ask Tensai” button, answer + key points + confidence + sources, loading & error states; save to History on success |
| **Sources** | List of sources (local or future API), “Add source” → Upload file or Paste text (two sub-screens) |
| **History** | List of past Q&A cards (local DB; optional backend sync); tap to expand/detail |
| **Auth** | Login (email + password) and Sign up (email + password + confirm); token stored; shown when not logged in |
| **Settings** | Base URL, “Check connection”, Account (email + Log out), About |

---

## 7. Backend additions (FastAPI) for Auth and History

To support the Flutter app’s auth and (optional) history sync, the Tensai backend needs the following. Implement these in the existing FastAPI app.

### 7.1 Auth

| What | Details |
|------|---------|
| **User storage** | Store users (e.g. SQLite, PostgreSQL, or Supabase). Minimal: `id`, `email`, `password_hash`, `created_at`. |
| **Password hashing** | Use `passlib` + `bcrypt` (or `argon2`). Never store plain passwords. |
| **POST /auth/register** | Body: `{"email": "...", "password": "..."}`. Validate email, check email not taken, hash password, create user, return `{"id", "email"}` or 201. |
| **POST /auth/login** | Body: `{"email": "...", "password": "..."}`. Verify password, issue JWT (e.g. `python-jose` or `PyJWT`). Return `{"access_token": "...", "token_type": "bearer"}`. |
| **Protected routes** | Dependency: read `Authorization: Bearer <token>`, verify JWT, attach current user. Apply to `/ask`, `/ingest/upload`, `/ingest/text` (optional: allow unauthenticated if no header). |

### 7.2 History (optional sync)

| What | Details |
|------|---------|
| **History storage** | Table: `user_id`, `question`, `answer`, `key_points` (JSON), `confidence`, `sources` (JSON), `created_at`. |
| **POST /history** | Body: same as AskResponse. Require auth; save with `user_id` from token. Return 201. |
| **GET /history** | Require auth. Return user’s history (newest first), optionally paginated. |

### 7.3 Implementation order

1. **Auth first** — User model, register, login, JWT, auth dependency on existing endpoints.
2. **History second** — History model, POST/GET endpoints; Flutter syncs after Ask and loads list on History tab.

**Alternative:** Keep backend auth-free for now; Flutter uses local-only auth (guest) and local-only history (SQLite) until you add these.

---

## 8. Out of scope (optional later)

- Theming (light/dark), onboarding slides, refresh token, password reset.

---

When you’re ready, say “implement” (or “implement backend auth first / implement Flutter app”) and we can generate the Flutter project structure and code for these screens and API calls.
