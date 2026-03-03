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

### Stack

`FastAPI` · `Supabase (Postgres)` · `Pinecone` · `LangGraph` · `Groq / OpenAI` · `Jina / OpenAI`
