"""Tensai — LLM answer generation and query expansion."""

import json

from openai import AsyncOpenAI

from app.config import get_settings

SYSTEM_PROMPT_ANSWER = """You are Tensai, an expert AI study assistant. Answer the student's question using ONLY the provided context documents. Be thorough, precise, and educational. Return a JSON object with these exact keys:
- answer: comprehensive string answer
- key_points: list of 3-5 concise bullet strings
- sources: list of document ids you used"""

SYSTEM_PROMPT_EXPAND = """You are a search query optimizer for Tensai. Given a student's question and an incomplete answer, rewrite the question to retrieve more relevant study material. Return ONLY the rewritten question. No explanation."""


def _chat_client() -> AsyncOpenAI:
    """Chat client: Groq if GROQ_API_KEY set, else OpenAI (or openai_base_url)."""
    settings = get_settings()
    if (settings.groq_api_key or "").strip():
        return AsyncOpenAI(
            api_key=settings.groq_api_key.strip(),
            base_url=settings.groq_base_url.strip() or None,
        )
    base_url = (settings.openai_base_url or "").strip() or None
    return AsyncOpenAI(api_key=settings.openai_api_key, base_url=base_url)


async def generate_answer(question: str, docs: list[dict]) -> dict:
    """Generate a structured answer from the LLM using the provided context documents."""
    settings = get_settings()
    client = _chat_client()
    context_lines = [
        f"[{i + 1}] ID={doc['id']} Score={doc.get('score') or 0:.2f}\n{doc.get('text', '')}\n"
        for i, doc in enumerate(docs)
    ]
    user_content = f"Question: {question}\n\nContext Documents:\n" + "".join(context_lines)
    response = await client.chat.completions.create(
        model=settings.chat_model,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT_ANSWER},
            {"role": "user", "content": user_content},
        ],
        response_format={"type": "json_object"},
    )
    raw_text = response.choices[0].message.content or ""
    try:
        out = json.loads(raw_text)
        if not isinstance(out, dict):
            raise ValueError("expected object")
        out.setdefault("answer", raw_text)
        out.setdefault("key_points", [])
        out.setdefault("sources", [])
    except (json.JSONDecodeError, TypeError, ValueError):
        out = {"answer": raw_text, "key_points": [], "sources": []}
    answer = out["answer"]
    print(f"[tensai] Answer generated, length={len(answer)}")
    return out


async def expand_query(original_question: str, answer: str) -> str:
    """Rewrite the question to retrieve more relevant material given the current answer."""
    settings = get_settings()
    client = _chat_client()
    user_content = f"Original question: {original_question}\n\nCurrent answer (possibly incomplete):\n{answer}"
    response = await client.chat.completions.create(
        model=settings.chat_model,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT_EXPAND},
            {"role": "user", "content": user_content},
        ],
    )
    new_query = (response.choices[0].message.content or "").strip()
    print(f"[tensai] Query expanded: {new_query[:80]}")
    return new_query
