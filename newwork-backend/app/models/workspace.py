from sqlalchemy import Column, String, DateTime, Boolean, Integer
from datetime import datetime
from app.db.database import Base


class Workspace(Base):
    """
    Workspace model for OpenCode workspaces.

    Represents a workspace/project directory.
    """

    __tablename__ = "workspaces"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    path = Column(String, nullable=False, unique=True)
    description = Column(String, nullable=True)
    is_active = Column(
        Integer, default=0, nullable=False
    )  # SQLite uses INTEGER for boolean
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    def __repr__(self) -> str:
        return f"<Workspace(id={self.id}, name='{self.name}', path='{self.path}')>"
