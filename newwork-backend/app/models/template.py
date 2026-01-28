from sqlalchemy import Column, String, DateTime, JSON
from datetime import datetime
from app.db.database import Base


class Template(Base):
    """
    Template model for OpenCode prompt templates.

    Represents reusable prompt templates.
    """

    __tablename__ = "templates"

    id = Column(String, primary_key=True, index=True)
    title = Column(String, nullable=False, index=True)  # Changed from 'name' to 'title'
    description = Column(String, nullable=True)
    prompt = Column(String, nullable=False)  # Changed from 'content' to 'prompt'
    scope = Column(
        String, nullable=False, default="workspace"
    )  # 'workspace' or 'global'
    skills = Column(JSON, nullable=True)  # List of skill names
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    workspace_id = Column(String, nullable=True, index=True)  # Foreign key to workspace

    def __repr__(self) -> str:
        return f"<Template(id={self.id}, title='{self.title}', scope='{self.scope}')>"
