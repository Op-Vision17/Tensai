"""Tensai — History router: save and list user history."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth_utils import get_current_user
from app.database import get_db
from app.models import History, User

router = APIRouter(prefix="/history", tags=["history"])


class CreateHistoryRequest(BaseModel):
    question: str = Field(..., min_length=1)
    answer: str = Field(...)
    key_points: list[str] = Field(default_factory=list)
    confidence: float = Field(..., ge=0.0, le=1.0)
    sources: list[str] = Field(default_factory=list)


class HistoryItem(BaseModel):
    id: uuid.UUID
    question: str
    answer: str
    key_points: list[str]
    confidence: float
    sources: list[str]

    model_config = {"from_attributes": True}


@router.post("/", response_model=HistoryItem)
async def create_history(
    body: CreateHistoryRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> HistoryItem:
    """Save a history entry for the current user (auth required)."""
    entry = History(
        user_id=current_user.id,
        question=body.question,
        answer=body.answer,
        key_points=body.key_points,
        confidence=body.confidence,
        sources=body.sources,
    )
    db.add(entry)
    await db.flush()
    await db.refresh(entry)
    return HistoryItem(
        id=entry.id,
        question=entry.question,
        answer=entry.answer,
        key_points=entry.key_points or [],
        confidence=entry.confidence,
        sources=entry.sources or [],
    )


@router.get("/", response_model=list[HistoryItem])
async def list_history(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
) -> list[HistoryItem]:
    """Return current user's history, newest first, with limit and offset."""
    result = await db.execute(
        select(History)
        .where(History.user_id == current_user.id)
        .order_by(History.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    rows = result.scalars().all()
    return [
        HistoryItem(
            id=r.id,
            question=r.question,
            answer=r.answer,
            key_points=r.key_points or [],
            confidence=r.confidence,
            sources=r.sources or [],
        )
        for r in rows
    ]


@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_history(
    id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    """Delete a history entry if it belongs to the current user."""
    result = await db.execute(
        select(History).where(History.id == id).where(History.user_id == current_user.id).limit(1)
    )
    entry = result.scalars().first()
    if entry is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="History entry not found or not owned by you.",
        )
    await db.delete(entry)
    await db.flush()
