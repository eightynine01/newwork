# NewWork

> AI 기반 코딩 어시스턴트 - 통합 데스크톱 애플리케이션

[![GitHub stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/network/members)
[![GitHub watchers](https://img.shields.io/github/watchers/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/watchers)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Flutter](https://img.shields.io/badge/flutter-3.0+-blue.svg)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109+-green.svg)](https://fastapi.tiangolo.com/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

<!-- Star History Chart -->
<a href="https://star-history.com/#eightynine01/newwork&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=eightynine01/newwork&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=eightynine01/newwork&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=eightynine01/newwork&type=Date" />
 </picture>
</a>

## 📖 개요

**NewWork**는 Claude Code(구 OpenCode)를 위한 통합 데스크톱 GUI 애플리케이션입니다. Flutter 프론트엔드와 Python 백엔드가 단일 실행 파일로 번들링되어, 설치 즉시 별도의 설정 없이 바로 사용할 수 있습니다.

### 핵심 특징

- 🎯 **올인원 애플리케이션**: Flutter UI + Python 백엔드가 하나의 실행 파일로 통합
- 🚀 **즉시 실행**: Docker나 별도의 서버 설정 불필요
- 💾 **로컬 우선**: SQLite 기반 로컬 데이터 저장
- 🖥️ **크로스 플랫폼**: Windows, macOS, Linux 지원
- 🔒 **프라이버시**: 모든 데이터가 로컬에 저장

### 주요 기능

- 🎯 **세션 관리**: AI 코딩 세션 생성, 조회, 관리
- 📝 **템플릿 시스템**: 재사용 가능한 프롬프트 및 워크플로우
- 🔧 **스킬 관리**: AI 에이전트 기능 및 도구 관리
- 📁 **워크스페이스**: 프로젝트 조직 및 관리
- 🔌 **MCP 통합**: Model Context Protocol 서버 지원
- 🌐 **실시간 통신**: WebSocket을 통한 실시간 스트리밍
- 🎨 **Material 3 디자인**: 모던하고 반응형 UI

## 🏗️ 아키텍처

NewWork는 사용자가 백엔드 존재를 인식하지 못하도록 완전히 통합된 아키텍처를 사용합니다:

```
┌─────────────────────────────────────┐
│   NewWork Desktop Application      │
│   (Flutter - 단일 실행 파일)          │
│                                     │
│  ┌─────────────┐  ┌──────────────┐ │
│  │   Flutter   │  │   Python     │ │
│  │   UI Layer  │◄─┤   Backend    │ │
│  │             │  │   (FastAPI)  │ │
│  └─────────────┘  └──────┬───────┘ │
│         │                │         │
│         │         ┌──────▼───────┐ │
│         └────────►│   SQLite DB  │ │
│                   └──────────────┘ │
└─────────────────────────────────────┘
         │
         ▼
   ┌──────────────┐
   │  OpenCode    │
   │  CLI (외부)   │
   └──────────────┘
```

**작동 방식**:
1. 사용자가 NewWork 앱 실행
2. 앱 시작 시 번들된 Python 백엔드 자동 시작
3. Flutter UI가 localhost API와 통신
4. 앱 종료 시 백엔드 자동 정리
5. 모든 데이터는 OS별 표준 위치에 저장

## 🚀 빠른 시작

### 사전 요구사항

- **개발 환경**:
  - Python 3.10 이상
  - Flutter 3.0 이상
  - OpenCode CLI (선택사항)

- **사용자 (릴리스 버전)**:
  - 사전 요구사항 없음! 실행 파일만 다운로드하면 됩니다.

### 릴리스 버전 설치

#### macOS
```bash
# DMG 다운로드 후 설치
open NewWork.dmg
# Applications 폴더로 드래그 앤 드롭

# 실행
open /Applications/NewWork.app
```

#### Linux
```bash
# AppImage 다운로드
chmod +x NewWork-x86_64.AppImage
./NewWork-x86_64.AppImage

# 또는 .deb 패키지
sudo dpkg -i newwork_0.2.0_amd64.deb
newwork
```

#### Windows
```bash
# Setup.exe 실행하여 설치
NewWork-Setup.exe

# 시작 메뉴에서 실행
# 또는 바탕화면 아이콘 더블 클릭
```

### 개발 환경 설정

#### 1. 저장소 클론

```bash
git clone https://github.com/eightynine01/newwork.git
cd newwork
```

#### 2. 백엔드 개발 모드

```bash
cd newwork-backend

# 가상환경 생성 및 활성화
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# 개발 서버 실행
make dev
# 또는
uvicorn app.main:app --reload --port 8000
```

백엔드는 `http://localhost:8000`에서 실행됩니다.

API 문서: http://localhost:8000/docs

#### 3. 프론트엔드 개발 모드

```bash
cd newwork-app

# 의존성 설치
flutter pub get

# 앱 실행 (백엔드가 실행 중이어야 함)
flutter run -d macos  # 또는 linux, windows
```

#### 4. 통합 빌드

```bash
# 프로젝트 루트에서
./scripts/build-all.sh

# macOS 빌드만
cd newwork-app && flutter build macos --release

# Windows 빌드만 (PowerShell)
.\scripts\build-windows.ps1
```

## 📚 프로젝트 구조

```
newwork/
├── newwork-backend/          # FastAPI 백엔드
│   ├── app/
│   │   ├── api/             # REST API 엔드포인트
│   │   │   ├── sessions.py # 세션 관리 API
│   │   │   ├── templates.py # 템플릿 API
│   │   │   ├── skills.py    # 스킬 관리 API
│   │   │   └── ...
│   │   ├── models/          # SQLAlchemy 데이터 모델
│   │   ├── schemas/         # Pydantic 요청/응답 스키마
│   │   ├── services/        # 비즈니스 로직
│   │   │   ├── opencode_client.py  # OpenCode CLI 통합
│   │   │   └── file_service.py
│   │   ├── core/            # 앱 설정 및 DB
│   │   └── main.py          # FastAPI 앱 진입점
│   ├── tests/               # 백엔드 테스트
│   ├── pyproject.toml       # Python 프로젝트 설정
│   ├── newwork.spec         # PyInstaller 스펙
│   └── build.sh             # 백엔드 빌드 스크립트
│
├── newwork-app/              # Flutter 프론트엔드
│   ├── lib/
│   │   ├── main.dart        # 앱 진입점
│   │   ├── app.dart         # 앱 위젯
│   │   ├── features/        # 기능별 모듈
│   │   │   ├── session/     # 세션 페이지
│   │   │   ├── template/    # 템플릿 관리
│   │   │   ├── dashboard/   # 메인 대시보드
│   │   │   └── settings/    # 설정
│   │   ├── services/        # 서비스 레이어
│   │   │   ├── backend_manager.dart  # 백엔드 프로세스 관리
│   │   │   ├── api_client.dart       # HTTP API 클라이언트
│   │   │   └── websocket_service.dart # WebSocket 통신
│   │   ├── providers/       # Riverpod 상태 관리
│   │   ├── models/          # 데이터 모델
│   │   └── widgets/         # 공유 위젯
│   ├── pubspec.yaml         # Flutter 의존성
│   └── assets/              # 에셋 (백엔드 바이너리 포함)
│
├── newwork-reference/        # Tauri 참고 구현 (보관)
│
├── scripts/                  # 빌드 및 배포 스크립트
│   ├── build-all.sh         # 전체 플랫폼 빌드
│   ├── build-windows.ps1    # Windows 전용 빌드
│   ├── package-macos.sh     # macOS DMG 생성
│   └── package-linux.sh     # Linux 패키지 생성
│
├── docs/                     # 프로젝트 문서
│   ├── architecture.md      # 아키텍처 가이드
│   ├── api.md               # API 문서
│   ├── deployment.md        # 배포 가이드
│   └── development.md       # 개발자 가이드
│
├── .github/workflows/        # CI/CD 파이프라인
│   ├── backend-tests.yml    # 백엔드 테스트
│   ├── frontend-tests.yml   # 프론트엔드 테스트
│   └── build-release.yml    # 릴리스 빌드
│
├── Makefile                  # 통합 빌드 명령어
├── CONTRIBUTING.md           # 기여 가이드
├── CODE_OF_CONDUCT.md        # 행동 강령
├── CHANGELOG.md              # 변경 이력
├── LICENSE                   # MIT 라이센스
└── README.md                 # 이 파일
```

## 🔧 설정

### 데이터 저장 위치

NewWork는 OS별 표준 위치에 데이터를 저장합니다:

- **macOS**: `~/Library/Application Support/NewWork/`
- **Linux**: `~/.local/share/NewWork/`
- **Windows**: `%APPDATA%\NewWork\`

데이터베이스 파일: `newwork.db`

### 개발 환경변수 (.env)

백엔드 개발 시 `.env` 파일 설정:

```env
# 애플리케이션 설정
APP_NAME=NewWork API
APP_VERSION=0.2.0
DEBUG=True

# 서버 설정
HOST=127.0.0.1
PORT=8000

# OpenCode CLI 설정
OPENCODE_URL=http://localhost:8080
OPENCODE_TIMEOUT=30

# 데이터베이스 (개발 모드)
DATABASE_URL=sqlite:///./newwork-dev.db

# CORS (개발 모드)
CORS_ORIGINS=http://localhost:*
```

## 🧪 테스트

### 백엔드 테스트

```bash
cd newwork-backend

# 전체 테스트 실행
make test
# 또는
pytest

# 커버리지 포함
pytest --cov=app tests/

# 특정 테스트
pytest tests/api/test_sessions.py
```

### 프론트엔드 테스트

```bash
cd newwork-app

# 위젯 테스트
flutter test

# 통합 테스트
flutter test integration_test/
```

### 통합 테스트

```bash
# 전체 빌드 후 실행 테스트
./scripts/build-all.sh

# macOS
open newwork-app/build/macos/Build/Products/Release/NewWork.app

# 테스트 체크리스트:
# - 앱 시작 시 백엔드 자동 시작
# - 새 세션 생성
# - 메시지 전송 및 실시간 응답
# - 템플릿 저장 및 불러오기
# - 앱 종료 시 백엔드 정리
```

## 📖 API 문서

백엔드 실행 후 다음 URL에서 API 문서를 확인할 수 있습니다:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

### 주요 엔드포인트

| 엔드포인트 | 메서드 | 설명 |
|-----------|--------|------|
| `/health` | GET | 헬스 체크 |
| `/api/v1/sessions` | GET, POST | 세션 관리 |
| `/api/v1/sessions/{id}/messages` | POST | 메시지 전송 |
| `/api/v1/templates` | GET, POST | 템플릿 관리 |
| `/api/v1/skills` | GET, POST | 스킬 관리 |
| `/api/v1/workspaces` | GET, POST | 워크스페이스 관리 |
| `/api/v1/mcp` | GET, POST | MCP 서버 관리 |
| `/ws/session/{id}` | WebSocket | 실시간 세션 스트리밍 |

## 🛠️ 개발 가이드

### Makefile 명령어

```bash
# 도움말
make help

# 개발 서버 실행 (백엔드 + 프론트엔드)
make dev

# 전체 빌드
make build-all

# 플랫폼별 빌드
make build-macos
make build-linux
make build-windows

# 테스트
make test

# 정리
make clean
```

### 코드 품질

**백엔드 (Python)**:
```bash
cd newwork-backend

# 포맷팅
make format

# 린트
make lint

# 타입 체크
make typecheck

# 보안 체크
make security
```

**프론트엔드 (Flutter)**:
```bash
cd newwork-app

# 분석
flutter analyze

# 포맷팅
dart format lib/
```

## 🎯 개발 로드맵

### v0.2.0 (현재) - 통합 앱
- [x] 프로젝트 이름 변경 (OpenWork → NewWork)
- [x] Python 백엔드 독립 실행 파일화 (PyInstaller)
- [ ] Flutter 앱 백엔드 통합
- [ ] 크로스 플랫폼 빌드 파이프라인
- [ ] 첫 릴리스 배포

### v0.3.0 - 핵심 기능 강화
- [ ] 향상된 세션 관리
- [ ] 템플릿 라이브러리
- [ ] 플러그인 마켓플레이스
- [ ] 다크/라이트 테마

### v0.4.0 - 협업 기능
- [ ] 워크스페이스 공유
- [ ] 템플릿 익스포트/임포트
- [ ] 클라우드 백업 (선택사항)

### v1.0.0 - 프로덕션 릴리스
- [ ] 완전한 기능 세트
- [ ] 포괄적인 문서
- [ ] 자동 업데이트
- [ ] 커뮤니티 지원

## 🔄 유사 프로젝트 비교

NewWork는 다른 AI 코딩 어시스턴트 프로젝트들과 어떻게 다른지 비교해보세요.

| 특성 | NewWork | [OpenWork](https://github.com/different-ai/openwork) | [Moltbot](https://github.com/moltbot/moltbot) |
|------|---------|----------|---------|
| ⭐ GitHub Stars | ![GitHub stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social) | ![GitHub stars](https://img.shields.io/github/stars/different-ai/openwork?style=social) | ![GitHub stars](https://img.shields.io/github/stars/moltbot/moltbot?style=social) |
| 🎯 핵심 목표 | 통합 데스크톱 앱 | 에이전트 워크플로우 | 개인 AI 어시스턴트 |
| 🖥️ 프론트엔드 | Flutter | SolidJS + TailwindCSS | Node.js CLI |
| ⚙️ 백엔드 | FastAPI (Python) | OpenCode CLI (spawned) | TypeScript |
| 📦 데스크톱 | Native (Flutter) | Tauri 2.x (Rust) | Electron/Native |
| 💾 데이터베이스 | SQLite (로컬) | IndexedDB | 로컬 파일 |
| 🔌 메시징 통합 | ❌ | WhatsApp (owpenbot) | WhatsApp, Telegram, Discord, Slack 등 |
| 📱 모바일 | ✅ (Flutter) | ❌ | ❌ |
| 🚀 설치 방식 | 단일 실행 파일 | DMG/소스 빌드 | CLI 설치 |
| 🔧 OpenCode 의존 | 선택적 | 필수 | 독립 |

### 왜 NewWork인가?

1. **진정한 올인원**: 백엔드가 앱 안에 완전히 내장되어 별도 설정 불필요
2. **Flutter 기반**: 모바일 확장이 용이하고 Material Design 3 적용
3. **Python 백엔드**: 확장과 커스터마이징이 쉬운 FastAPI 아키텍처
4. **프라이버시 우선**: 모든 데이터가 로컬에 저장되며 외부 서버 불필요

## 🤝 기여하기

**모든 형태의 기여를 환영합니다!** 🎉

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)
[![Good First Issues](https://img.shields.io/github/issues/eightynine01/newwork/good%20first%20issue?color=7057ff&label=good%20first%20issues)](https://github.com/eightynine01/newwork/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

### 🌟 기여 방법

| 유형 | 설명 |
|------|------|
| 🐛 **버그 리포트** | 문제를 발견하셨나요? [이슈](https://github.com/eightynine01/newwork/issues/new?template=bug_report.md)를 열어주세요 |
| 💡 **기능 제안** | 아이디어가 있으시면 [제안](https://github.com/eightynine01/newwork/issues/new?template=feature_request.md)해주세요 |
| 📝 **문서 개선** | 오타 수정, 번역, 가이드 추가 모두 환영합니다 |
| 🔧 **코드 기여** | PR을 보내주세요! OpenCode 관련 PR 특히 환영합니다 |
| ⭐ **Star 주기** | 프로젝트가 마음에 드시면 Star를 눌러주세요! |

### 개발 플로우

```bash
# 1. 포크 후 클론
git clone https://github.com/YOUR_USERNAME/newwork.git
cd newwork

# 2. 기능 브랜치 생성
git checkout -b feature/amazing-feature

# 3. 변경사항 커밋
git commit -m "feat: add amazing feature"

# 4. PR 생성
git push origin feature/amazing-feature
```

### 개발 가이드라인

- **코드 스타일**: Python은 Ruff, Dart는 `dart format` 사용
- **테스트**: 모든 PR은 테스트를 포함해야 합니다
- **문서**: 새로운 기능은 문서화되어야 합니다
- **커밋 메시지**: [Conventional Commits](https://www.conventionalcommits.org/) 형식 권장

## ☕ 후원하기

이 프로젝트가 유용하셨다면 커피 한 잔 사주세요! ☕

<a href="https://www.buymeacoffee.com/newwork" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="50">
</a>

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/newwork)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/newwork)

> 후원금은 서버 비용, 도메인, 그리고 더 나은 기능 개발에 사용됩니다.

## 📄 라이센스

이 프로젝트는 MIT 라이센스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고해주세요.

## 🙏 감사의 말

- [Claude Code](https://claude.ai/code) - AI 코딩 어시스턴트
- [FastAPI](https://fastapi.tiangolo.com/) - 모던 Python 웹 프레임워크
- [Flutter](https://flutter.dev/) - 크로스 플랫폼 UI 프레임워크
- [PyInstaller](https://www.pyinstaller.org/) - Python 실행 파일 번들러
- [Riverpod](https://riverpod.dev/) - Flutter 상태 관리

## 📞 문의 및 지원

- **이슈 트래커**: [GitHub Issues](https://github.com/eightynine01/newwork/issues)
- **토론**: [GitHub Discussions](https://github.com/eightynine01/newwork/discussions)
- **문서**: [docs/](docs/)

## 📊 프로젝트 상태

현재 버전: **0.2.0** (개발 중)

이 프로젝트는 현재 활발하게 개발 중입니다. v1.0.0 릴리스 전까지는 API가 변경될 수 있습니다.

### 기술 스택

| 컴포넌트 | 기술 | 버전 |
|---------|------|------|
| 프론트엔드 | Flutter | 3.0+ |
| 백엔드 | FastAPI | 0.109+ |
| 데이터베이스 | SQLite | 3.0+ |
| 상태 관리 | Riverpod | 2.5+ |
| API 클라이언트 | Dio | 5.4+ |
| 패키징 | PyInstaller | 6.0+ |

---

**Made with ❤️ by the NewWork Team**
