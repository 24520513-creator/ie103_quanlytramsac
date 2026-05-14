@echo off
chcp 65001 >nul
title EV_Charging_System database setup

set DB_SERVER=localhost
set DB_USER=sa
set DB_PASSWORD=TranKimHieu

if exist "%~dp0..\backend\.env" (
    for /f "usebackq tokens=1,* delims==" %%a in ("%~dp0..\backend\.env") do (
        if "%%a"=="DB_SERVER" set DB_SERVER=%%b
        if "%%a"=="DB_USER" set DB_USER=%%b
        if "%%a"=="DB_PASSWORD" set DB_PASSWORD=%%b
    )
)

echo Server: %DB_SERVER%
echo User: %DB_USER%
echo.
sqlcmd -I -b -C -f 65001 -S "%DB_SERVER%" -U "%DB_USER%" -P "%DB_PASSWORD%" -i "%~dp0run_all.sql"
if %ERRORLEVEL% NEQ 0 (
    echo Database setup failed.
    pause
    exit /b %ERRORLEVEL%
)

echo Database setup completed successfully.
pause
