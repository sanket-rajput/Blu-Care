import logging
from typing import Generator
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

from app.core.config import settings

logger = logging.getLogger(__name__)

Base = declarative_base()

_engine = None
_SessionLocal = None


def get_db_engine():
    global _engine
    if _engine is None and settings.supabase_db_url:
        try:
            logger.info("Initializing SQLAlchemy database connection pool for Supabase PostgreSQL...")
            _engine = create_engine(
                settings.supabase_db_url,
                pool_pre_ping=True,
                pool_size=10,
                max_overflow=20,
                pool_recycle=1800,
                connect_args={"connect_timeout": 10},
            )
        except Exception as e:
            logger.warning(f"Database connection initialization warning: {e}")
            _engine = None
    return _engine


def get_session_factory():
    global _SessionLocal
    engine = get_db_engine()
    if engine and _SessionLocal is None:
        _SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    return _SessionLocal


def init_db():
    """Attempts to create all tables defined in models.py."""
    engine = get_db_engine()
    if engine:
        try:
            Base.metadata.create_all(bind=engine)
            logger.info("SQLAlchemy database tables verified/created successfully.")
        except Exception as e:
            logger.warning(f"Database table migration notice (running in degraded fallback mode): {e}")


def get_db() -> Generator:
    """FastAPI dependency yielding database session."""
    session_factory = get_session_factory()
    if session_factory is None:
        yield None
        return
    db = session_factory()
    try:
        yield db
    finally:
        db.close()
