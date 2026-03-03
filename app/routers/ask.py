"""Tensai — Ask router: study question → answer (with optional history save)."""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app import evaluation
from app.auth_utils import get_optional_user
from app.config import get_settings
from app.database import get_db
from app.graph import StudyState, tensai_graph
from app.models import History, User

router = APIRouter(tags=["ask"])


class AskRequest(BaseModel):
    """Request body for /ask."""

    question: str = Field(
        ...,
        min_length=5,
        max_length=1000,
        description="The study question to answer",
    )


class AskResponse(BaseModel):
    """Response body for /ask."""

    question: str
    answer: str
    key_points: list[str]
    confidence: float
    sources: list[str]


@router.post(
    "/ask",
    response_model=AskResponse,
    summary="Ask Tensai a study question",
)
async def ask(
    request: AskRequest,
    db: AsyncSession = Depends(get_db),
    user: User | None = Depends(get_optional_user),
) -> AskResponse:
    """Run the Tensai graph and return the formatted answer. If authenticated, save to history."""
    settings = get_settings()
    initial_state: StudyState = {
        "question": request.question,
        "docs": [],
        "answer": "",
        "key_points": [],
        "sources": [],
        "confidence": 0.0,
        "complete": False,
        "retries": 0,
        "top_k": settings.default_top_k,
    }
    try:
        result = await tensai_graph.ainvoke(initial_state)
        formatted = evaluation.format_final_response(result)
        if user is not None:
            entry = History(
                user_id=user.id,
                question=request.question,
                answer=formatted["answer"],
                key_points=formatted["key_points"],
                confidence=formatted["confidence"],
                sources=formatted["sources"],
            )
            db.add(entry)
            await db.flush()
        return AskResponse(**formatted)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"[tensai] Error: {e}",
        ) from e
