# 문제 해결 가이드

OpenWork 사용 중 발생할 수 있는 일반적인 문제와 해결 방법을 정리했습니다.

## 목차

- [일반적인 문제](#일반적인-문제)
- [백엔드 문제](#백엔드-문제)
- [프론트엔드 문제](#프론트엔드-문제)
- [OpenCode 연결 문제](#opencode-연결-문제)
- [데이터베이스 문제](#데이터베이스-문제)
- [성능 문제](#성능-문제)
- [로그 확인 방법](#로그-확인-방법)

## 일반적인 문제

### 서비스가 시작되지 않음

**증상**: 서버 실행 시 즉시 종료되거나 에러 발생

**해결 방법**:

1. **포트 충돌 확인**

```bash
# 8000 포트 사용 중인 프로세스 확인
lsof -i :8000  # macOS/Linux
netstat -ano | findstr :8000  # Windows

# 프로세스 종료
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

2. **환경 변수 확인**

```bash
# .env 파일이 있는지 확인
ls -la .env

# 환경 변수 로드 확인
python -c "from app.core.config import settings; print(settings.DATABASE_URL)"
```

3. **의존성 확인**

```bash
# 가상환경 활성화 확인
which python  # venv 경로가 출력되어야 함

# 의존성 재설치
pip install -r requirements.txt --force-reinstall
```

### "Module not found" 에러

**증상**: `ImportError: No module named 'xxx'`

**해결 방법**:

```bash
# 1. 가상환경이 활성화되어 있는지 확인
source venv/bin/activate

# 2. 패키지 재설치
pip install -r requirements.txt

# 3. Python 경로 확인
echo $PYTHONPATH

# 4. 개발 모드로 패키지 설치
pip install -e .
```

### 권한 에러

**증상**: `PermissionError: [Errno 13] Permission denied`

**해결 방법**:

```bash
# 디렉토리 권한 확인
ls -la data/

# 권한 수정
chmod 755 data/
chown $USER:$USER data/

# Docker 사용 시
docker-compose down
sudo chown -R $USER:$USER .
docker-compose up -d
```

## 백엔드 문제

### FastAPI 서버가 응답하지 않음

**증상**: API 요청이 타임아웃되거나 응답 없음

**진단**:

```bash
# 헬스 체크
curl http://localhost:8000/health

# 프로세스 확인
ps aux | grep uvicorn

# 로그 확인
tail -f logs/app.log
```

**해결 방법**:

1. **서버 재시작**

```bash
# systemd
sudo systemctl restart openwork

# Docker
docker-compose restart backend

# 수동
pkill uvicorn
uvicorn app.main:app --reload
```

2. **워커 수 조정**

```bash
# 워커 수를 줄여서 실행
uvicorn app.main:app --workers 1 --timeout-keep-alive 5
```

### 데이터베이스 연결 에러

**증상**: `sqlalchemy.exc.OperationalError: unable to open database file`

**해결 방법**:

```bash
# 1. 데이터 디렉토리 확인
mkdir -p data

# 2. 데이터베이스 파일 권한
chmod 644 data/openwork.db

# 3. 데이터베이스 재생성
rm data/openwork.db
alembic upgrade head

# PostgreSQL 연결 문제
psql -U openwork -h localhost -d openwork  # 수동 연결 테스트
```

### Alembic 마이그레이션 실패

**증상**: `alembic upgrade head` 실행 시 에러

**해결 방법**:

```bash
# 현재 마이그레이션 상태 확인
alembic current

# 마이그레이션 히스토리
alembic history

# 특정 버전으로 다운그레이드
alembic downgrade -1

# 마이그레이션 재생성
alembic revision --autogenerate -m "Fix migration"

# 강제 스탬프 (주의!)
alembic stamp head
```

### Pydantic 검증 에러

**증상**: `pydantic.error_wrappers.ValidationError`

**해결 방법**:

```python
# 스키마 정의 확인
from app.schemas.session import SessionCreate

# 데이터 수동 검증
try:
    SessionCreate(workspace_id="test", title="Test")
except ValidationError as e:
    print(e.json())
```

```bash
# API 요청 디버깅
curl -X POST http://localhost:8000/api/v1/sessions \
  -H "Content-Type: application/json" \
  -d '{"workspace_id":"test","title":"Test"}' \
  -v  # verbose 모드로 자세한 정보 확인
```

## 프론트엔드 문제

### Flutter 빌드 에러

**증상**: `flutter build` 또는 `flutter run` 실패

**해결 방법**:

```bash
# 1. 클린 빌드
flutter clean
flutter pub get
flutter run

# 2. 캐시 삭제
rm -rf .dart_tool/
rm pubspec.lock
flutter pub get

# 3. Flutter 업그레이드
flutter upgrade
flutter doctor

# 4. 특정 패키지 재설치
flutter pub cache repair
```

### "Bad state: No element" 에러

**증상**: Riverpod 또는 Provider 관련 에러

**해결 방법**:

```dart
// ProviderScope가 최상위에 있는지 확인
void main() {
  runApp(
    const ProviderScope(  // 필수!
      child: MyApp(),
    ),
  );
}

// Provider 읽기 전에 null 체크
final session = ref.watch(sessionProvider(sessionId));
if (session == null) {
  return const CircularProgressIndicator();
}
```

### WebSocket 연결 실패

**증상**: WebSocket이 연결되지 않거나 즉시 끊김

**진단**:

```dart
// 연결 상태 로깅
final channel = WebSocketChannel.connect(Uri.parse(wsUrl));

channel.stream.listen(
  (message) {
    print('Received: $message');
  },
  onError: (error) {
    print('WebSocket error: $error');
  },
  onDone: () {
    print('WebSocket closed');
  },
);
```

**해결 방법**:

1. **백엔드 WebSocket 엔드포인트 확인**

```bash
# wscat으로 테스트
npm install -g wscat
wscat -c ws://localhost:8000/ws/session/test-123
```

2. **CORS 설정 확인**

```python
# app/main.py
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 개발 환경에서만
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### UI가 업데이트되지 않음

**증상**: 데이터가 변경되었는데 UI에 반영되지 않음

**해결 방법**:

```dart
// 1. notifyListeners() 호출 확인 (ChangeNotifier)
class MyNotifier extends ChangeNotifier {
  void updateData() {
    // ...
    notifyListeners();  // 필수!
  }
}

// 2. Riverpod ref.invalidate() 사용
ref.invalidate(sessionProvider(sessionId));

// 3. AsyncValue 상태 확인
session.when(
  data: (data) => Text(data.title),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

## OpenCode 연결 문제

### OpenCode API 연결 실패

**증상**: `OPENCODE_CONNECTION_ERROR` 또는 502 Bad Gateway

**진단**:

```bash
# OpenCode 프로세스 확인
ps aux | grep opencode

# OpenCode API 엔드포인트 테스트
curl http://localhost:8080/health

# 수동으로 OpenCode 실행
opencode --api --port 8080 --verbose
```

**해결 방법**:

1. **OpenCode 재시작**

```bash
# OpenCode 프로세스 종료
pkill opencode

# API 모드로 재시작
opencode --api --port 8080
```

2. **포트 변경**

```bash
# .env 파일 수정
OPENCODE_URL=http://localhost:8081

# OpenCode 다른 포트로 실행
opencode --api --port 8081
```

3. **네트워크 확인**

```bash
# 포트 리스닝 확인
netstat -an | grep 8080

# 방화벽 확인 (macOS)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps

# 방화벽 확인 (Linux)
sudo ufw status
```

### OpenCode 응답 타임아웃

**증상**: 요청이 너무 느리거나 타임아웃

**해결 방법**:

```python
# app/services/opencode_client.py
import httpx

class OpenCodeClient:
    def __init__(self):
        self.client = httpx.AsyncClient(
            timeout=httpx.Timeout(
                connect=5.0,
                read=120.0,  # 읽기 타임아웃 증가
                write=5.0,
                pool=5.0,
            )
        )
```

### OpenCode 세션 손실

**증상**: 세션 ID가 유효하지 않다는 에러

**해결 방법**:

```python
# 세션 존재 여부 확인
async def verify_session(session_id: str):
    try:
        response = await opencode_client.get(f"/session/{session_id}")
        return response.status_code == 200
    except Exception:
        return False

# 세션 재생성
if not await verify_session(session_id):
    session = await create_new_session()
```

## 데이터베이스 문제

### SQLite 잠금 에러

**증상**: `database is locked`

**해결 방법**:

```python
# 타임아웃 증가
from sqlalchemy import create_engine

engine = create_engine(
    "sqlite:///./data/openwork.db",
    connect_args={
        "check_same_thread": False,
        "timeout": 30  # 기본값 5초에서 증가
    }
)
```

```bash
# 또는 PostgreSQL로 마이그레이션 권장
# 프로덕션 환경에서는 SQLite 사용 지양
```

### 마이그레이션 충돌

**증상**: Alembic 마이그레이션 버전 충돌

**해결 방법**:

```bash
# 1. 현재 상태 확인
alembic current

# 2. 충돌 해결
alembic merge <rev1> <rev2>

# 3. 새 마이그레이션 적용
alembic upgrade head

# 4. 최악의 경우 DB 재생성
rm data/openwork.db
alembic upgrade head
```

### 데이터 손실

**증상**: 세션 또는 메시지가 사라짐

**복구 방법**:

```bash
# SQLite 백업 확인
ls -la data/backup/

# 백업에서 복원
cp data/backup/openwork_20260125.db data/openwork.db

# 백업 자동화 (cron)
0 */6 * * * cp /opt/openwork/data/openwork.db /opt/openwork/data/backup/openwork_$(date +\%Y\%m\%d_\%H\%M).db
```

## 성능 문제

### API 응답 느림

**진단**:

```python
# app/middleware/timing.py
import time
from fastapi import Request

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    print(f"{request.url.path}: {process_time:.2f}s")
    return response
```

**해결 방법**:

1. **데이터베이스 쿼리 최적화**

```python
# N+1 쿼리 방지
from sqlalchemy.orm import joinedload

sessions = db.query(Session).options(
    joinedload(Session.messages),
    joinedload(Session.workspace)
).all()
```

2. **캐싱 도입**

```python
from functools import lru_cache

@lru_cache(maxsize=100)
def get_workspace(workspace_id: str):
    return db.query(Workspace).filter_by(id=workspace_id).first()
```

3. **워커 수 증가**

```bash
# Gunicorn으로 실행
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker
```

### 메모리 누수

**진단**:

```bash
# 메모리 사용량 모니터링
ps aux | grep uvicorn
top -p <PID>

# Python 메모리 프로파일링
pip install memory_profiler
python -m memory_profiler app/main.py
```

**해결 방법**:

```python
# 대용량 데이터 스트리밍
from fastapi.responses import StreamingResponse

@app.get("/export")
async def export_data():
    def generate():
        for row in large_dataset:
            yield row + "\n"

    return StreamingResponse(generate(), media_type="text/csv")

# 데이터베이스 세션 정리
from sqlalchemy.orm import scoped_session

Session = scoped_session(sessionmaker(bind=engine))

@app.middleware("http")
async def db_session_middleware(request: Request, call_next):
    response = await call_next(request)
    Session.remove()  # 세션 정리
    return response
```

### Flutter 앱 느림

**해결 방법**:

```dart
// 1. 불필요한 rebuild 방지
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch 대신 read 사용 (rebuild 불필요할 때)
    final api = ref.read(apiClientProvider);

    // 특정 필드만 watch
    final title = ref.watch(sessionProvider.select((s) => s.title));

    return Text(title);
  }
}

// 2. ListView.builder 사용 (대량 데이터)
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) => MessageWidget(messages[index]),
);

// 3. 이미지 캐싱
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
);
```

## 로그 확인 방법

### 백엔드 로그

```bash
# systemd
sudo journalctl -u openwork -f

# Docker
docker-compose logs -f backend
docker logs -f openwork_backend_1

# 파일 로그
tail -f /var/log/openwork/app.log

# 특정 에러만 필터링
grep ERROR /var/log/openwork/app.log
```

### 프론트엔드 로그

```bash
# Flutter 콘솔
flutter run --verbose

# 특정 로그만
flutter run 2>&1 | grep "ERROR"

# Chrome DevTools (Flutter Web)
open http://localhost:53000/
```

### OpenCode 로그

```bash
# OpenCode 로그 위치
~/.opencode/logs/

# 실시간 로그
tail -f ~/.opencode/logs/opencode.log

# 특정 세션 로그
grep "session-123" ~/.opencode/logs/opencode.log
```

## 도움 요청하기

문제가 해결되지 않으면 다음 정보와 함께 이슈를 생성해주세요:

1. **환경 정보**
   - OS 및 버전
   - Python/Flutter 버전
   - OpenWork 버전

2. **재현 방법**
   - 문제 발생 단계
   - 최소 재현 코드

3. **에러 로그**
   - 전체 스택 트레이스
   - 관련 로그 파일

4. **시도한 해결 방법**
   - 이미 시도한 해결책
   - 결과

**이슈 템플릿**:

```markdown
### 환경
- OS: macOS 13.0
- Python: 3.10.8
- Flutter: 3.16.0
- OpenWork: 0.1.0

### 문제 설명
[명확하고 간결한 설명]

### 재현 방법
1. ...
2. ...
3. ...

### 예상 동작
[정상 동작 설명]

### 실제 동작
[에러 발생 설명]

### 에러 로그
```
[로그 첨부]
```

### 시도한 해결 방법
- [x] 서버 재시작
- [x] 캐시 삭제
- [ ] ...
```

## 추가 자료

- [GitHub Issues](https://github.com/yourusername/openwork/issues)
- [GitHub Discussions](https://github.com/yourusername/openwork/discussions)
- [API 문서](api.md)
- [개발 가이드](development.md)
