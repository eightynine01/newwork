from sqlalchemy import Column, String, DateTime
from datetime import datetime
from app.db.database import Base


class Skill(Base):
    """
    Skill model for OpenCode specialized agents.

    Represents specialized skills/agents available in OpenCode.
    """

    __tablename__ = "skills"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    description = Column(String, nullable=True)
    config = Column(String, nullable=True)  # JSON string for skill configuration
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    def __repr__(self) -> str:
        return f"<Skill(id={self.id}, name='{self.name}')>"
