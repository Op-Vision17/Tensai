"""Tensai — Extract text from uploaded documents (PDF, DOCX, TXT)."""

import io
from pathlib import Path


def extract_text_from_file(content: bytes, filename: str) -> str:
    """Extract plain text from uploaded file. Supports .txt, .pdf, .docx."""
    suffix = Path(filename).suffix.lower()
    if suffix == ".txt":
        return content.decode("utf-8", errors="replace")
    if suffix == ".pdf":
        from pypdf import PdfReader
        reader = PdfReader(io.BytesIO(content))
        return "\n\n".join(
            page.extract_text() or ""
            for page in reader.pages
        )
    if suffix in (".docx", ".doc"):
        from docx import Document
        doc = Document(io.BytesIO(content))
        return "\n\n".join(p.text for p in doc.paragraphs if p.text.strip())
    raise ValueError(f"Unsupported file type: {suffix}. Use .txt, .pdf, or .docx")
