from sqlalchemy import Column, String, DateTime, JSON, Integer, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base


class Session(Base):
    """
    Session model for AI conversation sessions.

    Represents a working session with an AI provider.
    Stores configuration and metadata for the session.
    """

    __tablename__ = "sessions"

    id = Column(String, primary_key=True, index=True)
    title = Column(String, nullable=False)
    path = Column(String, nullable=True)  # Workspace path
    provider = Column(String, nullable=False, default="anthropic")  # AI provider
    model = Column(String, nullable=False, default="claude-sonnet-4-20250514")  # Model ID
    system_prompt = Column(Text, nullable=True)  # Custom system prompt
    messages = Column(JSON, nullable=False, default=list)  # List of message objects
    todos = Column(JSON, nullable=False, default=list)  # List of todo objects
    session_metadata = Column(JSON, nullable=True, default=dict)  # Additional metadata
    total_input_tokens = Column(Integer, nullable=False, default=0)
    total_output_tokens = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )
    workspace_id = Column(String, nullable=True, index=True)  # Foreign key to workspace

    # Relationship to messages
    session_messages = relationship("Message", back_populates="session", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<Session(id={self.id}, title='{self.title}', provider='{self.provider}', model='{self.model}')>"


class Message(Base):
    """
    Message model for conversation history.

    Stores individual messages with tool use and result information.
    """

    __tablename__ = "messages"

    id = Column(String, primary_key=True, index=True)
    session_id = Column(String, ForeignKey("sessions.id"), nullable=False, index=True)
    role = Column(String, nullable=False)  # user, assistant, system, tool
    content = Column(Text, nullable=True)  # Text content
    tool_use = Column(JSON, nullable=True)  # Tool call information
    tool_result = Column(JSON, nullable=True)  # Tool result
    tokens_used = Column(Integer, nullable=True)  # Tokens for this message
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationship to session
    session = relationship("Session", back_populates="session_messages")

    def __repr__(self) -> str:
        return f"<Message(id={self.id}, session_id='{self.session_id}', role='{self.role}')>"
