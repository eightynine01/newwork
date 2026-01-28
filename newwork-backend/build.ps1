# NewWork Backend 빌드 스크립트 (Windows PowerShell)

$ErrorActionPreference = "Stop"

Write-Host "===== NewWork Backend Build Script =====" -ForegroundColor Blue
Write-Host "Platform: Windows"
Write-Host "Python: " -NoNewline
python --version 2>&1
Write-Host ""

# 함수: 에러 메시지
function Write-Error-Message {
    param([string]$Message)
    Write-Host "✗ Error: $Message" -ForegroundColor Red
    exit 1
}

# 함수: 성공 메시지
function Write-Success-Message {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

# 함수: 경고 메시지
function Write-Warning-Message {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

# Python 확인
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python not found"
    }
} catch {
    Write-Error-Message "Python 3 not found. Please install Python 3.10 or later."
}

# PyInstaller 확인 및 설치
Write-Host "Step 1: Checking PyInstaller..."
try {
    python -m pip show pyinstaller | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "PyInstaller not found"
    }
    Write-Success-Message "PyInstaller ready"
} catch {
    Write-Warning-Message "PyInstaller not found. Installing..."
    python -m pip install pyinstaller
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Message "Failed to install PyInstaller"
    }
    Write-Success-Message "PyInstaller installed"
}

# 의존성 확인
Write-Host ""
Write-Host "Step 2: Checking dependencies..."
if (-Not (Test-Path "requirements.txt")) {
    Write-Error-Message "requirements.txt not found"
}

# 의존성 설치 (선택사항)
$installDeps = Read-Host "Install/update dependencies from requirements.txt? (y/N)"
if ($installDeps -eq "y" -or $installDeps -eq "Y") {
    python -m pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Message "Failed to install dependencies"
    }
    Write-Success-Message "Dependencies installed"
} else {
    Write-Warning-Message "Skipping dependency installation"
}

# 이전 빌드 정리
Write-Host ""
Write-Host "Step 3: Cleaning previous builds..."
if (Test-Path "build") { Remove-Item -Recurse -Force "build" }
if (Test-Path "dist") { Remove-Item -Recurse -Force "dist" }
if (Test-Path "*.spec.bak") { Remove-Item -Force "*.spec.bak" }
Write-Success-Message "Cleaned"

# PyInstaller 빌드
Write-Host ""
Write-Host "Step 4: Building with PyInstaller..."
if (-Not (Test-Path "newwork.spec")) {
    Write-Error-Message "newwork.spec not found"
}

python -m PyInstaller newwork.spec --clean --noconfirm
if ($LASTEXITCODE -ne 0) {
    Write-Error-Message "Build failed"
}
Write-Success-Message "Build completed"

# 빌드 결과 확인
Write-Host ""
Write-Host "Step 5: Verifying build..."
$executable = "dist\newwork-backend.exe"

if (Test-Path $executable) {
    $fileSize = (Get-Item $executable).Length
    $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
    Write-Success-Message "Executable found: $executable (${fileSizeMB} MB)"
} else {
    Write-Error-Message "Executable not found: $executable"
}

# 완료
Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "✓ Build Successful!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""
Write-Host "Output: $executable"
Write-Host ""
Write-Host "To test the backend:"
Write-Host "  .\$executable --host 127.0.0.1 --port 8000"
Write-Host ""
