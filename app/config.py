"""Tensai — Centralized configuration via pydantic-settings."""

from functools import lru_cache

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Tensai application settings loaded from environment and .env."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Chat: Groq (free tier) or OpenAI
    groq_api_key: str = ""  # If set, use Groq for chat (llm + evaluation); get key at console.groq.com.
    groq_base_url: str = "https://api.groq.com/openai/v1"  # Groq OpenAI-compatible endpoint.
    chat_model: str = "gpt-4o"  # Chat model (e.g. llama-3.3-70b-versatile for Groq, gpt-4o for OpenAI).

    # Embeddings — one of: Jina (free), or OpenAI/Together (openai_*)
    jina_api_key: str = ""  # If set, use Jina for embeddings (free tier at jina.ai).
    jina_embedding_model: str = "jina-embeddings-v3"  # 1024 dim; or jina-embeddings-v3-small (512).
    openai_api_key: str = ""  # When Jina not set: OpenAI or Together API key for embeddings.
    openai_base_url: str = ""  # If set (e.g. https://api.together.xyz/v1), use for embeddings; else OpenAI.
    embedding_model: str = "text-embedding-3-small"  # Used only when not using Jina.
    embedding_dimension: int = 1536  # Must match Pinecone index (1024 for jina-embeddings-v3).

    # Pinecone
    pinecone_api_key: str  # Required for vector index access; no default for security.
    pinecone_index_name: str = "tensai-index"  # Name of the vector index for study content.
    pinecone_cloud: str = "aws"  # Cloud provider hosting the index (e.g. aws, gcp).
    pinecone_region: str = "us-east-1"  # Region of the index for latency and compliance.

    # Database (auth + history) — Supabase PostgreSQL only
    database_url: str = ""  # DATABASE_URL from env (Supabase: postgres:// or postgresql://)

    @property
    def async_database_url(self) -> str:
        """PostgreSQL URL in asyncpg format for Alembic and app (postgresql+asyncpg://)."""
        url = self.database_url.strip()
        if not url:
            raise ValueError("DATABASE_URL is required (Supabase PostgreSQL connection string)")
        if url.startswith("postgres://"):
            url = "postgresql://" + url[10:]
        if not url.startswith("postgresql://"):
            raise ValueError("DATABASE_URL must be a PostgreSQL URL (postgres:// or postgresql://)")
        if "+asyncpg" not in url:
            url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
        return url

    # JWT (auth)
    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24 * 7  # 7 days (access token)
    jwt_refresh_expire_days: int = 30  # refresh token

    # SMTP (OTP email)
    smtp_host: str = "smtp.gmail.com"
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from_email: str = "noreply@tensai.local"
    otp_expire_minutes: int = 10
    # Timezone for OTP expiry in emails (e.g. Asia/Kolkata for India)
    email_timezone: str = "Asia/Kolkata"

    # Tensai graph tuning
    default_top_k: int = 5  # Default number of retrieved chunks per query in the RAG pipeline.
    max_top_k: int = 15  # Upper bound for top_k to avoid overload and control cost.
    confidence_threshold: float = 0.7  # Minimum score to treat a retrieval or decision as confident.
    max_retries: int = 2  # Retries for transient failures (e.g. LLM or Pinecone calls).

    @model_validator(mode="after")
    def require_provider_keys(self) -> "Settings":
        if not (self.jina_api_key or self.openai_api_key):
            raise ValueError(
                "Embeddings: set JINA_API_KEY (free at jina.ai) or OPENAI_API_KEY in .env"
            )
        if not (self.groq_api_key or self.openai_api_key):
            raise ValueError(
                "Chat: set GROQ_API_KEY (free at console.groq.com/keys) or OPENAI_API_KEY in .env"
            )
        return self


@lru_cache
def get_settings() -> Settings:
    """Return cached Settings instance (singleton). Loads once from env and .env."""
    return Settings()
