# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- [ ] 백엔드 프로세스 자동 관리 완성
- [ ] WebSocket 실시간 통신 강화
- [ ] Flutter UI 데이터 바인딩 완성
- [ ] 크로스 플랫폼 배포 파이프라인
- [ ] 자동 업데이트 시스템
- [ ] 템플릿 마켓플레이스
- [ ] 협업 기능
- [ ] 클라우드 백업 (선택사항)

## [0.2.0] - 2026-01-25

### 🎉 Major Changes - 통합 애플리케이션 아키텍처

#### 프로젝트 리브랜딩
- **OpenWork → NewWork** 전체 프로젝트 이름 변경
  - 프로젝트 정체성 재정립
  - 통합 애플리케이션 비전 명확화
  - 모든 문서 및 코드 업데이트

#### 디렉토리 구조 변경
- `openwork-python` → `newwork-backend`
- `openwork-flutter` → `newwork-app`
- `openwork-clone` → `newwork-reference`

### Added

#### 통합 아키텍처
- **단일 실행 파일**: Flutter UI + Python 백엔드 통합
- **백엔드 자동 관리**:
  - `BackendManager` 서비스 구현
  - 앱 시작 시 Python 백엔드 자동 시작
  - 앱 종료 시 백엔드 정리
  - 헬스 체크 및 재시작 로직

#### Python 백엔드 패키징
- **PyInstaller 통합**:
  - `newwork.spec` 스펙 파일
  - 크로스 플랫폼 빌드 스크립트
  - 단일 실행 파일 생성 (--onefile)
  - 의존성 자동 번들링

#### Flutter 앱 강화
- **의존성 추가**:
  - `dio: ^5.4.0` - 향상된 HTTP 클라이언트
  - `process_run: ^0.14.0` - 프로세스 관리
  - `google_fonts: ^6.1.0` - UI 폰트
  - `flutter_svg: ^2.0.9` - SVG 지원
  - `uuid: ^4.3.0` - UUID 생성

- **서비스 레이어**:
  - `BackendManager` - Python 백엔드 프로세스 관리
  - `ApiClient` - REST API 클라이언트 (Dio 기반)
  - `WebSocketService` - 실시간 통신 서비스

#### 빌드 시스템
- **크로스 플랫폼 빌드 스크립트**:
  - `scripts/build-all.sh` - 전체 플랫폼 빌드
  - `scripts/build-windows.ps1` - Windows 전용
  - `scripts/package-macos.sh` - macOS DMG 생성
  - `scripts/package-linux.sh` - Linux 패키지

- **Makefile 통합**:
  - 개발, 빌드, 테스트 명령어 통합
  - 병렬 개발 서버 실행
  - 클린 빌드 지원

#### 배포 설정
- **macOS**: DMG 패키지 + 샌드박스 해제
- **Linux**: AppImage + .deb 패키지
- **Windows**: Inno Setup 인스톨러

### Changed

#### 프로젝트 메타데이터
- **Python 백엔드** (`pyproject.toml`):
  - name: `newwork-backend`
  - version: `0.2.0`
  - description: "FastAPI backend for NewWork"
  - keywords 업데이트

- **Flutter 앱** (`pubspec.yaml`):
  - name: `newwork`
  - version: `0.2.0+1`
  - description: "NewWork - AI-powered coding assistant"

#### 데이터베이스 위치
- **OS별 표준 위치 사용**:
  - macOS: `~/Library/Application Support/NewWork/`
  - Linux: `~/.local/share/NewWork/`
  - Windows: `%APPDATA%\NewWork\`

#### 문서
- `README.md` - 통합 앱 아키텍처 반영
- `CONTRIBUTING.md` - 디렉토리 이름 업데이트
- `CHANGELOG.md` - v0.2.0 엔트리 추가

### Architecture

#### 새로운 통합 구조
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
```

### 🎯 릴리스 목표

**v0.2.0**은 **통합 애플리케이션의 기초**를 구축하는 것이 목표입니다:

- ✅ 프로젝트 리브랜딩 완료
- ✅ 통합 아키텍처 설계
- 🚧 Python 백엔드 패키징 (진행 중)
- 🚧 Flutter 백엔드 통합 (진행 중)
- 🚧 크로스 플랫폼 빌드 (진행 중)
- ⬜ 첫 릴리스 배포 (예정)

## [0.1.0] - 2026-01-25

### Added

#### 프로젝트 기반 구조
- 멀티 레포지토리 프로젝트 구조 (openwork-python, openwork-flutter, openwork-clone)
- MIT 라이센스 적용
- 기여 가이드라인 (CONTRIBUTING.md)
- 행동 강령 (CODE_OF_CONDUCT.md)
- 포괄적인 .gitignore 설정

#### 문서화
- 프로젝트 개요 및 빠른 시작 가이드 (README.md)
- 시스템 아키텍처 문서 (docs/architecture.md)
  - 3-tier 아키텍처 설명
  - 컴포넌트 간 통신 다이어그램
  - 데이터베이스 스키마 ERD
  - WebSocket 실시간 통신 설계
- API 레퍼런스 (docs/api.md)
  - RESTful API 엔드포인트 상세 설명
  - WebSocket API 이벤트 타입
  - 요청/응답 예제 (cURL, Python)
  - 에러 코드 정의
- 배포 가이드 (docs/deployment.md)
  - Docker 배포 방법
  - systemd/supervisord 수동 배포
  - Nginx/Traefik 리버스 프록시 설정
  - PostgreSQL 마이그레이션 가이드
  - 보안 및 성능 최적화
