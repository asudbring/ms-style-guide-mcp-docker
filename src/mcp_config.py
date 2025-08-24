import os
from typing import Optional

class Config:
    # Server configuration
    HOST: str = os.getenv("MCP_HOST", "0.0.0.0")
    PORT: int = int(os.getenv("MCP_PORT", "8000"))
    WORKERS: int = int(os.getenv("MCP_WORKERS", "4"))
    
    # Redis configuration
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://redis:6379")
    SESSION_TTL: int = int(os.getenv("SESSION_TTL", "3600"))
    
    # CORS origins
    ALLOWED_ORIGINS: list = os.getenv(
        "ALLOWED_ORIGINS",
        "https://localhost,https://vscode.dev,https://*.visualstudio.com"
    ).split(",")
    
    # Logging
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    
    # Azure deployment readiness
    AZURE_READY: bool = os.getenv("AZURE_READY", "false").lower() == "true"
    KEY_VAULT_URL: Optional[str] = os.getenv("KEY_VAULT_URL")