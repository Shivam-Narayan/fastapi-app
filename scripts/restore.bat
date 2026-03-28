@echo off
setlocal enabledelayedexpansion





















echo Restore completedocker compose -f "%ROOT_DIR%\docker-compose.yml" exec -T postgres rm -f /tmp/restore_backup.sqldocker compose -f "%ROOT_DIR%\docker-compose.yml" exec -T postgres pg_restore -U postgres -d fastapi_db --clean --if-exists /tmp/restore_backup.sqldocker compose -f "%ROOT_DIR%\docker-compose.yml" exec -T postgres psql -U postgres -d fastapi_db -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"docker cp "%BACKUP_FILE%" "%CONTAINER_ID%:/tmp/restore_backup.sql"for /f "delims=" %%C in ('docker compose -f "%ROOT_DIR%\docker-compose.yml" ps -q postgres') do set CONTAINER_ID=%%Cecho Restoring backup from %BACKUP_FILE%
)  exit /b 1  echo Backup file not found: %BACKUP_FILE%if not exist "%BACKUP_FILE%" (for %%I in ("%~dp0..") do set "ROOT_DIR=%%~fI"set BACKUP_FILE=%~1
n)  exit /b 1  echo Usage: %~nx0 ^<path-to-backup-file^>if "%~1"=="" (:: restore.bat <backup-file-path>