#!/bin/bash
# NewWork 크로스 플랫폼 빌드 스크립트
# uv를 사용한 Python 의존성 관리

set -e  # 에러 발생 시 즉시 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}===== NewWork Build Script =====${NC}"
echo "Platform: $(uname -s)"
echo "Date: $(date)"
echo ""

# 함수: 에러 메시지
error() {
    echo -e "${RED}✗ Error: $1${NC}" >&2
    exit 1
}

# 함수: 성공 메시지
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# 함수: 섹션 헤더
section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 프로젝트 루트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 플랫폼 감지
PLATFORM=$(uname -s)
case "$PLATFORM" in
    Darwin)
        BUILD_TARGET="macos"
        BACKEND_EXEC="newwork-backend"
        ;;
    Linux)
        BUILD_TARGET="linux"
        BACKEND_EXEC="newwork-backend"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        BUILD_TARGET="windows"
        BACKEND_EXEC="newwork-backend.exe"
        ;;
    *)
        error "Unsupported platform: $PLATFORM"
        ;;
esac

echo "Build target: $BUILD_TARGET"
echo ""

# uv 확인
if ! command -v uv &> /dev/null; then
    error "uv not found. Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
fi

echo "uv version: $(uv --version)"

# ==================== Step 1: Python 백엔드 빌드 ====================

section "Step 1: Building Python Backend"

cd "$PROJECT_ROOT/newwork-backend"

# Python 확인
if ! command -v python3 &> /dev/null; then
    error "Python 3 not found. Please install Python 3.10 or later."
fi

echo "Python version: $(python3 --version)"

# uv 가상환경 설정 및 의존성 동기화
echo "Syncing dependencies with uv..."
uv sync --all-extras || error "Failed to sync dependencies"

# PyInstaller 설치 (필요시)
if ! uv run python -c "import PyInstaller" 2>/dev/null; then
    echo "Installing PyInstaller..."
    uv add --dev pyinstaller || error "Failed to install PyInstaller"
fi

# 빌드
echo "Building backend with PyInstaller..."
uv run python -m PyInstaller newwork.spec --clean --noconfirm || error "Backend build failed"

# 빌드 결과 확인
if [ -f "dist/$BACKEND_EXEC" ]; then
    FILE_SIZE=$(du -h "dist/$BACKEND_EXEC" | cut -f1)
    success "Backend built: dist/$BACKEND_EXEC (${FILE_SIZE})"
else
    error "Backend executable not found: dist/$BACKEND_EXEC"
fi

cd "$PROJECT_ROOT"

# ==================== Step 2: Flutter 앱 준비 ====================

section "Step 2: Preparing Flutter App"

cd "$PROJECT_ROOT/newwork-app"

# Flutter 확인
if ! command -v flutter &> /dev/null; then
    error "Flutter not found. Please install Flutter 3.0 or later."
fi

echo "Flutter version: $(flutter --version | head -1)"

# 의존성 설치
echo "Installing Flutter dependencies..."
flutter pub get || error "Failed to get Flutter dependencies"

# 백엔드 바이너리를 Flutter assets로 복사
echo "Copying backend to Flutter assets..."
mkdir -p assets/backend

if [ -f "$PROJECT_ROOT/newwork-backend/dist/$BACKEND_EXEC" ]; then
    cp "$PROJECT_ROOT/newwork-backend/dist/$BACKEND_EXEC" "assets/backend/" || error "Failed to copy backend"
    success "Backend copied to assets/backend/"
else
    error "Backend executable not found"
fi

# ==================== Step 3: Flutter 앱 빌드 ====================

section "Step 3: Building Flutter App ($BUILD_TARGET)"

case "$BUILD_TARGET" in
    macos)
        echo "Building for macOS..."
        flutter build macos --release || error "macOS build failed"

        # 백엔드를 앱 번들에 복사
        APP_BUNDLE="build/macos/Build/Products/Release/newwork.app"
        BACKEND_DIR="$APP_BUNDLE/Contents/Resources/backend"

        echo "Installing backend to app bundle..."
        mkdir -p "$BACKEND_DIR"
        cp "assets/backend/$BACKEND_EXEC" "$BACKEND_DIR/" || error "Failed to install backend to app bundle"
        chmod +x "$BACKEND_DIR/$BACKEND_EXEC"

        success "macOS app built: $APP_BUNDLE"
        ;;

    linux)
        echo "Building for Linux..."
        flutter build linux --release || error "Linux build failed"

        # 백엔드를 번들에 복사
        BUNDLE_DIR="build/linux/x64/release/bundle"
        BACKEND_DIR="$BUNDLE_DIR/data/flutter_assets/backend"

        echo "Installing backend to bundle..."
        mkdir -p "$BACKEND_DIR"
        cp "assets/backend/$BACKEND_EXEC" "$BACKEND_DIR/" || error "Failed to install backend to bundle"
        chmod +x "$BACKEND_DIR/$BACKEND_EXEC"

        success "Linux app built: $BUNDLE_DIR"
        ;;

    windows)
        echo "Building for Windows..."
        flutter build windows --release || error "Windows build failed"

        # 백엔드를 번들에 복사
        BUNDLE_DIR="build/windows/runner/Release"
        BACKEND_DIR="$BUNDLE_DIR/data/flutter_assets/backend"

        echo "Installing backend to bundle..."
        mkdir -p "$BACKEND_DIR"
        cp "assets/backend/$BACKEND_EXEC" "$BACKEND_DIR/" || error "Failed to install backend to bundle"

        success "Windows app built: $BUNDLE_DIR"
        ;;
esac

cd "$PROJECT_ROOT"

# ==================== 완료 ====================

section "Build Complete!"

echo -e "${GREEN}✓ NewWork build successful!${NC}"
echo ""
echo "Build artifacts:"

case "$BUILD_TARGET" in
    macos)
        echo "  📦 macOS: newwork-app/build/macos/Build/Products/Release/newwork.app"
        echo ""
        echo "To test:"
        echo "  open newwork-app/build/macos/Build/Products/Release/newwork.app"
        ;;
    linux)
        echo "  📦 Linux: newwork-app/build/linux/x64/release/bundle/"
        echo ""
        echo "To test:"
        echo "  ./newwork-app/build/linux/x64/release/bundle/newwork"
        ;;
    windows)
        echo "  📦 Windows: newwork-app\\build\\windows\\runner\\Release\\"
        echo ""
        echo "To test:"
        echo "  .\\newwork-app\\build\\windows\\runner\\Release\\newwork.exe"
        ;;
esac

echo ""
