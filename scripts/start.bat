@echo off
REM FastAPI Docker startup script for Windows
REM Usage: scripts\start.bat [--fast] [--build] [--down]

setlocal
setlocal EnableDelayedExpansion

REM Default flags
set "FAST=0"
set "BUILD=0"
set "DOWN=0"

REM Parse arguments
:parse_args
if "%1"=="" goto args_done
if "%1"=="--fast" set FAST=1
if "%1"=="--build" set BUILD=1
if "%1"=="--down" set DOWN=1
shift
goto parse_args

:args_done
REM Check if docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo Docker is not installed
    exit /b 1
)

REM Check if Docker Compose v2 is installed
docker compose version >nul 2>&1
if errorlevel 1 (
    echo Docker Compose is not installed
    exit /b 1
)

REM Ensure Docker daemon is running (auto-start Docker Desktop on Windows)
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker daemon is not running. Starting Docker Desktop...
    if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" (
        start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
        powershell -NoProfile -Command "$ready=$false; 1..60 | ForEach-Object { docker info *> $null; if ($LASTEXITCODE -eq 0) { $ready=$true; break }; Start-Sleep -Seconds 2 }; if (-not $ready) { exit 1 }"
        if errorlevel 1 (
            echo Docker daemon is still unavailable. Wait for Docker Desktop to fully start, then re-run this script.
            exit /b 1
        )
    ) else (
        echo Docker daemon is not running and Docker Desktop was not found at %ProgramFiles%\Docker\Docker\Docker Desktop.exe
        exit /b 1
    )
)

echo.
echo ================================================
echo FastAPI Docker Compose Manager
echo ================================================
echo.

REM Get project root directory
for %%A in ("%~f0") do set "SCRIPT_DIR=%%~dpA"
set "SEARCH_DIR=%SCRIPT_DIR%"

:find_compose
if exist "%SEARCH_DIR%docker-compose.yml" (
    set "PROJECT_ROOT=%SEARCH_DIR%"
    goto compose_found
)

for %%A in ("%SEARCH_DIR%..") do set "PARENT_DIR=%%~fA\"
if /I "%PARENT_DIR%"=="%SEARCH_DIR%" goto compose_not_found
set "SEARCH_DIR=%PARENT_DIR%"
goto find_compose

:compose_found
set "COMPOSE_FILE=%PROJECT_ROOT%docker-compose.yml"

:compose_not_found
if not exist "%COMPOSE_FILE%" (
    echo docker-compose.yml not found. Checked from "%SCRIPT_DIR%" upward.
    exit /b 1
)

cd /d "%PROJECT_ROOT%"

REM Handle --down flag
if "%DOWN%"=="1" (
    echo Stopping all services...
    docker compose -f "%COMPOSE_FILE%" down -v
    echo Services stopped
    exit /b 0
)

REM Create logs directory
if not exist "logs" mkdir logs
echo Logs directory created

REM Pick app host port with stable behavior:
REM 1) Prefer 8000 when free
REM 2) If 8000 is busy, reuse current app mapping when present
REM 3) Otherwise pick next free port up to 8100
set "APP_PORT="
set "EXISTING_PORT_LINE="
set "EXISTING_PORT="
for /f %%L in ('docker compose -f "%COMPOSE_FILE%" port app 8000 2^>nul') do (
    if not defined EXISTING_PORT_LINE set "EXISTING_PORT_LINE=%%L"
)

if defined EXISTING_PORT_LINE (
    for /f "tokens=2 delims=:" %%P in ("%EXISTING_PORT_LINE%") do set "EXISTING_PORT=%%P"
)

set "PORT8000_FREE="
for /f %%F in ('powershell -NoProfile -Command "if (Get-NetTCPConnection -State Listen -LocalPort 8000 -ErrorAction SilentlyContinue) { Write-Output 0 } else { Write-Output 1 }"') do set "PORT8000_FREE=%%F"

if "%PORT8000_FREE%"=="1" (
    set "APP_PORT=8000"
) else if defined EXISTING_PORT (
    set "APP_PORT=%EXISTING_PORT%"
) else (
    for /f %%P in ('powershell -NoProfile -Command "$selected=0; foreach($p in 8001..8100){ if(-not (Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue)){ $selected=$p; break } }; if($selected -eq 0){ exit 1 } else { Write-Output $selected }"') do set "APP_PORT=%%P"
)

