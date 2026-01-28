#!/bin/bash
# NewWork Backend 빌드 스크립트 (macOS/Linux)

set -e  # 에러 발생 시 즉시 중단

echo "===== NewWork Backend Build Script ====="
echo "Platform: $(uname -s)"
echo "Python: $(python3 --version 2>&1 || echo 'Not found')"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수: 에러 메시지
error() {
    echo -e "${RED}✗ Error: $1${NC}" >&2
    exit 1
}

# 함수: 성공 메시지
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# 함수: 경고 메시지
warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Python 확인
if ! command -v python3 &> /dev/null; then
    error "Python 3 not found. Please install Python 3.10 or later."
fi

# PyInstaller 확인 및 설치
echo "Step 1: Checking PyInstaller..."
if ! python3 -m pip show pyinstaller &> /dev/null; then
    warning "PyInstaller not found. Installing..."
    python3 -m pip install pyinstaller || error "Failed to install PyInstaller"
fi
success "PyInstaller ready"

# 의존성 확인
echo ""
echo "Step 2: Checking dependencies..."
if [ ! -f "requirements.txt" ]; then
    error "requirements.txt not found"
fi

# 의존성 설치 (선택사항 - 이미 설치되어 있을 수 있음)
read -p "Install/update dependencies from requirements.txt? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    python3 -m pip install -r requirements.txt || error "Failed to install dependencies"
    success "Dependencies installed"
else
    warning "Skipping dependency installation"
fi

# 이전 빌드 정리
echo ""
echo "Step 3: Cleaning previous builds..."
rm -rf build/ dist/ *.spec.bak
success "Cleaned"

# PyInstaller 빌드
echo ""
echo "Step 4: Building with PyInstaller..."
if [ ! -f "newwork.spec" ]; then
    error "newwork.spec not found"
fi

python3 -m PyInstaller newwork.spec --clean --noconfirm || error "Build failed"
success "Build completed"

# 빌드 결과 확인
echo ""
echo "Step 5: Verifying build..."
PLATFORM=$(uname -s)
if [ "$PLATFORM" = "Darwin" ] || [ "$PLATFORM" = "Linux" ]; then
    EXECUTABLE="dist/newwork-backend"
elif [ "$PLATFORM" = "MINGW"* ] || [ "$PLATFORM" = "MSYS"* ]; then
    EXECUTABLE="dist/newwork-backend.exe"
else
    warning "Unknown platform: $PLATFORM"
    EXECUTABLE="dist/newwork-backend"
fi

if [ -f "$EXECUTABLE" ]; then
    FILE_SIZE=$(du -h "$EXECUTABLE" | cut -f1)
    success "Executable found: $EXECUTABLE (${FILE_SIZE})"

    # 실행 권한 설정 (Unix 계열)
    if [ "$PLATFORM" = "Darwin" ] || [ "$PLATFORM" = "Linux" ]; then
        chmod +x "$EXECUTABLE"
        success "Executable permissions set"
    fi
else
    error "Executable not found: $EXECUTABLE"
fi

# 완료
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✓ Build Successful!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Output: $EXECUTABLE"
echo ""
echo "To test the backend:"
echo "  $EXECUTABLE --host 127.0.0.1 --port 8000"
echo ""
