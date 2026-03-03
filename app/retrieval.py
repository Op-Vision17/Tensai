"""Tensai — Pinecone retrieval and embedding logic (OpenAI-compatible or Jina)."""

import asyncio
from typing import Any

import httpx
from openai import AsyncOpenAI
from pinecone import Pinecone, ServerlessSpec

from app.config import get_settings

_index: Any = None

JINA_EMBED_URL = "https://api.jina.ai/v1/embeddings"


def get_index():
    """Return the connected Pinecone index; create it if it does not exist. Cached per process."""
    global _index
    if _index is not None:
        return _index
    settings = get_settings()
    pc = Pinecone(api_key=settings.pinecone_api_key)
    index_name = settings.pinecone_index_name
    try:
        info = pc.describe_index(name=index_name)
        index_dim = info.get("dimension") if isinstance(info, dict) else getattr(info, "dimension", None)
        if index_dim is not None and index_dim != settings.embedding_dimension:
            raise ValueError(
                f"Pinecone index '{index_name}' has dimension {index_dim}, but "
                f"EMBEDDING_DIMENSION={settings.embedding_dimension}. "
                "Either create a new index with the correct dimension, or set "
                "EMBEDDING_DIMENSION to match the index (and use a matching embedding model)."
            )
    except ValueError:
        raise
    except Exception:
        pc.create_index(
            name=index_name,
            dimension=settings.embedding_dimension,
            metric="cosine",
            spec=ServerlessSpec(
                cloud=settings.pinecone_cloud,
                region=settings.pinecone_region,
            ),
        )
    _index = pc.Index(index_name)
    print(f"[tensai] Pinecone index ready: {index_name}")
    return _index


def _openai_client() -> AsyncOpenAI:
    """AsyncOpenAI client for embeddings (OpenAI or Together)."""
    settings = get_settings()
    base_url = (settings.openai_base_url or "").strip() or None
    return AsyncOpenAI(api_key=settings.openai_api_key, base_url=base_url)


def _use_jina() -> bool:
    return bool((get_settings().jina_api_key or "").strip())


async def _embed_via_jina(text: str) -> list[float]:
    """Embed one text with Jina API (free tier)."""
    settings = get_settings()
    async with httpx.AsyncClient() as client:
        r = await client.post(
            JINA_EMBED_URL,
            headers={
                "Authorization": f"Bearer {settings.jina_api_key.strip()}",
                "Content-Type": "application/json",
            },
            json={
                "model": settings.jina_embedding_model,
                "input": text,
            },
            timeout=30.0,
        )
        r.raise_for_status()
        data = r.json()
    return list(data["data"][0]["embedding"])


async def _embed_batch_via_jina(texts: list[str]) -> list[list[float]]:
    """Embed multiple texts with Jina API."""
    settings = get_settings()
    async with httpx.AsyncClient() as client:
        r = await client.post(
            JINA_EMBED_URL,
            headers={
                "Authorization": f"Bearer {settings.jina_api_key.strip()}",
                "Content-Type": "application/json",
            },
            json={
                "model": settings.jina_embedding_model,
                "input": texts,
            },
            timeout=60.0,
        )
        r.raise_for_status()
        data = r.json()
    # Preserve order by index if present
    items = sorted(data["data"], key=lambda x: x.get("index", 0))
    return [list(item["embedding"]) for item in items]


async def embed_query(text: str) -> list[float]:
    """Embed a single query string and return the embedding vector (Jina or OpenAI)."""
    if _use_jina():
        return await _embed_via_jina(text)
    settings = get_settings()
    client = _openai_client()
    response = await client.embeddings.create(
        model=settings.embedding_model,
        input=text,
    )
    return list(response.data[0].embedding)


async def retrieve_docs(query: str, top_k: int, namespace: str = "default") -> list[dict]:
    """Retrieve the top_k most similar documents for the query from Pinecone (optionally in a namespace)."""
    try:
        embedding = await embed_query(query)
        index = get_index()
        results = await asyncio.to_thread(
            index.query,
            vector=embedding,
            top_k=top_k,
            include_metadata=True,
            namespace=namespace,
        )
        if not results.matches:
            return []
        return [
            {
                "id": m.id,
                "score": m.score,
                "text": m.metadata.get("text", "") if m.metadata else "",
                "metadata": dict(m.metadata) if m.metadata else {},
            }
            for m in results.matches
        ]
    except Exception as e:
        raise RuntimeError(f"[tensai] Retrieval failed: {e}") from e


async def upsert_documents(documents: list[dict], namespace: str = "default") -> None:
    """Embed and upsert documents into the Pinecone index in batches of 100 (optionally in a namespace).

    Each document must have "id" (str), "text" (str), and optionally "metadata" (dict).
    The "text" is embedded and stored in vector metadata for retrieval.

    Example:
        await upsert_documents([
            {"id": "chunk-1", "text": "Newton's first law...", "metadata": {"source": "physics.pdf", "page": 1}},
            {"id": "chunk-2", "text": "Force equals mass times acceleration.", "metadata": {"source": "physics.pdf"}},
        ], namespace="user_abc-123")
    """
    if not documents:
        return
    settings = get_settings()
    texts = [d["text"] for d in documents]
    if _use_jina():
        embeddings_list = await _embed_batch_via_jina(texts)
    else:
        client = _openai_client()
        response = await client.embeddings.create(
            model=settings.embedding_model,
            input=texts,
        )
        embeddings_list = [list(response.data[i].embedding) for i in range(len(response.data))]
    embedding_by_i = {i: embeddings_list[i] for i in range(len(embeddings_list))}
    vectors = []
    for i, doc in enumerate(documents):
        meta = dict(doc.get("metadata") or {})
        meta["text"] = doc["text"]
        vectors.append({
            "id": doc["id"],
            "values": embedding_by_i[i],
            "metadata": meta,
        })
    index = get_index()
    batch_size = 100
    for n in range(0, len(vectors), batch_size):
        batch = vectors[n : n + batch_size]
        await asyncio.to_thread(index.upsert, vectors=batch, namespace=namespace)
        count = len(batch)
        print(f"[tensai] Upserted batch {n // batch_size + 1}: {count} vectors")
