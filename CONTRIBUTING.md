# 기여 가이드

NewWork 프로젝트에 관심을 가져주셔서 감사합니다! 이 문서는 프로젝트에 기여하는 방법을 안내합니다.

## 목차

- [개발 환경 설정](#개발-환경-설정)
- [브랜치 전략](#브랜치-전략)
- [커밋 컨벤션](#커밋-컨벤션)
- [Pull Request 프로세스](#pull-request-프로세스)
- [코딩 스타일](#코딩-스타일)
- [테스트 요구사항](#테스트-요구사항)

## 개발 환경 설정

### 백엔드 (newwork-backend)

```bash
cd newwork-backend

# Python 3.10 이상 필요
python --version

# 가상환경 생성 및 활성화
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# 개발 서버 실행
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 프론트엔드 (newwork-app)

```bash
cd newwork-app

# Flutter 3.16.0 이상 필요
flutter --version

# 의존성 설치
flutter pub get

# 개발 서버 실행 (데스크톱)
flutter run -d macos  # 또는 linux, windows
```

### 레퍼런스 구현 (newwork-reference)

```bash
cd newwork-reference

# Node.js 18 이상 필요
node --version

# 의존성 설치
npm install

# 개발 서버 실행
npm run tauri dev
```

## 브랜치 전략

우리는 Git Flow 기반 브랜치 전략을 사용합니다:

- **`main`**: 프로덕션 릴리스 브랜치 (항상 안정적)
- **`develop`**: 개발 통합 브랜치
- **`feature/*`**: 새 기능 개발 (예: `feature/add-template-system`)
- **`bugfix/*`**: 버그 수정 (예: `bugfix/fix-session-crash`)
- **`hotfix/*`**: 긴급 프로덕션 수정
- **`release/*`**: 릴리스 준비 브랜치

### 브랜치 생성 예시

```bash
# 새 기능 개발
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name

# 버그 수정
git checkout develop
git pull origin develop
git checkout -b bugfix/your-bug-description
```

## 커밋 컨벤션

우리는 [Conventional Commits](https://www.conventionalcommits.org/) 형식을 따릅니다:

```
<타입>(<범위>): <제목>

<본문>

<푸터>
```

### 타입

- **feat**: 새로운 기능
- **fix**: 버그 수정
- **docs**: 문서 변경
- **style**: 코드 포맷팅 (기능 변경 없음)
- **refactor**: 코드 리팩토링
- **test**: 테스트 추가/수정
- **chore**: 빌드, 설정 등의 변경

### 예시

```bash
# 좋은 커밋 메시지
git commit -m "feat(session): WebSocket 실시간 통신 추가"
git commit -m "fix(api): 세션 생성 시 null 체크 누락 수정"
git commit -m "docs(readme): 설치 가이드 업데이트"

# 나쁜 커밋 메시지
git commit -m "update"
git commit -m "fix bug"
git commit -m "WIP"
```

## Pull Request 프로세스

1. **Fork & Clone**

```bash
# 저장소 Fork 후
git clone https://github.com/YOUR-USERNAME/openwork.git
cd openwork
git remote add upstream https://github.com/openwork/openwork.git
```

2. **브랜치 생성 및 작업**

```bash
git checkout -b feature/amazing-feature
# 코드 작성...
```

3. **코드 작성 및 테스트**

```bash
# Python 프로젝트
cd newwork-backend
pytest tests/

# Flutter 프로젝트
cd newwork-app
flutter test
```

4. **Lint & Format 실행**

```bash
# Python
black app/ tests/
isort app/ tests/
pylint app/ tests/

# Flutter
dart format lib/ test/
flutter analyze
```

5. **커밋 및 푸시**

```bash
git add .
git commit -m "feat(component): 새로운 기능 추가"
git push origin feature/amazing-feature
```

6. **Pull Request 생성**

GitHub에서 PR을 생성하고 템플릿에 따라 내용을 작성합니다.

7. **코드 리뷰 대응**

리뷰어의 피드백에 응답하고 필요한 변경사항을 반영합니다.

## 코딩 스타일

### Python (newwork-backend)

- **Formatter**: [Black](https://black.readthedocs.io/)
- **Import Sorter**: [isort](https://pycqa.github.io/isort/)
- **Linter**: [pylint](https://pylint.org/)
- **Type Checker**: [mypy](https://mypy.readthedocs.io/)

**설정 예시**:

```python
# 최대 라인 길이: 100
# 타입 힌트 권장
# Docstring: Google 스타일

def create_session(
    workspace_path: str,
    model: str | None = None,
) -> dict[str, Any]:
    """새 세션을 생성합니다.

    Args:
        workspace_path: 작업 디렉토리 경로
        model: 사용할 AI 모델 (선택사항)

    Returns:
        생성된 세션 정보 딕셔너리

    Raises:
        ValueError: 잘못된 경로가 제공된 경우
    """
    # 구현...
```

### Dart/Flutter (newwork-app)

- **Formatter**: `dart format`
- **Analyzer**: `flutter analyze`
- **Linter**: [very_good_analysis](https://pub.dev/packages/very_good_analysis)

**설정 예시**:

```dart
// 최대 라인 길이: 80
// single quotes 사용
// trailing commas 권장

class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({
    required this.sessionId,
    super.key,
  });

  final String sessionId;

  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}
```

### TypeScript/React (newwork-reference)

- **Formatter**: [Prettier](https://prettier.io/)
- **Linter**: [ESLint](https://eslint.org/)

**설정 예시**:

```typescript
// 세미콜론 사용
// single quotes
// 2 spaces 들여쓰기

interface SessionProps {
  sessionId: string;
  onClose?: () => void;
}

export const SessionPage: React.FC<SessionProps> = ({ sessionId, onClose }) => {
  // 구현...
};
```

## 테스트 요구사항

### 필수 사항

- **새 기능**: 단위 테스트 필수
- **버그 수정**: 재현 테스트 추가
- **API 변경**: 통합 테스트 업데이트

### 테스트 커버리지

- 목표: **80% 이상**
- 핵심 비즈니스 로직: **90% 이상**

### Python 테스트 예시

```python
# tests/test_session.py
import pytest
from app.services.session import SessionService

@pytest.mark.asyncio
async def test_create_session():
    """세션 생성 테스트"""
    service = SessionService()
    session = await service.create_session(
        workspace_path="/tmp/test",
        model="claude-3-opus",
    )

    assert session["id"] is not None
    assert session["workspace_path"] == "/tmp/test"
    assert session["model"] == "claude-3-opus"
```

### Flutter 테스트 예시

```dart
// test/session_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:openwork/features/session/session_page.dart';

void main() {
  testWidgets('세션 페이지 렌더링 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SessionPage(sessionId: 'test-123'),
      ),
    );

    expect(find.text('test-123'), findsOneWidget);
  });
}
```

## 도움이 필요하신가요?

- **GitHub Issues**: 버그 리포트, 기능 제안
- **GitHub Discussions**: 일반 질문, 아이디어 공유
- **Discord** (향후 개설 예정): 실시간 채팅

## 행동 강령

모든 기여자는 [Code of Conduct](CODE_OF_CONDUCT.md)를 준수해야 합니다.

---

다시 한 번 기여에 감사드립니다! 🎉
