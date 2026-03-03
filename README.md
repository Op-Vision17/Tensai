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

### Stack

`FastAPI` · `Supabase (Postgres)` · `Pinecone` · `LangGraph` · `Groq / OpenAI` · `Jina / OpenAI`
