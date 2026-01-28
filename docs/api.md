# API 레퍼런스

OpenWork 백엔드는 RESTful API와 WebSocket API를 제공합니다. 이 문서는 모든 엔드포인트의 상세 사양을 설명합니다.

## 목차

- [기본 정보](#기본-정보)
- [인증](#인증)
- [세션 API](#세션-api)
- [템플릿 API](#템플릿-api)
- [워크스페이스 API](#워크스페이스-api)
- [스킬 API](#스킬-api)
- [WebSocket API](#websocket-api)
- [에러 코드](#에러-코드)

## 기본 정보

### Base URL

```
http://localhost:8000/api/v1
```

### 헤더

```
Content-Type: application/json
Accept: application/json
```

### 응답 형식

모든 API는 JSON 형식으로 응답합니다.

**성공 응답**:
```json
{
  "data": { ... },
  "meta": {
    "timestamp": "2026-01-25T12:00:00Z"
  }
}
```

**에러 응답**:
```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "세션을 찾을 수 없습니다",
    "details": {}
  }
}
```

## 인증

현재 버전(v0.1.0)에서는 인증이 구현되어 있지 않습니다. 향후 버전에서 JWT 기반 인증을 추가할 예정입니다.

## 세션 API

### 세션 목록 조회

모든 세션 목록을 조회합니다.

**요청**:
```http
GET /api/v1/sessions
```

**쿼리 파라미터**:
- `workspace_id` (optional): 워크스페이스별 필터링
- `status` (optional): 상태별 필터링 (`active`, `archived`)
- `limit` (optional): 최대 결과 수 (기본값: 50)
- `offset` (optional): 페이지네이션 오프셋

**응답 예시**:
```json
{
  "data": {
    "sessions": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "workspace_id": "workspace-123",
        "title": "새 프로젝트 세션",
        "model": "claude-3-opus-20240229",
        "status": "active",
        "created_at": "2026-01-25T10:30:00Z",
        "updated_at": "2026-01-25T12:00:00Z",
        "metadata": {
          "message_count": 15,
          "file_count": 3
        }
      }
    ],
    "total": 1
  }
}
```

**cURL 예시**:
```bash
curl -X GET "http://localhost:8000/api/v1/sessions?limit=10"
```

**Python 예시**:
```python
import requests

response = requests.get(
    "http://localhost:8000/api/v1/sessions",
    params={"workspace_id": "workspace-123", "limit": 10}
)
sessions = response.json()["data"]["sessions"]
```

### 세션 생성

새 세션을 생성합니다.

**요청**:
```http
POST /api/v1/sessions
Content-Type: application/json
```

**요청 본문**:
```json
{
  "workspace_id": "workspace-123",
  "title": "버그 수정 세션",
  "model": "claude-3-opus-20240229"
}
```

**필드 설명**:
- `workspace_id` (required): 워크스페이스 ID
- `title` (required): 세션 제목
- `model` (optional): Claude 모델 (기본값: `claude-3-opus-20240229`)

**응답 예시**:
```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "workspace_id": "workspace-123",
    "title": "버그 수정 세션",
    "model": "claude-3-opus-20240229",
    "status": "active",
    "created_at": "2026-01-25T12:30:00Z",
    "updated_at": "2026-01-25T12:30:00Z",
    "metadata": {}
  }
}
```

**cURL 예시**:
```bash
curl -X POST "http://localhost:8000/api/v1/sessions" \
  -H "Content-Type: application/json" \
  -d '{
    "workspace_id": "workspace-123",
    "title": "버그 수정 세션",
    "model": "claude-3-opus-20240229"
  }'
```

**Python 예시**:
```python
import requests

response = requests.post(
    "http://localhost:8000/api/v1/sessions",
    json={
        "workspace_id": "workspace-123",
        "title": "버그 수정 세션",
        "model": "claude-3-opus-20240229"
    }
)
session = response.json()["data"]
print(f"세션 생성됨: {session['id']}")
```

### 세션 조회

특정 세션의 상세 정보를 조회합니다.

**요청**:
```http
GET /api/v1/sessions/{session_id}
```

**경로 파라미터**:
- `session_id`: 세션 ID

**응답 예시**:
```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "workspace_id": "workspace-123",
    "title": "새 프로젝트 세션",
    "model": "claude-3-opus-20240229",
    "status": "active",
    "created_at": "2026-01-25T10:30:00Z",
    "updated_at": "2026-01-25T12:00:00Z",
    "metadata": {
      "message_count": 15,
      "file_count": 3
    },
    "messages": [
      {
        "id": "msg-001",
        "role": "user",
        "content": "Hello",
        "created_at": "2026-01-25T10:31:00Z"
      },
      {
        "id": "msg-002",
        "role": "assistant",
        "content": "안녕하세요! 무엇을 도와드릴까요?",
        "created_at": "2026-01-25T10:31:05Z"
      }
    ]
  }
}
```

### 메시지 전송

세션에 메시지를 전송합니다.

**요청**:
```http
POST /api/v1/sessions/{session_id}/messages
Content-Type: application/json
```

**요청 본문**:
```json
{
  "content": "Python으로 피보나치 함수를 작성해줘"
}
```

**응답 예시**:
```json
{
  "data": {
    "id": "msg-003",
    "session_id": "550e8400-e29b-41d4-a716-446655440000",
    "role": "user",
    "content": "Python으로 피보나치 함수를 작성해줘",
    "created_at": "2026-01-25T12:35:00Z"
  }
}
```

**참고**: 실제 AI 응답은 WebSocket을 통해 스트리밍됩니다.

### 세션 삭제

세션을 삭제합니다.

**요청**:
```http
DELETE /api/v1/sessions/{session_id}
```

**응답 예시**:
```json
{
  "data": {
    "message": "세션이 삭제되었습니다"
  }
}
```

## 템플릿 API

### 템플릿 목록 조회

**요청**:
```http
GET /api/v1/templates
```

**쿼리 파라미터**:
- `workspace_id` (optional): 워크스페이스별 필터링
- `scope` (optional): 범위 필터링 (`workspace`, `global`)

**응답 예시**:
```json
{
  "data": {
    "templates": [
      {
        "id": "template-001",
        "workspace_id": "workspace-123",
        "name": "코드 리뷰 요청",
        "content": "다음 코드를 리뷰해주세요:\n\n{{code}}",
        "variables": ["code"],
        "scope": "workspace",
        "created_at": "2026-01-20T10:00:00Z",
        "updated_at": "2026-01-20T10:00:00Z"
      }
    ],
    "total": 1
  }
}
```

### 템플릿 생성

**요청**:
```http
POST /api/v1/templates
Content-Type: application/json
```

**요청 본문**:
```json
{
  "workspace_id": "workspace-123",
  "name": "버그 리포트",
  "content": "다음 버그를 수정해주세요:\n\n**증상**: {{symptom}}\n**재현 방법**: {{steps}}",
  "variables": ["symptom", "steps"],
  "scope": "workspace"
}
```

**응답 예시**:
```json
{
  "data": {
    "id": "template-002",
    "workspace_id": "workspace-123",
    "name": "버그 리포트",
    "content": "다음 버그를 수정해주세요:\n\n**증상**: {{symptom}}\n**재현 방법**: {{steps}}",
    "variables": ["symptom", "steps"],
    "scope": "workspace",
    "created_at": "2026-01-25T13:00:00Z",
    "updated_at": "2026-01-25T13:00:00Z"
  }
}
```

### 템플릿 수정

**요청**:
```http
PUT /api/v1/templates/{template_id}
Content-Type: application/json
```

**요청 본문**:
```json
{
  "name": "버그 리포트 (업데이트)",
  "content": "...",
  "variables": ["symptom", "steps", "priority"]
}
```

### 템플릿 삭제

**요청**:
```http
DELETE /api/v1/templates/{template_id}
```

## 워크스페이스 API

### 워크스페이스 목록 조회

**요청**:
```http
GET /api/v1/workspaces
```

**응답 예시**:
```json
{
  "data": {
    "workspaces": [
      {
        "id": "workspace-123",
        "path": "/Users/username/projects/myapp",
        "name": "My App",
        "created_at": "2026-01-15T08:00:00Z",
        "updated_at": "2026-01-25T12:00:00Z",
        "metadata": {
          "session_count": 5,
          "template_count": 3
        }
      }
    ],
    "total": 1
  }
}
```

### 워크스페이스 생성

**요청**:
```http
POST /api/v1/workspaces
Content-Type: application/json
```

**요청 본문**:
```json
{
  "path": "/Users/username/projects/newapp",
  "name": "New App"
}
```

## 스킬 API

### 스킬 목록 조회

**요청**:
```http
GET /api/v1/skills
```

**응답 예시**:
```json
{
  "data": {
    "skills": [
      {
        "id": "commit",
        "name": "Git Commit",
        "description": "코드 변경사항을 커밋합니다",
        "enabled": true
      },
      {
        "id": "test",
        "name": "Run Tests",
        "description": "테스트를 실행합니다",
        "enabled": true
      }
    ],
    "total": 2
  }
}
```

### 스킬 활성화/비활성화

**요청**:
```http
PATCH /api/v1/skills/{skill_id}
Content-Type: application/json
```

**요청 본문**:
```json
{
  "enabled": false
}
```

## WebSocket API

### 연결

**WebSocket URL**:
```
ws://localhost:8000/ws/session/{session_id}
```

**연결 예시 (JavaScript)**:
```javascript
const ws = new WebSocket('ws://localhost:8000/ws/session/session-123');

ws.onopen = () => {
  console.log('WebSocket 연결됨');
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('이벤트 수신:', data);
};

ws.onerror = (error) => {
  console.error('WebSocket 에러:', error);
};

ws.onclose = () => {
  console.log('WebSocket 연결 종료');
};
```

### 이벤트 타입

#### 1. MESSAGE_START

메시지 스트리밍 시작

```json
{
  "type": "message_start",
  "data": {
    "message_id": "msg-004",
    "role": "assistant"
  },
  "timestamp": "2026-01-25T13:10:00Z"
}
```

#### 2. MESSAGE_DELTA

메시지 내용 스트리밍

```json
{
  "type": "message_delta",
  "data": {
    "message_id": "msg-004",
    "delta": "안녕하세요"
  },
  "timestamp": "2026-01-25T13:10:01Z"
}
```

#### 3. MESSAGE_END

메시지 스트리밍 완료

```json
{
  "type": "message_end",
  "data": {
    "message_id": "msg-004"
  },
  "timestamp": "2026-01-25T13:10:05Z"
}
```

#### 4. FILE_CHANGED

파일 변경 이벤트

```json
{
  "type": "file_changed",
  "data": {
    "path": "src/main.py",
    "status": "modified",
    "diff": "..."
  },
  "timestamp": "2026-01-25T13:10:10Z"
}
```

#### 5. TOOL_USE

도구 사용 이벤트

```json
{
  "type": "tool_use",
  "data": {
    "tool": "bash",
    "command": "pytest tests/",
    "status": "running"
  },
  "timestamp": "2026-01-25T13:10:15Z"
}
```

#### 6. ERROR

에러 이벤트

```json
{
  "type": "error",
  "data": {
    "code": "OPENCODE_ERROR",
    "message": "OpenCode 연결 실패",
    "details": {}
  },
  "timestamp": "2026-01-25T13:10:20Z"
}
```

### Python WebSocket 클라이언트 예시

```python
import asyncio
import websockets
import json

async def listen_to_session(session_id):
    uri = f"ws://localhost:8000/ws/session/{session_id}"

    async with websockets.connect(uri) as websocket:
        print(f"연결됨: {session_id}")

        async for message in websocket:
            event = json.loads(message)
            event_type = event["type"]

            if event_type == "message_delta":
                print(event["data"]["delta"], end="", flush=True)
            elif event_type == "message_end":
                print("\n[메시지 완료]")
            elif event_type == "error":
                print(f"\n[에러] {event['data']['message']}")

if __name__ == "__main__":
    asyncio.run(listen_to_session("session-123"))
```

## 에러 코드

### HTTP 상태 코드

- `200 OK`: 요청 성공
- `201 Created`: 리소스 생성 성공
- `204 No Content`: 삭제 성공
- `400 Bad Request`: 잘못된 요청
- `404 Not Found`: 리소스를 찾을 수 없음
- `409 Conflict`: 리소스 충돌
- `500 Internal Server Error`: 서버 내부 에러
- `502 Bad Gateway`: OpenCode 연결 실패
- `503 Service Unavailable`: 서비스 일시 중단

### 애플리케이션 에러 코드

| 코드 | 설명 |
|------|------|
| `VALIDATION_ERROR` | 입력 검증 실패 |
| `RESOURCE_NOT_FOUND` | 리소스를 찾을 수 없음 |
| `DUPLICATE_RESOURCE` | 중복된 리소스 |
| `OPENCODE_CONNECTION_ERROR` | OpenCode 연결 실패 |
| `OPENCODE_API_ERROR` | OpenCode API 에러 |
| `DATABASE_ERROR` | 데이터베이스 에러 |
| `INTERNAL_ERROR` | 내부 서버 에러 |

### 에러 응답 예시

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "세션을 찾을 수 없습니다",
    "details": {
      "session_id": "invalid-session-id"
    }
  }
}
```

## Rate Limiting

현재 버전에서는 Rate Limiting이 구현되어 있지 않습니다. 향후 버전에서 추가될 예정입니다.

## 버전 관리

API 버전은 URL 경로에 포함됩니다 (`/api/v1/`). 주요 변경 시 새 버전을 릴리스합니다.

## 추가 자료

- [FastAPI 자동 생성 문서](http://localhost:8000/docs)
- [ReDoc 문서](http://localhost:8000/redoc)
- [OpenAPI 스펙](http://localhost:8000/openapi.json)
