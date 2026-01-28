# NewWork

> AI 기반 코딩 어시스턴트 - 통합 데스크톱 애플리케이션

<p align="center">
  <a href="README.md">English</a> |
  <a href="README.ko.md"><b>한국어</b></a> |
  <a href="README.zh-CN.md">简体中文</a> |
  <a href="README.ja.md">日本語</a>
</p>

[![GitHub stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/network/members)
[![GitHub watchers](https://img.shields.io/github/watchers/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/watchers)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Flutter](https://img.shields.io/badge/flutter-3.0+-blue.svg)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109+-green.svg)](https://fastapi.tiangolo.com/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

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

## 🔄 유사 프로젝트 비교

| 특성 | NewWork | [OpenWork](https://github.com/different-ai/openwork) | [Moltbot](https://github.com/moltbot/moltbot) |
|------|---------|----------|---------|
| ⭐ GitHub Stars | ![stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social) | ![stars](https://img.shields.io/github/stars/different-ai/openwork?style=social) | ![stars](https://img.shields.io/github/stars/moltbot/moltbot?style=social) |
| 🎯 핵심 목표 | 통합 데스크톱 앱 | 에이전트 워크플로우 | 개인 AI 어시스턴트 |
| 🖥️ 프론트엔드 | Flutter | SolidJS + TailwindCSS | Node.js CLI |
| ⚙️ 백엔드 | FastAPI (Python) | OpenCode CLI (spawned) | TypeScript |
| 📱 모바일 | ✅ (Flutter) | ❌ | ❌ |
| 🚀 설치 방식 | 단일 실행 파일 | DMG/소스 빌드 | CLI 설치 |

### 왜 NewWork인가?

1. **진정한 올인원**: 백엔드가 앱 안에 완전히 내장되어 별도 설정 불필요
2. **Flutter 기반**: 모바일 확장이 용이하고 Material Design 3 적용
3. **Python 백엔드**: 확장과 커스터마이징이 쉬운 FastAPI 아키텍처
4. **프라이버시 우선**: 모든 데이터가 로컬에 저장되며 외부 서버 불필요

## 🤝 기여하기

**모든 형태의 기여를 환영합니다!** 🎉

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

### 🌟 기여 방법

| 유형 | 설명 |
|------|------|
| 🐛 **버그 리포트** | 문제를 발견하셨나요? [이슈](https://github.com/eightynine01/newwork/issues/new?template=bug_report.md)를 열어주세요 |
| 💡 **기능 제안** | 아이디어가 있으시면 [제안](https://github.com/eightynine01/newwork/issues/new?template=feature_request.md)해주세요 |
| 📝 **문서 개선** | 오타 수정, 번역, 가이드 추가 모두 환영합니다 |
| 🔧 **코드 기여** | PR을 보내주세요! OpenCode 관련 PR 특히 환영합니다 |
| ⭐ **Star 주기** | 프로젝트가 마음에 드시면 Star를 눌러주세요! |

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

## 📄 라이센스

이 프로젝트는 MIT 라이센스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고해주세요.

## 📞 문의 및 지원

- **이슈 트래커**: [GitHub Issues](https://github.com/eightynine01/newwork/issues)
- **토론**: [GitHub Discussions](https://github.com/eightynine01/newwork/discussions)
- **문서**: [docs/](docs/)

---

**Made with ❤️ by the NewWork Team**