if "%APP_PORT%"=="" (
    echo Could not determine a free port between 8000 and 8100
    exit /b 1
)

if not "%APP_PORT%"=="8000" (
    echo Port 8000 is busy. Using port %APP_PORT% for FastAPI.
)

set "APP_PORT=%APP_PORT%"
echo %APP_PORT%>"%PROJECT_ROOT%\logs\app-port.txt"

REM Start services
if "%FAST%"=="1" goto start_fast
if "%BUILD%"=="1" goto start_build
goto start_default

:start_fast
echo.
echo Starting services (fast mode - no rebuild)...
docker compose -f "%COMPOSE_FILE%" up -d
goto start_done

:start_build
echo.
echo Building images and starting services...
docker compose -f "%COMPOSE_FILE%" up -d --build
goto start_done

:start_default
echo.
echo Starting services...
docker compose -f "%COMPOSE_FILE%" up -d

:start_done

if errorlevel 1 (
    echo Failed to start services
    exit /b 1
)

echo Waiting for PostgreSQL to be ready...
set "DB_READY=0"
for /l %%I in (1,1,30) do (
    docker compose -f "%COMPOSE_FILE%" exec -T postgres pg_isready -U postgres -d fastapi_db >nul 2>&1
    if not errorlevel 1 (
        set "DB_READY=1"
        goto db_ready
    )
    timeout /t 2 /nobreak >nul
)

:db_ready
if "!DB_READY!"=="0" (
    echo PostgreSQL did not become ready in time
    echo Failed to start services
    exit /b 1
)

echo Running database migrations...
set "MIGRATIONS_OK=0"
for /l %%I in (1,1,5) do (
    docker compose -f "%COMPOSE_FILE%" exec -T app alembic -c alembic.ini upgrade head >nul 2>&1
    if not errorlevel 1 (
        set "MIGRATIONS_OK=1"
        goto migrations_done
    )
    echo Migration attempt %%I failed, retrying...
    timeout /t 3 /nobreak >nul
)

:migrations_done
if "!MIGRATIONS_OK!"=="0" (
    echo Database migrations failed
    docker compose -f "%COMPOSE_FILE%" exec -T app alembic -c alembic.ini upgrade head
    exit /b 1
)

echo.
echo ================================================
echo Service Status
echo ================================================
echo.

REM Check services
docker compose -f "%COMPOSE_FILE%" ps | find "postgres" >nul
if errorlevel 1 (
    echo PostgreSQL - not running
) else (
    echo PostgreSQL - localhost:5432
)

docker compose -f "%COMPOSE_FILE%" ps | find "app" >nul
if errorlevel 1 (
    echo FastAPI App - not running
) else (
    echo FastAPI App - http://localhost:%APP_PORT%
)

docker compose -f "%COMPOSE_FILE%" ps | find "pgadmin" >nul
if errorlevel 1 (
    echo pgAdmin - not running
) else (
    echo pgAdmin - http://localhost:5050
)

docker compose -f "%COMPOSE_FILE%" ps | find "grafana" >nul
if errorlevel 1 (
    echo Grafana - not running
) else (
    echo Grafana - http://localhost:4000
)

docker compose -f "%COMPOSE_FILE%" ps | find "loki" >nul
if errorlevel 1 (
    echo Loki - not running
) else (
    echo Loki - http://localhost:3100
)

docker compose -f "%COMPOSE_FILE%" ps | find "prometheus" >nul
if errorlevel 1 (
    echo Prometheus - not running
) else (
    echo Prometheus - http://localhost:9090
)

echo.
echo ================================================
echo Access Points
echo ================================================
echo.
echo FastAPI:      http://localhost:%APP_PORT%
echo pgAdmin:      http://localhost:5050/browser/
echo Grafana:      http://localhost:4000 (admin/admin)
echo Prometheus:   http://localhost:9090
echo Loki:         http://localhost:3100
echo PostgreSQL:   localhost:5432
echo.
echo View logs:    docker compose -f "%COMPOSE_FILE%" logs -f [service]
echo Stop all:     scripts\start.bat --down
echo ================================================
echo.
