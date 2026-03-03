"""Tensai — Answer evaluation and response formatting."""

import json

from openai import AsyncOpenAI

from app.config import get_settings

SYSTEM_PROMPT_EVALUATE = """You are a strict answer quality evaluator for Tensai.
Evaluate whether the answer fully addresses the student's question.
Return JSON with exactly these keys:
- confidence: float between 0.0 and 1.0
  (1.0 = complete, thorough answer; 0.0 = missing or wrong)
- complete: boolean, true only if confidence >= 0.7
- reasoning: one sentence explaining your score"""


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


async def evaluate_answer(
    question: str,
    answer: str,
    docs: list[dict],
) -> dict:
    """Evaluate answer quality and return confidence, complete flag, and reasoning."""
    settings = get_settings()
    client = _chat_client()
    user_content = (
        f"Question: {question}\nAnswer: {answer}\nSource docs available: {len(docs)}"
    )
    response = await client.chat.completions.create(
        model=settings.chat_model,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT_EVALUATE},
            {"role": "user", "content": user_content},
        ],
        response_format={"type": "json_object"},
    )
    raw_text = response.choices[0].message.content or ""
    try:
        out = json.loads(raw_text)
        if not isinstance(out, dict):
            raise ValueError("expected object")
        confidence = float(out.get("confidence", 0.0))
        confidence = max(0.0, min(1.0, confidence))
        complete = bool(out.get("complete", False))
        reasoning = str(out.get("reasoning", ""))
        out = {"confidence": confidence, "complete": complete, "reasoning": reasoning}
    except (json.JSONDecodeError, TypeError, ValueError):
        out = {"confidence": 0.0, "complete": False, "reasoning": "parse error"}
    confidence = out["confidence"]
    complete = out["complete"]
    print(f"[tensai] Evaluated: confidence={confidence:.2f} complete={complete}")
    return out


def format_final_response(state: dict) -> dict:
    """Build the clean API response from pipeline state."""
    return {
        "question": state["question"],
        "answer": state["answer"],
        "key_points": state.get("key_points", []),
        "confidence": round(state["confidence"], 3),
        "sources": state.get("sources", []),
    }
