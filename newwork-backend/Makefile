.PHONY: help install dev test lint format clean migration db-upgrade db-downgrade docker-build docker-run

# 색상 정의
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# 기본 타겟
help: ## 사용 가능한 명령어 표시
	@echo "$(BLUE)OpenWork Python Backend - Available Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

# 설치 및 설정
install: ## 의존성 설치
	@echo "$(BLUE)Installing dependencies...$(NC)"
	pip install -r requirements.txt
	pip install -e ".[dev]"
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

install-uv: ## UV를 사용하여 의존성 설치
	@echo "$(BLUE)Installing dependencies with UV...$(NC)"
	uv pip install -r requirements.txt
	uv pip install -e ".[dev]"
	@echo "$(GREEN)✓ Dependencies installed with UV$(NC)"

install-hooks: ## Pre-commit hooks 설치
	@echo "$(BLUE)Installing pre-commit hooks...$(NC)"
	pre-commit install
	@echo "$(GREEN)✓ Pre-commit hooks installed$(NC)"

setup: install install-hooks ## 전체 개발 환경 설정
	@echo "$(GREEN)✓ Development environment ready$(NC)"

# 개발 서버
dev: ## 개발 서버 실행 (auto-reload)
	@echo "$(BLUE)Starting development server...$(NC)"
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

dev-debug: ## 디버그 모드로 개발 서버 실행
	@echo "$(BLUE)Starting development server in debug mode...$(NC)"
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 --log-level debug

# 테스트
test: ## 모든 테스트 실행
	@echo "$(BLUE)Running tests...$(NC)"
	pytest tests/ -v

test-cov: ## 커버리지와 함께 테스트 실행
	@echo "$(BLUE)Running tests with coverage...$(NC)"
	pytest tests/ --cov=app --cov-report=html --cov-report=term-missing -v
	@echo "$(GREEN)✓ Coverage report: htmlcov/index.html$(NC)"

test-unit: ## 단위 테스트만 실행
	@echo "$(BLUE)Running unit tests...$(NC)"
	pytest tests/ -m unit -v

test-integration: ## 통합 테스트만 실행
	@echo "$(BLUE)Running integration tests...$(NC)"
	pytest tests/ -m integration -v

test-watch: ## Watch 모드로 테스트 실행
	@echo "$(BLUE)Running tests in watch mode...$(NC)"
	pytest-watch

# 코드 품질
lint: ## Ruff로 린트 검사
	@echo "$(BLUE)Running linter...$(NC)"
	ruff check app/ tests/
	@echo "$(GREEN)✓ Lint check passed$(NC)"

lint-fix: ## Ruff로 자동 수정 가능한 문제 수정
	@echo "$(BLUE)Fixing lint issues...$(NC)"
	ruff check --fix app/ tests/
	@echo "$(GREEN)✓ Lint issues fixed$(NC)"

format: ## Ruff로 코드 포맷팅
	@echo "$(BLUE)Formatting code...$(NC)"
	ruff format app/ tests/
	@echo "$(GREEN)✓ Code formatted$(NC)"

format-check: ## 포맷팅 검사 (수정하지 않음)
	@echo "$(BLUE)Checking code formatting...$(NC)"
	ruff format --check app/ tests/

typecheck: ## MyPy로 타입 체크
	@echo "$(BLUE)Running type checker...$(NC)"
	mypy app/
	@echo "$(GREEN)✓ Type check passed$(NC)"

security: ## Bandit으로 보안 검사
	@echo "$(BLUE)Running security check...$(NC)"
	bandit -r app/ -ll
	@echo "$(GREEN)✓ Security check passed$(NC)"

safety: ## Safety로 의존성 취약점 검사
	@echo "$(BLUE)Checking dependencies for vulnerabilities...$(NC)"
	safety check --json
	@echo "$(GREEN)✓ No vulnerabilities found$(NC)"

quality: lint typecheck security ## 모든 코드 품질 검사 실행
	@echo "$(GREEN)✓ All quality checks passed$(NC)"

