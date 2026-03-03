"""Tensai — LangGraph state machine with retry logic."""

import uuid
from typing import NotRequired, TypedDict

from langgraph.graph import END, START, StateGraph
from langgraph.graph.state import CompiledStateGraph
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app import evaluation, llm, retrieval
from app.config import get_settings
from app.models import Source


class StudyState(TypedDict):
    question: str
    docs: list
    answer: str
    key_points: list
    sources: list
    confidence: float
    complete: bool
    retries: int
    top_k: int
    namespace: str
    db: NotRequired[AsyncSession]


NO_ANSWER_MSG = "The uploaded study materials don't contain information related to your question."


async def retrieve_node(state: StudyState) -> dict:
    """Fetch documents from Pinecone for the current question."""
    top_k = state["top_k"]
    namespace = state.get("namespace") or "default"
    docs = await retrieval.retrieve_docs(state["question"], top_k, namespace=namespace)
    filtered = [d for d in docs if (d.get("score") or 0) >= 0.5]
    n = len(filtered)
    print(f"[tensai:retrieve] top_k={top_k} → {len(docs)} docs, {n} with score >= 0.5")
    if n == 0:
        return {
            "docs": [],
            "answer": NO_ANSWER_MSG,
            "key_points": [],
            "sources": [],
            "confidence": 0.0,
            "complete": True,
        }
    return {"docs": filtered}


async def generate_node(state: StudyState) -> dict:
    """Generate answer and key points from the LLM using retrieved docs."""
    result = await llm.generate_answer(state["question"], state["docs"])
    answer = result["answer"]
    if (answer or "").strip().upper() == "NOT_IN_CONTEXT":
        return {
            "answer": NO_ANSWER_MSG,
            "key_points": [],
            "sources": [],
            "confidence": 0.0,
            "complete": True,
        }
    print(f"[tensai:generate] answer={len(answer)} chars")
    # Build unique source titles from retrieved docs (so response shows titles, not chunk ids)
    seen_titles: set[str] = set()
    source_titles: list[str] = []
    db: AsyncSession | None = state.get("db")
    source_id_cache: dict[str, str] = {}
    for doc in state["docs"]:
        meta = doc.get("metadata") or {}
        title = meta.get("source_title") or meta.get("source")
        if not title and meta.get("source_id") and db is not None:
            sid = meta["source_id"]
            if sid in source_id_cache:
                title = source_id_cache[sid]
            else:
                try:
                    source_uuid = uuid.UUID(sid)
                    r = await db.execute(select(Source.title).where(Source.id == source_uuid).limit(1))
                    row = r.scalars().first()
                    if row is not None:
                        title = row
                        source_id_cache[sid] = title
                except (ValueError, TypeError):
                    pass
        if not title:
            title = doc.get("id") or ""
        if title and title not in seen_titles:
            seen_titles.add(title)
            source_titles.append(title)
    return {
        "answer": answer,
        "key_points": result.get("key_points", []),
        "sources": source_titles,
    }


async def evaluate_node(state: StudyState) -> dict:
    """Evaluate answer quality and set confidence and complete."""
    result = await evaluation.evaluate_answer(
        state["question"],
        state["answer"],
        state["docs"],
    )
    confidence = result["confidence"]
    complete = result["complete"]
    print(f"[tensai:evaluate] confidence={confidence} complete={complete}")
    return {"confidence": confidence, "complete": complete}


async def expand_node(state: StudyState) -> dict:
    """Rewrite the question and bump top_k for a retry."""
    settings = get_settings()
    new_question = await llm.expand_query(state["question"], state["answer"])
    new_top_k = min(state["top_k"] + 3, settings.max_top_k)
    retries = state["retries"] + 1
    print(f"[tensai:expand] retry={retries} new_q={new_question[:70]}")
    return {
        "question": new_question,
        "top_k": new_top_k,
        "retries": retries,
    }


def after_retrieve(state: StudyState) -> str:
    """If already complete (no docs above threshold), skip to end; else generate."""
    if state.get("complete"):
        return "end"
    return "generate"


def should_retry(state: StudyState) -> str:
    """Route to end or expand based on completeness and retry count."""
    if state["complete"]:
        return "end"
    if state["retries"] >= get_settings().max_retries:
        return "end"
    return "expand"


def build_graph() -> CompiledStateGraph:
    """Build and compile the Tensai study copilot graph."""
    graph = StateGraph(StudyState)
    graph.add_node("retrieve_node", retrieve_node)
    graph.add_node("generate_node", generate_node)
    graph.add_node("evaluate_node", evaluate_node)
    graph.add_node("expand_node", expand_node)
    graph.add_edge(START, "retrieve_node")
    graph.add_conditional_edges(
        "retrieve_node",
        after_retrieve,
        {"end": END, "generate": "generate_node"},
    )
    graph.add_edge("generate_node", "evaluate_node")
    graph.add_conditional_edges(
        "evaluate_node",
        should_retry,
        {"end": END, "expand": "expand_node"},
    )
    graph.add_edge("expand_node", "retrieve_node")
    return graph.compile()


tensai_graph = build_graph()
