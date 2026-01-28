# 멀티 스테이지 빌드
# Stage 1: Builder
FROM python:3.10-slim as builder

# 빌드 도구 설치
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*

# 작업 디렉토리 설정
WORKDIR /build

# 의존성 파일 복사
COPY requirements.txt .

# 의존성 설치 (wheels 생성)
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Runtime
FROM python:3.10-slim

# 보안: root가 아닌 사용자로 실행
RUN useradd -m -u 1000 openwork && \
    mkdir -p /app/data /app/logs && \
    chown -R openwork:openwork /app

# 작업 디렉토리 설정
WORKDIR /app

# builder stage에서 설치된 패키지 복사
COPY --from=builder /root/.local /home/openwork/.local

# 애플리케이션 코드 복사
COPY --chown=openwork:openwork app ./app

# PATH에 로컬 패키지 디렉토리 추가
ENV PATH=/home/openwork/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# 사용자 전환
USER openwork

# 포트 노출
EXPOSE 8000

# 헬스체크
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health', timeout=2)" || exit 1

# 실행
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
