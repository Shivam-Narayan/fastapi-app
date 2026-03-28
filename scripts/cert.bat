@echo off
setlocal












echo Generated %CERT_DIR%\tls.crt and %CERT_DIR%\tls.key  -subj "/CN=localhost/O=FastAPI-Learn"  -out "%CERT_DIR%\tls.crt" ^  -keyout "%CERT_DIR%\tls.key" ^openssl req -x509 -nodes -days 365 -newkey rsa:2048 ^if not exist "%CERT_DIR%" mkdir "%CERT_DIR%"set CERT_DIR=%ROOT_DIR%\certsfor %%I in ("%~dp0..") do set "ROOT_DIR=%%~fI":: Simple self-signed cert generator for Windows (requires OpenSSL in PATH)