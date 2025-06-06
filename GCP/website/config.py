import os
from dataclasses import dataclass

@dataclass
class DatabaseConfig:
    """Database configuration for the data tier"""
    host: str
    user: str
    password: str
    database: str
    port: int = 3306

@dataclass
class APIConfig:
    """API configuration for the application tier"""
    host: str = "0.0.0.0"
    port: int = 5000
    debug: bool = False

# Database configuration - In production, use environment variables
DATABASE_CONFIG = DatabaseConfig(
    host=os.getenv("DB_HOST", "104.198.208.198"),
    user=os.getenv("DB_USER", "root"),
    password=os.getenv("DB_PASSWORD", "M7rk|(`J&H1+*I>i"),
    database=os.getenv("DB_NAME", "eventsdb")
)

# API configuration
API_CONFIG = APIConfig(
    host=os.getenv("API_HOST", "0.0.0.0"),
    port=int(os.getenv("API_PORT", "5000")),
    debug=os.getenv("DEBUG", "False").lower() == "true"
)

# CORS settings
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",") 