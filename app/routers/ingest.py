"""Tensai — Ingest router: documents and text into the vector index."""

import uuid
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app import retrieval
from app.auth_utils import get_optional_user
from app.database import get_db
from app.document_loader import extract_text_from_file
from app.models import Source, User

router = APIRouter(tags=["ingest"])

ALLOWED_EXTENSIONS = {".txt", ".pdf", ".docx", ".doc"}


class IngestDocument(BaseModel):
    """One document to ingest (id, text, optional metadata)."""

    id: str = Field(..., min_length=1, description="Unique document or chunk id")
    text: str = Field(..., min_length=1, description="Text content to embed and store")
    metadata: dict = Field(default_factory=dict, description="Optional metadata (e.g. source, page)")


class IngestRequest(BaseModel):
    """Request body for /ingest."""

    documents: list[IngestDocument] = Field(
        ...,
        min_length=1,
        max_length=1000,
        description="List of documents to embed and store in the index",
    )


class IngestResponse(BaseModel):
    """Response after ingesting documents."""

    status: str = "ok"
    ingested: int = Field(..., description="Number of documents ingested")


class IngestTextRequest(BaseModel):
    """Simple text ingest: paste text, split by paragraphs and store."""

    text: str = Field(
        ...,
        min_length=1,
        description="Plain text to ingest. Split by paragraphs (double newline) into chunks.",
    )
    title: str | None = Field(default=None, description="Optional display title for this source.")


class SourceItem(BaseModel):
    """One source in the list response."""

    id: uuid.UUID
    title: str
    source_type: str
    filename: str | None
    chunk_count: int
    created_at: datetime


def _namespace(user: User | None) -> str:
    return f"user_{user.id}" if user is not None else "default"


@router.post(
    "/ingest",
    response_model=IngestResponse,
    summary="Ingest documents into the index",
)
async def ingest(
    request: IngestRequest,
    user: User | None = Depends(get_optional_user),
) -> IngestResponse:
    """Embed and store documents in Pinecone. Use these for /ask retrieval."""
    namespace = _namespace(user)
    try:
        docs = [
            {"id": d.id, "text": d.text, "metadata": d.metadata}
            for d in request.documents
        ]
        await retrieval.upsert_documents(docs, namespace=namespace)
        return IngestResponse(ingested=len(docs))
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"[tensai] Ingest failed: {e}",
        ) from e


@router.post(
    "/ingest/text",
    response_model=IngestResponse,
    summary="Ingest plain text (split by paragraphs)",
)
async def ingest_text(
    request: IngestTextRequest,
    user: User | None = Depends(get_optional_user),
    db: AsyncSession = Depends(get_db),
) -> IngestResponse:
    """Ingest simple text: split by paragraphs and embed each chunk. No IDs or metadata needed."""
    namespace = _namespace(user)
    chunks = [s.strip() for s in request.text.split("\n\n") if s.strip()]
    if not chunks:
        raise HTTPException(
            status_code=400,
            detail="No non-empty paragraphs found in text.",
        )
    title = request.title
    if not title:
        title = f"Pasted Text {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M')}"
    source_id = uuid.uuid4()
    docs = [
        {"id": f"chunk-{i}", "text": chunk, "metadata": {}}
        for i, chunk in enumerate(chunks)
    ]
    try:
        await retrieval.upsert_documents(
            docs,
            namespace=namespace,
            source_id=str(source_id),
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"[tensai] Ingest failed: {e}",
        ) from e
    source = Source(
        id=source_id,
        user_id=user.id if user else None,
        title=title,
        namespace=namespace,
        chunk_count=len(docs),
        source_type="text",
        filename=None,
    )
    db.add(source)
    await db.flush()
    return IngestResponse(ingested=len(docs))


@router.post(
    "/ingest/upload",
    response_model=IngestResponse,
    summary="Upload a document (PDF, DOCX, TXT) as source",
)
async def ingest_upload(
    file: UploadFile = File(..., description="Document to ingest (.txt, .pdf, .docx)"),
    title: str | None = Form(None, description="Optional display title for this source."),
    user: User | None = Depends(get_optional_user),
    db: AsyncSession = Depends(get_db),
) -> IngestResponse:
    """Upload a file; text is extracted, chunked by paragraphs, and stored as sources for /ask."""
    namespace = _namespace(user)
    suffix = Path(file.filename or "").suffix.lower()
    if suffix not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type. Use one of: {', '.join(ALLOWED_EXTENSIONS)}",
        )
    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="File is empty.")
    try:
        text = extract_text_from_file(content, file.filename or "upload")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e)) from e
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Could not extract text from file: {e}",
        ) from e
    chunks = [s.strip() for s in text.split("\n\n") if s.strip()]
    if not chunks:
        raise HTTPException(
            status_code=400,
            detail="No text content found in the document.",
        )
    source_name = file.filename or "upload"
    display_title = (title or "").strip() or source_name
    source_id = uuid.uuid4()
    docs = [
        {"id": f"{source_name}--{i}", "text": chunk, "metadata": {"source": source_name}}
        for i, chunk in enumerate(chunks)
    ]
    try:
        await retrieval.upsert_documents(
            docs,
            namespace=namespace,
            source_id=str(source_id),
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"[tensai] Ingest failed: {e}",
        ) from e
    source = Source(
        id=source_id,
        user_id=user.id if user else None,
        title=display_title,
        namespace=namespace,
        chunk_count=len(docs),
        source_type="upload",
        filename=file.filename,
    )
    db.add(source)
    await db.flush()
    return IngestResponse(ingested=len(docs))


@router.get(
    "/ingest/sources",
    response_model=list[SourceItem],
    summary="List sources for the current user or guest",
)
async def list_sources(
    user: User | None = Depends(get_optional_user),
    db: AsyncSession = Depends(get_db),
) -> list[SourceItem]:
    """If logged in: return user's sources. If guest: return sources where user_id is null. Ordered by created_at DESC."""
    q = select(Source).order_by(Source.created_at.desc())
    if user is not None:
        q = q.where(Source.user_id == user.id)
    else:
        q = q.where(Source.user_id.is_(None))
    result = await db.execute(q)
    sources = result.scalars().all()
    return [
        SourceItem(
            id=s.id,
            title=s.title,
            source_type=s.source_type,
            filename=s.filename,
            chunk_count=s.chunk_count,
            created_at=s.created_at,
        )
        for s in sources
    ]


@router.delete(
    "/ingest/sources/{source_id}",
    status_code=204,
    summary="Delete a source and its vectors",
)
async def delete_source(
    source_id: uuid.UUID,
    user: User | None = Depends(get_optional_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Verify source belongs to current user (or guest), delete vectors from Pinecone, then delete Source record."""
    result = await db.execute(select(Source).where(Source.id == source_id).limit(1))
    source = result.scalars().first()
    if source is None:
        raise HTTPException(status_code=404, detail="Source not found")
    if user is not None:
        if source.user_id != user.id:
            raise HTTPException(status_code=403, detail="Source does not belong to you")
    else:
        if source.user_id is not None:
            raise HTTPException(status_code=403, detail="Source does not belong to you")
    await retrieval.delete_vectors_by_source_id(str(source_id), source.namespace)
    await db.delete(source)
    await db.flush()
