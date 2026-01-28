# 배포 가이드

이 문서는 OpenWork를 프로덕션 환경에 배포하는 방법을 설명합니다.

## 목차

- [Docker 배포](#docker-배포)
- [수동 배포](#수동-배포)
- [환경 변수](#환경-변수)
- [데이터베이스 마이그레이션](#데이터베이스-마이그레이션)
- [리버스 프록시 설정](#리버스-프록시-설정)
- [모니터링](#모니터링)
- [보안 고려사항](#보안-고려사항)

## Docker 배포

Docker를 사용한 배포가 가장 간단하고 권장됩니다.

### 사전 요구사항

- Docker 20.10+
- Docker Compose 2.0+
- OpenCode CLI 설치 및 설정

### 빠른 시작

```bash
# 저장소 클론
git clone https://github.com/yourusername/openwork.git
cd openwork

# 환경 변수 설정
cp .env.example .env
nano .env  # 필요한 값 수정

# 컨테이너 빌드 및 실행
docker-compose up -d

# 로그 확인
docker-compose logs -f backend
```

### docker-compose.yml 구성

```yaml
version: '3.8'

services:
  backend:
    build: ./openwork-python
    ports:
      - "8000:8000"
    environment:
      - DEBUG=False
      - DATABASE_URL=postgresql://user:password@postgres:5432/openwork
      - OPENCODE_URL=${OPENCODE_URL:-http://localhost:8080}
      - SECRET_KEY=${SECRET_KEY}
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
    restart: unless-stopped
    depends_on:
      - postgres
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=openwork
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=openwork
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### 커스텀 빌드

```bash
# 백엔드만 빌드
docker-compose build backend

# 특정 버전 태그
docker build -t openwork/backend:v0.1.0 ./openwork-python

# 멀티 스테이지 빌드 (프로덕션)
docker build --target production -t openwork/backend:latest ./openwork-python
```

## 수동 배포

### systemd를 사용한 배포 (Linux)

#### 1. 애플리케이션 설치

```bash
# 사용자 생성
sudo useradd -r -s /bin/false openwork

# 디렉토리 생성
sudo mkdir -p /opt/openwork
sudo chown openwork:openwork /opt/openwork

# 코드 배포
cd /opt/openwork
sudo -u openwork git clone https://github.com/yourusername/openwork.git .

# Python 가상환경 설정
cd openwork-python
sudo -u openwork python3 -m venv venv
sudo -u openwork venv/bin/pip install -r requirements.txt
```

#### 2. systemd 서비스 파일 생성

`/etc/systemd/system/openwork.service`:

```ini
[Unit]
Description=OpenWork Backend Service
After=network.target

[Service]
Type=exec
User=openwork
Group=openwork
WorkingDirectory=/opt/openwork/openwork-python
Environment="PATH=/opt/openwork/openwork-python/venv/bin"
ExecStart=/opt/openwork/openwork-python/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

# 로그
StandardOutput=append:/var/log/openwork/access.log
StandardError=append:/var/log/openwork/error.log

# 보안
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/openwork/data

[Install]
WantedBy=multi-user.target
```

#### 3. 서비스 시작

```bash
# 로그 디렉토리 생성
sudo mkdir -p /var/log/openwork
sudo chown openwork:openwork /var/log/openwork

# 서비스 활성화 및 시작
sudo systemctl daemon-reload
sudo systemctl enable openwork
sudo systemctl start openwork

# 상태 확인
sudo systemctl status openwork

# 로그 확인
sudo journalctl -u openwork -f
```

### supervisord를 사용한 배포

`/etc/supervisor/conf.d/openwork.conf`:

```ini
[program:openwork]
command=/opt/openwork/openwork-python/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
directory=/opt/openwork/openwork-python
user=openwork
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/openwork/access.log
stderr_logfile=/var/log/openwork/error.log
environment=PATH="/opt/openwork/openwork-python/venv/bin"
```

```bash
# supervisord 재로드
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start openwork

# 상태 확인
sudo supervisorctl status openwork
```

## 환경 변수

### 필수 환경 변수

```bash
# .env 파일
DEBUG=False
SECRET_KEY=your-secret-key-here-min-32-chars
DATABASE_URL=postgresql://user:password@localhost:5432/openwork
OPENCODE_URL=http://localhost:8080
```

### 선택적 환경 변수

```bash
# 서버 설정
HOST=0.0.0.0
PORT=8000
WORKERS=4

# 데이터베이스
DB_POOL_SIZE=20
DB_MAX_OVERFLOW=10

# Redis (향후)
REDIS_URL=redis://localhost:6379/0

# 로깅
LOG_LEVEL=INFO
LOG_FORMAT=json

# CORS
CORS_ORIGINS=["http://localhost:3000", "https://yourdomain.com"]

# 파일 업로드
MAX_UPLOAD_SIZE=10485760  # 10MB
```

### SECRET_KEY 생성

```bash
# Python으로 생성
python -c "import secrets; print(secrets.token_urlsafe(32))"

# OpenSSL로 생성
openssl rand -base64 32
```

## 데이터베이스 마이그레이션

### SQLite에서 PostgreSQL로 마이그레이션

#### 1. PostgreSQL 설치 및 설정

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# macOS
brew install postgresql@15
brew services start postgresql@15

# 데이터베이스 생성
sudo -u postgres createuser openwork
sudo -u postgres createdb openwork -O openwork
sudo -u postgres psql -c "ALTER USER openwork WITH PASSWORD 'your-password';"
```

#### 2. Alembic 마이그레이션 설정

```bash
cd openwork-python

# Alembic 초기화 (이미 설정된 경우 생략)
alembic init alembic

# 마이그레이션 파일 생성
alembic revision --autogenerate -m "Initial migration"

# 마이그레이션 실행
alembic upgrade head
```

#### 3. 데이터 마이그레이션

```python
# migrate_data.py
import sqlite3
import psycopg2
from psycopg2.extras import execute_values

# SQLite 연결
sqlite_conn = sqlite3.connect('data/openwork.db')
sqlite_cur = sqlite_conn.cursor()

# PostgreSQL 연결
pg_conn = psycopg2.connect(
    dbname='openwork',
    user='openwork',
    password='your-password',
    host='localhost'
)
pg_cur = pg_conn.cursor()

# 세션 데이터 마이그레이션
sqlite_cur.execute("SELECT * FROM sessions")
sessions = sqlite_cur.fetchall()

execute_values(
    pg_cur,
    "INSERT INTO sessions (id, workspace_id, title, model, status, metadata, created_at, updated_at) VALUES %s",
    sessions
)

pg_conn.commit()
print(f"마이그레이션 완료: {len(sessions)}개 세션")

# 연결 종료
sqlite_conn.close()
pg_conn.close()
```

```bash
# 마이그레이션 실행
python migrate_data.py
```

## 리버스 프록시 설정

### Nginx 설정

`/etc/nginx/sites-available/openwork`:

```nginx
upstream openwork_backend {
    server localhost:8000 fail_timeout=0;
}

server {
    listen 80;
    server_name openwork.yourdomain.com;

    # HTTPS 리다이렉트
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name openwork.yourdomain.com;

    # SSL 인증서 (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/openwork.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/openwork.yourdomain.com/privkey.pem;

    # SSL 설정
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # 로그
    access_log /var/log/nginx/openwork.access.log;
    error_log /var/log/nginx/openwork.error.log;

    # 최대 업로드 크기
    client_max_body_size 10M;

    # API 프록시
    location /api/ {
        proxy_pass http://openwork_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket 프록시
    location /ws/ {
        proxy_pass http://openwork_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;  # 24시간
    }

    # 정적 파일 (향후 Flutter Web)
    location / {
        root /var/www/openwork;
        try_files $uri $uri/ /index.html;
    }
}
```

```bash
# 설정 활성화
sudo ln -s /etc/nginx/sites-available/openwork /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Let's Encrypt SSL 인증서

```bash
# Certbot 설치
sudo apt install certbot python3-certbot-nginx

# 인증서 발급
sudo certbot --nginx -d openwork.yourdomain.com

# 자동 갱신 테스트
sudo certbot renew --dry-run
```

### Traefik 설정 (Docker)

`docker-compose.yml`:

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    command:
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.email=your@email.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./letsencrypt:/letsencrypt

  backend:
    build: ./openwork-python
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.backend.rule=Host(`openwork.yourdomain.com`)"
      - "traefik.http.routers.backend.entrypoints=websecure"
      - "traefik.http.routers.backend.tls.certresolver=letsencrypt"
```

## 모니터링

### 헬스 체크 엔드포인트

```python
# app/api/endpoints/health.py
from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
async def health_check():
    """헬스 체크 엔드포인트"""
    return {
        "status": "healthy",
        "version": "0.1.0"
    }

@router.get("/health/detailed")
async def detailed_health_check():
    """상세 헬스 체크"""
    return {
        "status": "healthy",
        "database": "connected",
        "opencode": "reachable",
        "version": "0.1.0"
    }
```

### 로그 수집 (ELK Stack)

`docker-compose.yml`:

```yaml
services:
  elasticsearch:
    image: elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
    volumes:
      - es_data:/usr/share/elasticsearch/data

  logstash:
    image: logstash:8.11.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    depends_on:
      - elasticsearch

  kibana:
    image: kibana:8.11.0
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch

volumes:
  es_data:
```

### Prometheus 메트릭 (향후)

```python
# app/middleware/metrics.py
from prometheus_client import Counter, Histogram

REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

REQUEST_DURATION = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration'
)
```

## 보안 고려사항

### 1. 환경 변수 보호

```bash
# .env 파일 권한 설정
chmod 600 .env
chown openwork:openwork .env

# Git에서 제외
echo ".env" >> .gitignore
```

### 2. 방화벽 설정

```bash
# UFW (Ubuntu)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# 백엔드 포트는 외부 접근 차단 (Nginx가 프록시)
# 8000 포트는 localhost만 바인딩
```

### 3. 정기 업데이트

```bash
# 시스템 업데이트
sudo apt update && sudo apt upgrade -y

# Docker 이미지 업데이트
docker-compose pull
docker-compose up -d
```

### 4. 백업

```bash
# 데이터베이스 백업
pg_dump -U openwork openwork > backup_$(date +%Y%m%d).sql

# Docker 볼륨 백업
docker run --rm -v openwork_postgres_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/postgres_backup_$(date +%Y%m%d).tar.gz /data
```

## 성능 최적화

### 1. Gunicorn Workers

```bash
# 권장 워커 수: (2 x CPU 코어) + 1
gunicorn app.main:app \
  --workers 5 \
  --worker-class uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:8000 \
  --access-logfile - \
  --error-logfile -
```

### 2. PostgreSQL 튜닝

`postgresql.conf`:

```ini
# 연결 풀
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# WAL
wal_buffers = 16MB
checkpoint_completion_target = 0.9
```

### 3. Redis 캐싱 (향후)

```python
# app/core/cache.py
import redis.asyncio as redis

cache = redis.from_url("redis://localhost:6379")

async def get_cached_sessions(workspace_id: str):
    cached = await cache.get(f"workspace:{workspace_id}:sessions")
    if cached:
        return json.loads(cached)
    # ... DB에서 조회
    await cache.setex(f"workspace:{workspace_id}:sessions", 300, json.dumps(sessions))
    return sessions
```

## 문제 해결

자세한 내용은 [Troubleshooting Guide](troubleshooting.md)를 참조하세요.

## 추가 자료

- [Docker 공식 문서](https://docs.docker.com/)
- [Nginx 공식 문서](https://nginx.org/en/docs/)
- [FastAPI 배포 가이드](https://fastapi.tiangolo.com/deployment/)
