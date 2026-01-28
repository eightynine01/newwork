"""
Test configuration and fixtures.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

import app.db.database as db_module
from app.db.database import Base

# 모델 import - Base.metadata에 테이블 정의가 등록되도록 함
from app.models.session import Session as SessionModel, Message as MessageModel  # noqa: F401
from app.models.template import Template  # noqa: F401
from app.models.workspace import Workspace  # noqa: F401
from app.models.permission import Permission  # noqa: F401
from app.models.skill import Skill  # noqa: F401

# Test database URL (in-memory SQLite with shared cache for connection sharing)
SQLALCHEMY_TEST_DATABASE_URL = "sqlite:///file::memory:?cache=shared&uri=true"

# Create test engine (싱글 연결을 사용하여 메모리 DB 공유)
test_engine = create_engine(
    SQLALCHEMY_TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
)

TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


@pytest.fixture(scope="function")
def db():
    """
    Create a test database session.

    Creates fresh tables for each test and cleans up afterwards.
    Patches the app's database module to use test engine.
    """
    # 테이블 생성
    Base.metadata.create_all(bind=test_engine)

    # 앱의 데이터베이스 모듈 패치
    original_engine = db_module.engine
    original_session_local = db_module.SessionLocal

    db_module.engine = test_engine
    db_module.SessionLocal = TestingSessionLocal

    db_session = TestingSessionLocal()
    try:
        yield db_session
    finally:
        db_session.close()
        # 원래 값 복원
        db_module.engine = original_engine
        db_module.SessionLocal = original_session_local
        # 테이블 삭제
        Base.metadata.drop_all(bind=test_engine)


@pytest.fixture
def client(db):
    """
    Create a test client with database override.
    """
    # 모듈 레벨 패치가 적용된 상태에서 앱 import
    from app.main import app
    from app.db.database import get_db

    def override_get_db():
        try:
            yield db
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def mock_anthropic():
    """
    Mock Anthropic API for testing without actual API calls.

    Yields a mock client that can be configured for different test scenarios.
    """
    with patch("anthropic.AsyncAnthropic") as mock_class:
        mock_client = AsyncMock()
        mock_class.return_value = mock_client

        # Default response structure
        mock_response = MagicMock()
        mock_response.content = [MagicMock(text="Test response", type="text")]
        mock_response.usage = MagicMock(input_tokens=10, output_tokens=20)
        mock_response.stop_reason = "end_turn"

        mock_client.messages.create = AsyncMock(return_value=mock_response)
        yield mock_client


@pytest.fixture
def mock_openai():
    """
    Mock OpenAI API for testing without actual API calls.

    Yields a mock client that can be configured for different test scenarios.
    """
    with patch("openai.AsyncOpenAI") as mock_class:
        mock_client = AsyncMock()
        mock_class.return_value = mock_client

        # Default response structure
        mock_response = MagicMock()
        mock_choice = MagicMock()
        mock_choice.message.content = "Test response"
        mock_choice.finish_reason = "stop"
        mock_response.choices = [mock_choice]
        mock_response.usage = MagicMock(prompt_tokens=10, completion_tokens=20)

        mock_client.chat.completions.create = AsyncMock(return_value=mock_response)
        yield mock_client


@pytest.fixture
def test_session_data():
    """
    Provide test data for session creation.
    """
    return {
        "title": "Test Session",
        "provider": "anthropic",
        "model": "claude-sonnet-4-20250514",
    }


@pytest.fixture
async def created_session(client, test_session_data):
    """
    Create a session and return its data.
    """
    response = client.post("/api/v1/sessions", json=test_session_data)
    assert response.status_code == 201
    return response.json()
