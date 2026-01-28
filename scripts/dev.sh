#!/bin/bash
# NewWork 개발 서버 스크립트
# Flutter 앱과 백엔드를 연동하여 실행
# Flutter 앱이 종료되면 백엔드도 함께 종료됨

set -e

# 색상 정의
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 프로젝트 루트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# PID 저장용 변수
BACKEND_PID=""

# 정리 함수: 모든 자식 프로세스 종료
cleanup() {
    echo -e "\n${YELLOW}Shutting down NewWork...${NC}"

    # 백엔드 프로세스 종료
    if [ -n "$BACKEND_PID" ] && kill -0 "$BACKEND_PID" 2>/dev/null; then
        echo -e "${YELLOW}Stopping backend (PID: $BACKEND_PID)...${NC}"
        kill "$BACKEND_PID" 2>/dev/null || true
        wait "$BACKEND_PID" 2>/dev/null || true
    fi

    # 프로세스 그룹의 모든 자식 프로세스 종료
    pkill -P $$ 2>/dev/null || true

    echo -e "${GREEN}✓ NewWork stopped${NC}"
    exit 0
}

# 시그널 트랩 설정
trap cleanup SIGINT SIGTERM EXIT

# uv 설치 확인
if ! command -v uv &> /dev/null; then
    echo -e "${RED}Error: uv is not installed.${NC}"
    echo "Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

# Flutter 설치 확인
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter is not installed.${NC}"
    exit 1
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  NewWork Development Server${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 백엔드 서버 시작 (백그라운드)
echo -e "${GREEN}[1/2] Starting backend server...${NC}"
cd "$PROJECT_ROOT/newwork-backend"

# 가상환경이 없으면 생성
if [ ! -d ".venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    uv venv
fi

# 의존성 동기화
echo -e "${YELLOW}Syncing dependencies...${NC}"
uv sync --all-extras

# 백엔드 시작 (백그라운드에서 실행)
uv run uvicorn app.main:app --reload --host 127.0.0.1 --port 8000 &
BACKEND_PID=$!

echo -e "${GREEN}✓ Backend started (PID: $BACKEND_PID)${NC}"
echo -e "${GREEN}  API: http://127.0.0.1:8000${NC}"
echo -e "${GREEN}  Docs: http://127.0.0.1:8000/docs${NC}"
echo ""

# 백엔드가 시작될 때까지 대기
echo -e "${YELLOW}Waiting for backend to be ready...${NC}"
MAX_RETRIES=30
RETRY_COUNT=0
while ! curl -s http://127.0.0.1:8000/health > /dev/null 2>&1; do
    sleep 1
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo -e "${RED}Backend failed to start within ${MAX_RETRIES} seconds${NC}"
        cleanup
        exit 1
    fi
done
echo -e "${GREEN}✓ Backend is ready${NC}"
echo ""

# Flutter 앱 시작 (포어그라운드)
echo -e "${GREEN}[2/2] Starting Flutter app...${NC}"
cd "$PROJECT_ROOT/newwork-app"

# Flutter 의존성 설치
flutter pub get

echo -e "${GREEN}✓ Flutter dependencies installed${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Starting Flutter app (close app to stop all servers)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Flutter 앱 실행 (포어그라운드 - 이 프로세스가 종료되면 cleanup 호출됨)
flutter run -d macos

# Flutter가 종료되면 여기에 도달
# trap EXIT에 의해 cleanup이 자동 호출됨