- 개발 가이드 (docs/development.md)
  - 개발 환경 설정 상세 가이드
  - 프로젝트 구조 설명
  - 디버깅 방법
  - 테스트 작성 가이드
  - 코드 스타일 가이드
- 문제 해결 가이드 (docs/troubleshooting.md)
  - 일반적인 문제 및 해결 방법
  - 백엔드/프론트엔드 문제
  - OpenCode 연결 문제
  - 성능 문제 진단 및 해결

#### Docker 설정
- 멀티 스테이지 Dockerfile (openwork-python)
  - 빌더 스테이지와 런타임 스테이지 분리
  - 보안을 위한 비 root 사용자 실행
  - 헬스체크 구현
- docker-compose.yml
  - 백엔드, PostgreSQL, Redis, Nginx 서비스 정의
  - 프로덕션 프로파일 지원
  - 볼륨 및 네트워크 설정
- .dockerignore 최적화
- .env.example 환경 변수 템플릿

#### CI/CD (GitHub Actions)
- 백엔드 테스트 워크플로우 (backend-test.yml)
  - Python 3.10, 3.11, 3.12 매트릭스 테스트
  - Black, isort, pylint, mypy 코드 품질 검사
  - pytest 단위 테스트 및 커버리지
  - Codecov 통합
  - Bandit 보안 검사
  - Safety 의존성 취약점 검사
- Flutter 테스트 워크플로우 (flutter-test.yml)
  - 포맷팅 검증 (dart format)
  - 정적 분석 (flutter analyze)
  - 단위 테스트 및 커버리지
  - 멀티 플랫폼 빌드 테스트 (Linux, macOS, Windows)
- Docker 빌드 워크플로우 (docker-build.yml)
  - GitHub Container Registry 푸시
  - 멀티 아키텍처 빌드 (amd64, arm64)
  - Trivy 보안 스캔
  - docker-compose 통합 테스트

#### GitHub 템플릿
- 버그 리포트 이슈 템플릿
- 기능 요청 이슈 템플릿
- Pull Request 템플릿
  - 변경사항 체크리스트
  - 테스트 확인 항목
  - 코드 품질 검증 항목

#### 백엔드 (openwork-python)
- FastAPI 프레임워크 기반 구조
- 기본 API 엔드포인트 스켈레톤
  - 세션 관리 API
  - 템플릿 API
  - 워크스페이스 API
  - 스킬 API
- SQLAlchemy 모델 정의
- Pydantic 스키마 정의
- 환경 설정 (Pydantic Settings)

#### 프론트엔드 (openwork-flutter)
- Flutter 3.16+ 기본 구조
- Riverpod 2.0 상태 관리 설정
- 기본 UI 컴포넌트 스켈레톤
  - 세션 페이지
  - 템플릿 관리
  - 설정 페이지

#### 레퍼런스 구현 (openwork-clone)
- Tauri + React 기본 구조
- TypeScript 설정
- Tailwind CSS 스타일링

### Changed
- Nothing yet

### Deprecated
- Nothing yet

### Removed
- Nothing yet

### Fixed
- Nothing yet

### Security
- Docker 컨테이너를 비 root 사용자로 실행
- .env 파일을 .gitignore에 추가
- GitHub Actions 시크릿을 통한 민감 정보 관리
- Trivy를 통한 Docker 이미지 보안 스캔

## 릴리스 노트

### v0.1.0 - 프로젝트 기반 구축 (2026-01-25)

OpenWork 프로젝트의 첫 번째 릴리스입니다. 이 버전은 오픈소스 배포를 위한 **기반 인프라**에 중점을 두었습니다.

**주요 성과:**
- ✅ 완전한 프로젝트 문서화
- ✅ Docker 기반 배포 시스템
- ✅ CI/CD 파이프라인 구축
- ✅ 프로젝트 구조 및 아키텍처 설계

**아직 구현되지 않은 기능:**
- ⚠️ OpenCode API 실제 통합
- ⚠️ 실시간 WebSocket 통신
- ⚠️ 데이터베이스 CRUD 로직
- ⚠️ Flutter UI 실제 구현
- ⚠️ 사용자 인증

**다음 릴리스 (v0.2.0) 계획:**
- 핵심 기능 구현 (세션 관리, OpenCode 통합)
- WebSocket 실시간 통신
- 기본 UI 컴포넌트 구현
- 테스트 커버리지 80% 달성

---

## 버전 관리 가이드

### Semantic Versioning

우리는 [Semantic Versioning](https://semver.org/)을 따릅니다:

- **MAJOR** (X.0.0): 호환성이 손상되는 API 변경
- **MINOR** (0.X.0): 하위 호환성이 있는 새 기능
- **PATCH** (0.0.X): 하위 호환성이 있는 버그 수정

### 변경 사항 카테고리

- **Added**: 새로운 기능
- **Changed**: 기존 기능의 변경
- **Deprecated**: 곧 제거될 기능
- **Removed**: 제거된 기능
- **Fixed**: 버그 수정
- **Security**: 보안 관련 변경

## 기여하기

변경사항을 이 파일에 추가하려면:

1. `[Unreleased]` 섹션의 적절한 카테고리에 변경사항 추가
2. 릴리스 시 메인테이너가 버전 번호와 날짜를 업데이트

자세한 내용은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참조하세요.
