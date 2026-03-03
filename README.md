# Tensai

> **AI study copilot** — Ingest your materials, ask in plain language, get answers with sources.

<br>

### ✦ Ask

Natural-language questions over your content. Answers come with key points and sources.

### ✦ Ingest

Paste text or upload PDFs, DOCX, TXT. Content is chunked and indexed for retrieval.

### ✦ Auth

Email OTP sign-in, JWT + refresh tokens, optional per-user history.

---

### Run it

```bash
poetry install
cp .env.example .env
poetry run alembic upgrade head
poetry run start
```

→ **http://localhost:8000/docs**

---

### Env (`.env`)

Copy `.env.example` to `.env` and set values. Summary:

| Section | Key(s) | Notes |
|--------|--------|--------|
| **Chat** | `GROQ_API_KEY` or `OPENAI_API_KEY` | One required. Set `CHAT_MODEL` (e.g. `llama-3.3-70b-versatile` for Groq). |
| **Embeddings** | `JINA_API_KEY` or `OPENAI_API_KEY` | One required. With Jina use `EMBEDDING_DIMENSION=1024`. |
| **Pinecone** | `PINECONE_API_KEY`, `PINECONE_INDEX_NAME` | Index dimension must match `EMBEDDING_DIMENSION`. |
| **Database** | `DATABASE_URL` | Supabase Postgres connection string. |
| **JWT** | `JWT_SECRET` | Use a long random value in production. |
| **SMTP** | `SMTP_HOST`, `SMTP_USER`, `SMTP_PASSWORD`, … | Required for OTP email. Gmail: use App Password. |

---

### Deploy to Heroku

We use **Supabase** for PostgreSQL (not Heroku Postgres). Set `DATABASE_URL` to your Supabase connection string in Heroku config.

1. **Install Heroku CLI** and log in: `heroku login`.

2. **Create app** (from the project root):
   ```bash
   heroku create your-app-name
   ```

3. **Set config vars** (required). Get **DATABASE_URL** from Supabase: Project Settings → Database → Connection string (URI, e.g. `postgresql://postgres.[ref]:[password]@...supabase.com:6543/postgres`).
   ```bash
   heroku config:set DATABASE_URL="postgresql://postgres.xxx:password@aws-0-region.pooler.supabase.com:6543/postgres"
   heroku config:set PINECONE_API_KEY=your_key
   heroku config:set PINECONE_INDEX_NAME=tensai-index
   heroku config:set JWT_SECRET=your-long-random-secret
   heroku config:set GROQ_API_KEY=your_groq_key
   heroku config:set JINA_API_KEY=your_jina_key
   ```
   Or use `OPENAI_API_KEY` instead of Groq/Jina if you prefer. For OTP email, set `SMTP_HOST`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM_EMAIL`, etc.

4. **Deploy**:
   ```bash
   git init
   git add .
   git commit -m "Deploy to Heroku"
   heroku git:remote -a your-app-name
   git push heroku main
   ```
   Use `git push heroku master` if your default branch is `master`. The **release phase** runs `alembic upgrade head` before each deploy; the **web** process runs `uvicorn` on `$PORT`.

5. **Re-export requirements** after adding dependencies:
   ```bash
   poetry export -f requirements.txt --without-hashes --without dev -o requirements.txt
   ```

---

### Stack

`FastAPI` · `Supabase (Postgres)` · `Pinecone` · `LangGraph` · `Groq / OpenAI` · `Jina / OpenAI`
