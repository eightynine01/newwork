# 개발 가이드

이 문서는 OpenWork 프로젝트의 개발 환경 설정과 개발 워크플로우를 상세히 설명합니다.

## 목차

- [개발 환경 설정](#개발-환경-설정)
- [프로젝트 구조](#프로젝트-구조)
- [디버깅](#디버깅)
- [테스트 작성](#테스트-작성)
- [코드 스타일 가이드](#코드-스타일-가이드)
- [Git 워크플로우](#git-워크플로우)
- [유용한 명령어](#유용한-명령어)

## 개발 환경 설정

### 시스템 요구사항

- **OS**: macOS, Linux, Windows (WSL2)
- **Python**: 3.10 이상
- **Flutter**: 3.16.0 이상
- **Node.js**: 18 이상 (Tauri 앱용)
- **Git**: 2.x
- **Docker**: 20.10+ (선택사항)

### 백엔드 (openwork-python) 설정

#### 1. 저장소 클론 및 디렉토리 이동

```bash
git clone https://github.com/yourusername/openwork.git
cd openwork/openwork-python
```

#### 2. Python 가상환경 설정

```bash
# 가상환경 생성
python3 -m venv venv

# 가상환경 활성화
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate     # Windows
```

#### 3. 의존성 설치

```bash
# 프로덕션 의존성
pip install -r requirements.txt

# 개발 의존성 (권장)
pip install -r requirements-dev.txt

# 또는 한 번에
pip install -r requirements.txt -r requirements-dev.txt
```

`requirements-dev.txt`:
```
pytest>=7.4.4
pytest-cov>=4.1.0
pytest-asyncio>=0.23.3
black>=23.12.0
isort>=5.13.2
pylint>=3.0.3
mypy>=1.8.0
httpx>=0.26.0
```

#### 4. 환경 변수 설정

```bash
# .env 파일 생성
cat > .env << EOF
DEBUG=True
DATABASE_URL=sqlite:///./data/openwork.db
OPENCODE_URL=http://localhost:8080
SECRET_KEY=dev-secret-key-change-in-production
LOG_LEVEL=DEBUG
EOF
```

#### 5. 데이터베이스 초기화

```bash
# 데이터 디렉토리 생성
mkdir -p data

# Alembic 마이그레이션 실행
alembic upgrade head
```

#### 6. 개발 서버 실행

```bash
# Uvicorn으로 실행 (자동 리로드)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 또는 make 사용
make dev
```

API 문서 접근:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### 프론트엔드 (openwork-flutter) 설정

#### 1. Flutter SDK 설치

```bash
# macOS (Homebrew)
brew install --cask flutter

# Linux
snap install flutter --classic

# 설치 확인
flutter doctor
```

#### 2. 의존성 설치

```bash
cd openwork-flutter
flutter pub get
```

#### 3. 코드 생성 (필요시)

```bash
# freezed, json_serializable 등
flutter pub run build_runner build --delete-conflicting-outputs

# watch 모드 (자동 재생성)
flutter pub run build_runner watch
```

#### 4. 개발 서버 실행

```bash
# 데스크톱 (macOS)
flutter run -d macos

# 데스크톱 (Linux)
flutter run -d linux

# 데스크톱 (Windows)
flutter run -d windows

# Chrome (웹)
flutter run -d chrome

# 모바일 에뮬레이터
flutter run -d emulator-5554
```

### 레퍼런스 구현 (openwork-clone) 설정

#### 1. Tauri 사전 요구사항 설치

```bash
# macOS
brew install rust

# Ubuntu/Debian
sudo apt install libwebkit2gtk-4.0-dev \
    build-essential \
    curl \
    wget \
    file \
    libssl-dev \
    libgtk-3-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

#### 2. 의존성 설치 및 실행

```bash
cd openwork-clone
npm install

# 개발 서버 실행
npm run tauri dev
```

### VS Code 설정

`.vscode/settings.json`:

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/openwork-python/venv/bin/python",
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.formatting.provider": "black",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": true
  },
  "[python]": {
    "editor.rulers": [100]
  },
  "[dart]": {
    "editor.rulers": [80],
    "editor.formatOnSave": true
  },
  "dart.flutterSdkPath": "/path/to/flutter",
  "files.exclude": {
    "**/__pycache__": true,
    "**/*.pyc": true,
    "**/venv": true
  }
}
```

`.vscode/extensions.json`:

```json
{
  "recommendations": [
    "ms-python.python",
    "ms-python.vscode-pylance",
    "Dart-Code.flutter",
    "Dart-Code.dart-code",
    "tamasfe.even-better-toml",
    "eamodio.gitlens"
  ]
}
```

## 프로젝트 구조

### 백엔드 (openwork-python)

```
openwork-python/
├── app/
│   ├── __init__.py
│   ├── main.py              # 애플리케이션 진입점
│   ├── api/                 # API 레이어
│   │   ├── __init__.py
│   │   ├── endpoints/       # 엔드포인트 정의
│   │   │   ├── __init__.py
│   │   │   ├── sessions.py  # 세션 관련 API
│   │   │   ├── templates.py # 템플릿 관련 API
│   │   │   ├── skills.py    # 스킬 관련 API
│   │   │   └── workspaces.py
│   │   └── websocket.py     # WebSocket 핸들러
│   ├── core/                # 핵심 설정
│   │   ├── __init__.py
│   │   ├── config.py        # 환경 설정
│   │   └── security.py      # 보안 관련
│   ├── db/                  # 데이터베이스
│   │   ├── __init__.py
│   │   ├── database.py      # DB 연결 설정
│   │   └── migrations/      # Alembic 마이그레이션
│   ├── models/              # SQLAlchemy 모델
│   │   ├── __init__.py
│   │   ├── session.py
│   │   ├── template.py
│   │   └── workspace.py
│   ├── schemas/             # Pydantic 스키마
│   │   ├── __init__.py
│   │   ├── session.py       # 요청/응답 스키마
│   │   └── template.py
│   └── services/            # 비즈니스 로직
│       ├── __init__.py
│       ├── opencode_client.py
│       └── session_service.py
├── tests/                   # 테스트
│   ├── __init__.py
│   ├── conftest.py          # pytest fixtures
│   ├── test_api/
│   │   ├── test_sessions.py
│   │   └── test_templates.py
│   └── test_services/
│       └── test_session_service.py
├── data/                    # SQLite DB 저장소
├── alembic.ini              # Alembic 설정
├── requirements.txt
├── requirements-dev.txt
└── Makefile                 # 개발 명령어
```

### 프론트엔드 (openwork-flutter)

```
openwork-flutter/
├── lib/
│   ├── main.dart            # 애플리케이션 진입점
│   ├── core/                # 공통 유틸리티
│   │   ├── config/
│   │   │   └── app_config.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── colors.dart
│   │   └── utils/
│   │       ├── logger.dart
│   │       └── validators.dart
│   ├── features/            # 기능별 모듈
│   │   ├── session/
│   │   │   ├── models/
│   │   │   │   └── session.dart
│   │   │   ├── providers/
│   │   │   │   └── session_provider.dart
│   │   │   ├── widgets/
│   │   │   │   ├── message_bubble.dart
│   │   │   │   └── prompt_input.dart
│   │   │   └── session_page.dart
│   │   ├── template/
│   │   ├── workspace/
│   │   └── settings/
│   ├── providers/           # 전역 Riverpod 프로바이더
│   │   └── api_client_provider.dart
│   ├── models/              # 공통 데이터 모델
│   ├── services/            # API 클라이언트
│   │   ├── api_client.dart
│   │   └── websocket_service.dart
│   └── widgets/             # 공통 위젯
│       ├── loading_spinner.dart
│       └── error_widget.dart
├── test/                    # 테스트
│   ├── widget_test.dart
│   └── unit/
├── pubspec.yaml
└── analysis_options.yaml
```

## 디버깅

### 백엔드 디버깅

#### 1. VS Code 디버거 설정

`.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: FastAPI",
      "type": "python",
      "request": "launch",
      "module": "uvicorn",
      "args": [
        "app.main:app",
        "--reload",
        "--host",
        "0.0.0.0",
        "--port",
        "8000"
      ],
      "jinja": true,
      "cwd": "${workspaceFolder}/openwork-python",
      "env": {
        "DEBUG": "True"
      }
    }
  ]
}
```

#### 2. 로깅 활용

```python
# app/core/logging.py
import logging
import sys

def setup_logging(level=logging.DEBUG):
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler('logs/app.log')
        ]
    )

# 사용 예시
logger = logging.getLogger(__name__)
logger.debug(f"Session created: {session.id}")
logger.info(f"User message received: {message[:50]}...")
logger.error(f"OpenCode connection failed: {error}")
```

#### 3. pdb 디버거

```python
# 브레이크포인트 설정
import pdb; pdb.set_trace()

# 또는 Python 3.7+
breakpoint()
```

#### 4. HTTP 요청 디버깅

```bash
# httpx를 사용한 수동 테스트
python -m http.client localhost:8000

# 또는 httpie
http POST localhost:8000/api/v1/sessions workspace_id=test title="Debug Session"

# curl
curl -X POST http://localhost:8000/api/v1/sessions \
  -H "Content-Type: application/json" \
  -d '{"workspace_id":"test","title":"Debug Session"}'
```

### 프론트엔드 디버깅

#### 1. Flutter DevTools

```bash
# DevTools 실행
flutter pub global activate devtools
flutter pub global run devtools

# 앱 실행 시 디버그 모드
flutter run --debug
```

#### 2. 로깅

```dart
// lib/core/utils/logger.dart
import 'package:flutter/foundation.dart';

class Logger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  static void info(String message) {
    debugPrint('[INFO] $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[ERROR] $message');
    if (error != null) debugPrint('Error: $error');
    if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
  }
}

// 사용 예시
Logger.debug('Session provider initialized');
Logger.error('API call failed', error, stackTrace);
```

#### 3. Riverpod DevTools

```dart
// main.dart
void main() {
  runApp(
    ProviderScope(
      observers: [MyProviderObserver()],
      child: const MyApp(),
    ),
  );
}

class MyProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('Provider: ${provider.name ?? provider.runtimeType}');
    print('Previous: $previousValue');
    print('New: $newValue');
  }
}
```

## 테스트 작성

### 백엔드 테스트

#### 1. pytest 설정

`pytest.ini`:

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
asyncio_mode = auto
addopts =
    --cov=app
    --cov-report=html
    --cov-report=term-missing
    --strict-markers
```

#### 2. Fixtures

`tests/conftest.py`:

```python
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.db.database import Base, get_db

# 테스트용 인메모리 DB
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

@pytest.fixture
def test_db():
    engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    Base.metadata.create_all(bind=engine)

    def override_get_db():
        try:
            db = TestingSessionLocal()
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db

    yield TestingSessionLocal()

    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def client(test_db):
    return TestClient(app)
```

#### 3. 테스트 예시

`tests/test_api/test_sessions.py`:

```python
import pytest

def test_create_session(client):
    """세션 생성 테스트"""
    response = client.post(
        "/api/v1/sessions",
        json={
            "workspace_id": "workspace-123",
            "title": "Test Session",
            "model": "claude-3-opus-20240229"
        }
    )

    assert response.status_code == 201
    data = response.json()["data"]
    assert data["title"] == "Test Session"
    assert data["model"] == "claude-3-opus-20240229"

def test_get_sessions(client):
    """세션 목록 조회 테스트"""
    # Given: 세션 생성
    client.post(
        "/api/v1/sessions",
        json={"workspace_id": "workspace-123", "title": "Session 1"}
    )

    # When: 목록 조회
    response = client.get("/api/v1/sessions")

    # Then
    assert response.status_code == 200
    data = response.json()["data"]
    assert len(data["sessions"]) == 1

@pytest.mark.asyncio
async def test_session_service():
    """세션 서비스 단위 테스트"""
    from app.services.session_service import SessionService

    service = SessionService()
    session = await service.create_session(
        workspace_id="test",
        title="Test"
    )

    assert session.id is not None
    assert session.title == "Test"
```

#### 4. 테스트 실행

```bash
# 전체 테스트 실행
pytest

# 커버리지 포함
pytest --cov=app --cov-report=html

# 특정 파일만
pytest tests/test_api/test_sessions.py

# 특정 테스트만
pytest tests/test_api/test_sessions.py::test_create_session

# 마커로 필터링
pytest -m "not slow"

# 병렬 실행
pytest -n auto
```

### 프론트엔드 테스트

#### 1. Widget 테스트

`test/features/session/session_page_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:openwork/features/session/session_page.dart';

void main() {
  testWidgets('SessionPage displays title', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(
      const MaterialApp(
        home: SessionPage(sessionId: 'test-123'),
      ),
    );

    // Verify the title is displayed
    expect(find.text('test-123'), findsOneWidget);
  });

  testWidgets('Message input field exists', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SessionPage(sessionId: 'test-123'),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
  });
}
```

#### 2. Provider 테스트

`test/features/session/providers/session_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openwork/features/session/providers/session_provider.dart';

void main() {
  test('SessionProvider initial state is loading', () {
    final container = ProviderContainer();
    final provider = container.read(sessionProvider('test-123'));

    expect(provider, const AsyncValue<Session?>.loading());
  });

  test('SessionProvider sends message', () async {
    final container = ProviderContainer();
    final notifier = container.read(sessionProvider('test-123').notifier);

    await notifier.sendMessage('Hello');

    // Verify state updated
    final state = container.read(sessionProvider('test-123'));
    expect(state.value?.messages.last.content, 'Hello');
  });
}
```

#### 3. 테스트 실행

```bash
# 전체 테스트 실행
flutter test

# 커버리지 포함
flutter test --coverage

# 특정 파일만
flutter test test/features/session/session_page_test.dart

# watch 모드
flutter test --watch
```

## 코드 스타일 가이드

### Python

```bash
# 포맷팅
black app/ tests/

# Import 정렬
isort app/ tests/

# Lint
pylint app/ tests/

# 타입 체크
mypy app/
```

### Dart/Flutter

```bash
# 포맷팅
dart format lib/ test/

# 분석
flutter analyze

# 미사용 import 제거
dart fix --apply
```

## Git 워크플로우

자세한 내용은 [CONTRIBUTING.md](../CONTRIBUTING.md)를 참조하세요.

## 유용한 명령어

### Makefile 명령어 (백엔드)

`Makefile`:

```makefile
.PHONY: install dev test lint format clean

install:
	pip install -r requirements.txt -r requirements-dev.txt

dev:
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

test:
	pytest --cov=app tests/

lint:
	pylint app/ tests/
	mypy app/

format:
	black app/ tests/
	isort app/ tests/

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache .coverage htmlcov .mypy_cache
```

사용:

```bash
make install  # 의존성 설치
make dev      # 개발 서버 실행
make test     # 테스트 실행
make lint     # Lint 실행
make format   # 코드 포맷팅
make clean    # 캐시 삭제
```

## 추가 자료

- [FastAPI 공식 문서](https://fastapi.tiangolo.com/)
- [Flutter 공식 문서](https://docs.flutter.dev/)
- [Riverpod 문서](https://riverpod.dev/)
- [pytest 문서](https://docs.pytest.org/)
