"""Tensai — LangGraph state machine with retry logic."""

from typing import TypedDict

from langgraph.graph import END, START, StateGraph
from langgraph.graph.state import CompiledStateGraph

from app import evaluation, llm, retrieval
from app.config import get_settings


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


NO_ANSWER_MSG = "The uploaded study materials don't contain information related to your question."


async def retrieve_node(state: StudyState) -> dict:
    """Fetch documents from Pinecone for the current question."""
    top_k = state["top_k"]
    docs = await retrieval.retrieve_docs(state["question"], top_k)
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
    return {
        "answer": answer,
        "key_points": result.get("key_points", []),
        "sources": result.get("sources", []),
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
