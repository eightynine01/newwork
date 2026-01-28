.PHONY: help dev dev-backend dev-frontend build-backend build-frontend build-all clean test lint format install sync

# 기본 타겟
.DEFAULT_GOAL := help

# 색상
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# uv가 설치되어 있는지 확인
UV := $(shell command -v uv 2> /dev/null)

help: ## 도움말 표시
	@echo "$(BLUE)NewWork - Available Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

# ==================== 개발 ====================

dev: check-uv ## 개발 모드 실행 (백엔드 + 프론트엔드 연동, Flutter 종료시 백엔드도 종료)
	@echo "$(BLUE)Starting development servers (linked)...$(NC)"
	@./scripts/dev.sh

dev-backend: check-uv ## 백엔드 개발 서버 실행 (단독)
	@echo "$(GREEN)Starting backend server...$(NC)"
	@cd newwork-backend && uv run uvicorn app.main:app --reload --host 127.0.0.1 --port 8000

dev-frontend: ## 프론트엔드 개발 서버 실행 (단독)
	@echo "$(GREEN)Starting Flutter app...$(NC)"
	@cd newwork-app && flutter run -d macos

# ==================== 의존성 관리 (uv) ====================

check-uv:
ifndef UV
	@echo "$(RED)Error: uv is not installed.$(NC)"
	@echo "Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
	@exit 1
endif

install: check-uv ## 모든 의존성 설치 (uv sync)
	@echo "$(BLUE)Installing dependencies with uv...$(NC)"
	@echo "$(YELLOW)Backend dependencies...$(NC)"
	@cd newwork-backend && uv sync --all-extras
	@echo "$(YELLOW)Frontend dependencies...$(NC)"
	@cd newwork-app && flutter pub get
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

sync: check-uv ## 백엔드 의존성 동기화 (lock 파일 업데이트)
	@echo "$(BLUE)Syncing backend dependencies...$(NC)"
	@cd newwork-backend && uv sync --all-extras
	@echo "$(GREEN)✓ Dependencies synced$(NC)"

add: check-uv ## 패키지 추가 (예: make add PKG=requests)
	@if [ -z "$(PKG)" ]; then \
		echo "$(RED)Error: PKG is required. Usage: make add PKG=package_name$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Adding $(PKG)...$(NC)"
	@cd newwork-backend && uv add $(PKG)

add-dev: check-uv ## 개발 패키지 추가 (예: make add-dev PKG=pytest)
	@if [ -z "$(PKG)" ]; then \
		echo "$(RED)Error: PKG is required. Usage: make add-dev PKG=package_name$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Adding $(PKG) as dev dependency...$(NC)"
	@cd newwork-backend && uv add --dev $(PKG)

# ==================== 빌드 ====================

build-backend: check-uv ## Python 백엔드 빌드
	@echo "$(BLUE)Building Python backend...$(NC)"
	@cd newwork-backend && uv build
	@echo "$(GREEN)✓ Backend built$(NC)"

build-frontend: ## Flutter 앱 빌드 (현재 플랫폼)
	@echo "$(BLUE)Building Flutter app...$(NC)"
	@cd newwork-app && flutter build macos --release
	@echo "$(GREEN)✓ Frontend built$(NC)"

build-all: check-uv ## 전체 빌드 (백엔드 + 프론트엔드 통합)
	@echo "$(BLUE)Building NewWork (all platforms)...$(NC)"
	@./scripts/build-all.sh
	@echo "$(GREEN)✓ Build complete$(NC)"

build-macos: ## macOS 빌드
	@echo "$(BLUE)Building for macOS...$(NC)"
	@cd newwork-app && flutter build macos --release
	@echo "$(GREEN)✓ macOS build complete$(NC)"

build-linux: ## Linux 빌드
	@echo "$(BLUE)Building for Linux...$(NC)"
	@cd newwork-app && flutter build linux --release
	@echo "$(GREEN)✓ Linux build complete$(NC)"

build-windows: ## Windows 빌드
	@echo "$(BLUE)Building for Windows...$(NC)"
	@cd newwork-app && flutter build windows --release
	@echo "$(GREEN)✓ Windows build complete$(NC)"

# ==================== 테스트 ====================

test: check-uv ## 전체 테스트 실행
	@echo "$(BLUE)Running tests...$(NC)"
	@$(MAKE) test-backend
	@$(MAKE) test-frontend
	@echo "$(GREEN)✓ All tests passed$(NC)"

test-backend: check-uv ## 백엔드 테스트
	@echo "$(YELLOW)Testing backend...$(NC)"
	@cd newwork-backend && uv run pytest tests/ -v

test-unit: check-uv ## 단위 테스트만 실행
	@echo "$(YELLOW)Running unit tests...$(NC)"
	@cd newwork-backend && uv run pytest tests/ -m "unit" -v

test-integration: check-uv ## 통합 테스트만 실행
	@echo "$(YELLOW)Running integration tests...$(NC)"
	@cd newwork-backend && uv run pytest tests/ -m "integration" -v

test-e2e: check-uv ## E2E 테스트만 실행
	@echo "$(YELLOW)Running E2E tests...$(NC)"
	@cd newwork-backend && uv run pytest tests/e2e/ -v

