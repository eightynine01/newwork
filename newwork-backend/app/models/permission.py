from sqlalchemy import Column, String, DateTime
from datetime import datetime
from app.db.database import Base


class Permission(Base):
    """
    Permission model for OpenCode permission requests.

    Represents permission requests from OpenCode agents.
    """

    __tablename__ = "permissions"

    id = Column(String, primary_key=True, index=True)
    session_id = Column(String, nullable=False, index=True)
    tool_name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    status = Column(
        String, default="pending", nullable=False
    )  # pending, approved, denied
    response = Column(String, nullable=True)  # allow_once, allow_always, deny
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    def __repr__(self) -> str:
        return f"<Permission(id={self.id}, session_id='{self.session_id}', status='{self.status}')>"
