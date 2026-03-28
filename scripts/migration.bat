@echo off
setlocal
for %%I in ("%~dp0") do set "SCRIPT_DIR=%%~fI"
REM alembic.ini is in project root, not scripts folder
set "PROJECT_ROOT=%SCRIPT_DIR%.."
if not exist "%PROJECT_ROOT%\alembic.ini" (
  echo alembic.ini not found in %PROJECT_ROOT%
  exit /b 1
)
cd /d "%PROJECT_ROOT%"
alembic -c alembic.ini upgrade head
echo Database migration finished.