pre-commit: ## Pre-commit hooks 수동 실행
	@echo "$(BLUE)Running pre-commit hooks...$(NC)"
	pre-commit run --all-files

# 데이터베이스
migration: ## 새 마이그레이션 생성
	@echo "$(BLUE)Creating new migration...$(NC)"
	@read -p "Enter migration message: " msg; \
	alembic revision --autogenerate -m "$$msg"
	@echo "$(GREEN)✓ Migration created$(NC)"

db-upgrade: ## 데이터베이스 마이그레이션 적용
	@echo "$(BLUE)Applying database migrations...$(NC)"
	alembic upgrade head
	@echo "$(GREEN)✓ Database upgraded$(NC)"

db-downgrade: ## 마지막 마이그레이션 롤백
	@echo "$(BLUE)Rolling back last migration...$(NC)"
	alembic downgrade -1
	@echo "$(GREEN)✓ Database downgraded$(NC)"

db-current: ## 현재 데이터베이스 버전 확인
	@echo "$(BLUE)Current database version:$(NC)"
	alembic current

db-history: ## 마이그레이션 히스토리 확인
	@echo "$(BLUE)Migration history:$(NC)"
	alembic history

db-reset: ## 데이터베이스 초기화 (주의!)
	@echo "$(RED)⚠️  This will delete all data!$(NC)"
	@read -p "Are you sure? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		rm -f data/*.db; \
		alembic upgrade head; \
		echo "$(GREEN)✓ Database reset$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

# Docker
docker-build: ## Docker 이미지 빌드
	@echo "$(BLUE)Building Docker image...$(NC)"
	docker build -t openwork/backend:latest .
	@echo "$(GREEN)✓ Docker image built$(NC)"

docker-run: ## Docker 컨테이너 실행
	@echo "$(BLUE)Running Docker container...$(NC)"
	docker run -p 8000:8000 --env-file ../.env openwork/backend:latest

docker-compose-up: ## docker-compose로 서비스 시작
	@echo "$(BLUE)Starting services with docker-compose...$(NC)"
	cd .. && docker-compose up -d backend
	@echo "$(GREEN)✓ Services started$(NC)"

docker-compose-down: ## docker-compose로 서비스 중지
	@echo "$(BLUE)Stopping services...$(NC)"
	cd .. && docker-compose down
	@echo "$(GREEN)✓ Services stopped$(NC)"

docker-logs: ## Docker 로그 확인
	cd .. && docker-compose logs -f backend

# 클린업
clean: ## 캐시 및 빌드 파일 정리
	@echo "$(BLUE)Cleaning up...$(NC)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type f -name "*.pyo" -delete 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache .coverage htmlcov .mypy_cache .ruff_cache 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

clean-all: clean ## 모든 캐시, 빌드, 가상환경 정리
	@echo "$(BLUE)Cleaning everything...$(NC)"
	rm -rf venv .venv
	@echo "$(GREEN)✓ Full cleanup complete$(NC)"

# 유틸리티
check: lint typecheck test ## 린트, 타입 체크, 테스트 실행
	@echo "$(GREEN)✓ All checks passed$(NC)"

ci: ## CI에서 실행할 검사
	@echo "$(BLUE)Running CI checks...$(NC)"
	@$(MAKE) format-check
	@$(MAKE) lint
	@$(MAKE) typecheck
	@$(MAKE) security
	@$(MAKE) test-cov
	@echo "$(GREEN)✓ CI checks passed$(NC)"

requirements: ## requirements.txt 업데이트
	@echo "$(BLUE)Updating requirements.txt...$(NC)"
	pip freeze > requirements.txt
	@echo "$(GREEN)✓ requirements.txt updated$(NC)"

shell: ## Python 대화형 셸 실행
	@echo "$(BLUE)Starting Python shell...$(NC)"
	python -i -c "from app.main import app; from app.db.database import SessionLocal; db = SessionLocal()"

.DEFAULT_GOAL := help
