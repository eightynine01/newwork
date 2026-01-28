from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from typing import Generator
from app.services.config_service import settings

# Get database URL from settings (OS-specific data directory)
SQLALCHEMY_DATABASE_URL = settings.DATABASE_URL

# Create engine with SQLite
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},  # Needed for SQLite
)

# Create SessionLocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()

# Import all models to ensure they're registered with Base
# These imports are necessary for Base.metadata.create_all() to find and create tables
from app.models.session import Session as SessionModel
from app.models.template import Template
from app.models.skill import Skill
from app.models.workspace import Workspace
from app.models.permission import Permission

# Reference models to prevent import elimination
__all__ = ["SessionModel", "Template", "Skill", "Workspace", "Permission"]


def get_db() -> Generator[Session, None, None]:
    """
    Dependency for getting database sessions.

    Yields:
        Session: SQLAlchemy session

    Usage:
        @app.get("/items/")
        def read_items(db: Session = Depends(get_db)):
            items = db.query(Item).all()
            return items
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    """
    Initialize database by creating all tables.

    This should be called on application startup.
    """
    Base.metadata.create_all(bind=engine)
