@echo off
setlocal enabledelayedexpansion






















echo Backup complete: %TARGET%docker compose -f "%ROOT_DIR%\docker-compose.yml" exec -T postgres rm -f /tmp/%FILENAME%docker cp "%CONTAINER_ID%:/tmp/%FILENAME%" "%TARGET%"for /f "delims=" %%C in ('docker compose -f "%ROOT_DIR%\docker-compose.yml" ps -q postgres') do set CONTAINER_ID=%%Cdocker compose -f "%ROOT_DIR%\docker-compose.yml" exec -T postgres pg_dump -U postgres -d fastapi_db -F c -f /tmp/%FILENAME%echo Creating backup file: %TARGET%set TARGET=%BACKUP_DIR%\%FILENAME%set FILENAME=fastapi_db_backup_%DATEPART%_%TIMESTAMP%.sqlfor /f "tokens=1-3 delims=/" %%a in ("%date%") do set DATEPART=%%c%%a%%bfor /f "tokens=1-3 delims=:." %%a in ("%time%") do set TIMESTAMP=%%a%%b%%cif not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"set BACKUP_DIR=%ROOT_DIR%\backupsfor %%I in ("%~dp0..") do set "ROOT_DIR=%%~fI"set ROOT_DIR=%~f0set ROOT_DIR=%~dp0..\:: Backup PostgreSQL database from docker compose (Windows)