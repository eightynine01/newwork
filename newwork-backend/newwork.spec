# -*- mode: python ; coding: utf-8 -*-
"""
NewWork Backend PyInstaller Specification

이 파일은 FastAPI 백엔드를 독립 실행 파일로 패키징하기 위한 PyInstaller 설정입니다.
"""

import sys
import os
from pathlib import Path

# 현재 디렉토리 (PyInstaller는 SPECPATH 변수를 자동으로 정의)
SPEC_DIR = Path(SPECPATH)

block_cipher = None

# 분석 단계: Python 코드 및 의존성 수집
a = Analysis(
    ['app/main.py'],  # 진입점
    pathex=[str(SPEC_DIR)],
    binaries=[],  # 바이너리 의존성 (필요시 추가)
    datas=[
        # 앱 코드 포함 (Python 파일들)
        ('app', 'app'),
    ],
    hiddenimports=[
        # FastAPI 및 Uvicorn 관련
        'uvicorn.logging',
        'uvicorn.loops',
        'uvicorn.loops.auto',
        'uvicorn.protocols',
        'uvicorn.protocols.http',
        'uvicorn.protocols.http.auto',
        'uvicorn.protocols.websockets',
        'uvicorn.protocols.websockets.auto',
        'uvicorn.lifespan',
        'uvicorn.lifespan.on',

        # FastAPI
        'fastapi',
        'fastapi.routing',
        'fastapi.responses',

        # Pydantic
        'pydantic',
        'pydantic.networks',
        'pydantic_settings',

        # SQLAlchemy
        'sqlalchemy',
        'sqlalchemy.ext.declarative',
        'sqlalchemy.orm',
        'sqlalchemy.sql',

        # Alembic
        'alembic',
        'alembic.runtime.migration',

        # 기타
        'httpx',
        'python_multipart',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        # 제외할 모듈 (빌드 크기 최적화)
        'matplotlib',
        'PIL',
        'tkinter',
        'pandas',
        'numpy',
        'scipy',
        'pytest',
        'mypy',
        'ruff',
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

# PYZ: Python 라이브러리 아카이브
pyz = PYZ(
    a.pure,
    a.zipped_data,
    cipher=block_cipher
)

# EXE: 실행 파일 생성
exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='newwork-backend',  # 실행 파일 이름
    debug=False,  # 디버그 모드 비활성화
    bootloader_ignore_signals=False,
    strip=False,  # 심볼 제거 (Linux/macOS)
    upx=True,  # UPX 압축 활성화 (크기 최적화)
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,  # GUI 앱이므로 콘솔 숨김 (Windows)
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    # macOS 앱 번들 정보 (선택사항)
    # icon='path/to/icon.icns',  # 아이콘 파일 경로
)

# macOS .app 번들 생성 (선택사항)
# app = BUNDLE(
#     exe,
#     name='NewWork Backend.app',
#     icon='path/to/icon.icns',
#     bundle_identifier='com.newwork.backend',
# )
