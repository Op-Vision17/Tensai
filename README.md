# Tensai

Production-grade AI Study Copilot.

## Setup

```bash
poetry install
cp .env.example .env
```

Edit `.env` with your values (see **Fully working backend** below). Then:

```bash
poetry run alembic upgrade head   # create DB tables (SQLite or Postgres)
poetry run start                   # or: uvicorn app.main:app --reload
```

Open `http://localhost:8000/docs` to try the API.

---

## Fully working backend — checklist

Everything the backend needs is in `.env.example`. Copy it to `.env` and fill in:

| What | Required? | Where / Notes |
|------|-----------|----------------|
| **Chat** | One required | `GROQ_API_KEY` (free at [console.groq.com](https://console.groq.com/keys)) **or** `OPENAI_API_KEY`. Set `CHAT_MODEL` (e.g. `llama-3.3-70b-versatile` for Groq). |
| **Embeddings** | One required | `JINA_API_KEY` (free at [jina.ai](https://jina.ai)) **or** `OPENAI_API_KEY`. With Jina use `EMBEDDING_DIMENSION=1024` and create a Pinecone index with dimension 1024. |
| **Pinecone** | Yes | `PINECONE_API_KEY`, `PINECONE_INDEX_NAME`. Index dimension must match `EMBEDDING_DIMENSION`. |
| **Database** | Optional | Default `sqlite:///./tensai.db`. For production set `DATABASE_URL` (e.g. Heroku Postgres). |
| **JWT (auth)** | Yes for auth | `JWT_SECRET` — set a long random string in production; default is insecure. |
| **SMTP (OTP email)** | Yes for send-otp | `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM_EMAIL`. Gmail: use an [App Password](https://support.google.com/accounts/answer/185833). |

**Pending steps for you:**

1. Copy `.env.example` → `.env`.
2. Fill in **Chat**: `GROQ_API_KEY` (or OpenAI).
3. Fill in **Embeddings**: `JINA_API_KEY` (or OpenAI); if Jina, set `EMBEDDING_DIMENSION=1024`.
4. Fill in **Pinecone**: `PINECONE_API_KEY`; create an index named `PINECONE_INDEX_NAME` with dimension matching `EMBEDDING_DIMENSION`.
5. Set **JWT_SECRET** (at least 32 random characters for production).
6. For **OTP login**: set SMTP vars so `POST /auth/send-otp` can send email.
7. Run `poetry run alembic upgrade head` then `poetry run start`.

No code changes needed — once `.env` is complete, the backend is fully working (ask, ingest, auth, history).

## License

MIT
