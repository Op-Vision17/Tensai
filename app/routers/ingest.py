"""Tensai — Ingest router: documents and text into the vector index."""

from pathlib import Path

from fastapi import APIRouter, File, HTTPException, UploadFile
from pydantic import BaseModel, Field

from app import retrieval
from app.document_loader import extract_text_from_file

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


@router.post(
    "/ingest",
    response_model=IngestResponse,
    summary="Ingest documents into the index",
)
async def ingest(request: IngestRequest) -> IngestResponse:
    """Embed and store documents in Pinecone. Use these for /ask retrieval."""
    try:
        docs = [
            {"id": d.id, "text": d.text, "metadata": d.metadata}
            for d in request.documents
        ]
        await retrieval.upsert_documents(docs)
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
async def ingest_text(request: IngestTextRequest) -> IngestResponse:
    """Ingest simple text: split by paragraphs and embed each chunk. No IDs or metadata needed."""
    chunks = [s.strip() for s in request.text.split("\n\n") if s.strip()]
    if not chunks:
        raise HTTPException(
            status_code=400,
            detail="No non-empty paragraphs found in text.",
        )
    docs = [
        {"id": f"chunk-{i}", "text": chunk, "metadata": {}}
        for i, chunk in enumerate(chunks)
    ]
    try:
        await retrieval.upsert_documents(docs)
        return IngestResponse(ingested=len(docs))
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"[tensai] Ingest failed: {e}",
        ) from e


@router.post(
    "/ingest/upload",
    response_model=IngestResponse,
    summary="Upload a document (PDF, DOCX, TXT) as source",
)
async def ingest_upload(
    file: UploadFile = File(..., description="Document to ingest (.txt, .pdf, .docx)")
) -> IngestResponse:
    """Upload a file; text is extracted, chunked by paragraphs, and stored as sources for /ask."""
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
    docs = [
        {"id": f"{source_name}--{i}", "text": chunk, "metadata": {"source": source_name}}
        for i, chunk in enumerate(chunks)
    ]
    try:
        await retrieval.upsert_documents(docs)
        return IngestResponse(ingested=len(docs))
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"[tensai] Ingest failed: {e}",
        ) from e