test-coverage: check-uv ## 커버리지 리포트 생성
	@echo "$(YELLOW)Running tests with coverage...$(NC)"
	@cd newwork-backend && uv run pytest tests/ --cov=app --cov-report=html --cov-report=term-missing
	@echo "$(GREEN)Coverage report: newwork-backend/htmlcov/index.html$(NC)"

test-frontend: ## 프론트엔드 테스트
	@echo "$(YELLOW)Testing frontend...$(NC)"
	@cd newwork-app && flutter test

# ==================== 코드 품질 ====================

lint: check-uv ## 코드 린트
	@echo "$(BLUE)Linting code...$(NC)"
	@$(MAKE) lint-backend
	@$(MAKE) lint-frontend
	@echo "$(GREEN)✓ Lint complete$(NC)"

lint-backend: check-uv ## 백엔드 린트 (Ruff + MyPy)
	@echo "$(YELLOW)Linting backend with ruff...$(NC)"
	@cd newwork-backend && uv run ruff check app/
	@echo "$(YELLOW)Type checking with mypy...$(NC)"
	@cd newwork-backend && uv run mypy app/ --ignore-missing-imports || true

lint-frontend: ## 프론트엔드 린트 (Dart)
	@echo "$(YELLOW)Linting frontend...$(NC)"
	@cd newwork-app && flutter analyze

format: check-uv ## 코드 포맷팅
	@echo "$(BLUE)Formatting code...$(NC)"
	@$(MAKE) format-backend
	@$(MAKE) format-frontend
	@echo "$(GREEN)✓ Format complete$(NC)"

format-backend: check-uv ## 백엔드 포맷팅 (Ruff)
	@echo "$(YELLOW)Formatting backend...$(NC)"
	@cd newwork-backend && uv run ruff format app/
	@cd newwork-backend && uv run ruff check --fix app/

format-frontend: ## 프론트엔드 포맷팅 (Dart)
	@echo "$(YELLOW)Formatting frontend...$(NC)"
	@cd newwork-app && dart format lib/

check: check-uv ## 코드 품질 전체 검사 (lint + format check)
	@echo "$(BLUE)Running all code quality checks...$(NC)"
	@cd newwork-backend && uv run ruff check app/
	@cd newwork-backend && uv run ruff format --check app/
	@cd newwork-backend && uv run mypy app/ --ignore-missing-imports || true
	@cd newwork-app && flutter analyze
	@echo "$(GREEN)✓ All checks passed$(NC)"

# ==================== 정리 ====================

clean: ## 빌드 산출물 정리
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	@cd newwork-backend && rm -rf build/ dist/ *.egg-info __pycache__ .pytest_cache .ruff_cache .mypy_cache
	@cd newwork-app && flutter clean
	@rm -rf newwork-app/assets/backend/
	@echo "$(GREEN)✓ Clean complete$(NC)"

clean-all: clean ## 전체 정리 (의존성 포함)
	@echo "$(YELLOW)Cleaning all (including dependencies)...$(NC)"
	@cd newwork-backend && rm -rf .venv/ venv/
	@echo "$(GREEN)✓ Clean all complete$(NC)"

# ==================== 유틸리티 ====================

run: build-all ## 빌드 후 실행
	@echo "$(BLUE)Running NewWork...$(NC)"
	@open newwork-app/build/macos/Build/Products/Release/newwork.app

version: ## 버전 정보 표시
	@echo "$(BLUE)NewWork Version Information$(NC)"
	@echo ""
	@echo "Backend:"
	@cd newwork-backend && uv run python -c "import tomllib; print('  Version:', tomllib.load(open('pyproject.toml', 'rb'))['project']['version'])"
	@echo ""
	@echo "Frontend:"
	@cd newwork-app && grep '^version:' pubspec.yaml | sed 's/version: /  Version: /'
	@echo ""
	@echo "Tools:"
	@echo "  Python: $$(python3 --version 2>&1 | cut -d' ' -f2)"
	@echo "  uv: $$(uv --version 2>&1 | cut -d' ' -f2)"
	@echo "  Flutter: $$(flutter --version | head -1 | cut -d' ' -f2)"

status: ## 프로젝트 상태 확인
	@echo "$(BLUE)NewWork Project Status$(NC)"
	@echo ""
	@echo "Dependencies:"
	@if [ -f "newwork-backend/uv.lock" ]; then \
		echo "  ✓ Backend dependencies locked (uv.lock)"; \
	else \
		echo "  ✗ Backend dependencies not locked (run 'make install')"; \
	fi
	@echo ""
	@echo "Backend:"
	@if [ -d "newwork-backend/.venv" ]; then \
		echo "  ✓ Virtual environment exists"; \
	else \
		echo "  ✗ Virtual environment not created (run 'make install')"; \
	fi
	@echo ""
	@echo "Frontend:"
	@if [ -d "newwork-app/build/macos/Build/Products/Release/newwork.app" ]; then \
		echo "  ✓ macOS app built"; \
	else \
		echo "  ✗ macOS app not built"; \
	fi

setup: check-uv ## 초기 설정 (uv 및 의존성 설치)
	@echo "$(BLUE)Setting up NewWork development environment...$(NC)"
	@$(MAKE) install
	@echo "$(GREEN)✓ Setup complete$(NC)"
	@echo ""
	@echo "Run '$(GREEN)make dev$(NC)' to start development servers"
