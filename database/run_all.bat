@echo off
chcp 65001 >nul
title EV Charging System - Database Setup
echo ============================================
echo EV Charging System - Database Installation
echo ============================================
echo.

:: Load variables from ../backend/.env
for /f "usebackq tokens=1,* delims==" %%a in ("%~dp0..\backend\.env") do (
    if "%%a"=="DB_SERVER" set DB_SERVER=%%b
    if "%%a"=="DB_USER" set DB_USER=%%b
    if "%%a"=="DB_PASSWORD" set DB_PASSWORD=%%b
    if "%%a"=="DB_NAME" set DB_NAME=%%b
)

:: Use defaults if not set
if "%DB_SERVER%"=="" set DB_SERVER=localhost
if "%DB_USER%"=="" set DB_USER=sa
if "%DB_PASSWORD%"=="" set DB_PASSWORD=TranKimHieu
if "%DB_NAME%"=="" set DB_NAME=EV_Charging_System

echo Server: %DB_SERVER%
echo Database: %DB_NAME%
echo User: %DB_USER%
echo.

:: ============================================
:: Step 1: Create Database (drops existing one)
:: ============================================
echo [1/11] Creating database...
sqlcmd -I -f 65001 -S "%DB_SERVER%" -U "%DB_USER%" -P "%DB_PASSWORD%" -i "01_CreateDatabase.sql"
if %ERRORLEVEL% NEQ 0 ( echo FAILED! & pause & exit /b %ERRORLEVEL% )
echo OK

:: ============================================
:: Step 2: Create Tables
:: ============================================
echo [2/11] Creating tables...
sqlcmd -I -f 65001 -S "%DB_SERVER%" -d "%DB_NAME%" -U "%DB_USER%" -P "%DB_PASSWORD%" -i "02_CreateTables.sql"
if %ERRORLEVEL% NEQ 0 ( echo FAILED! & pause & exit /b %ERRORLEVEL% )
echo OK

:: ============================================
:: Step 3: Create Error Handling (sp_ThrowError)
:: ============================================
echo [3/11] Creating error handling...
sqlcmd -I -f 65001 -S "%DB_SERVER%" -d "%DB_NAME%" -U "%DB_USER%" -P "%DB_PASSWORD%" -i "07_CreateErrorHandling.sql"
if %ERRORLEVEL% NEQ 0 ( echo FAILED! & pause & exit /b %ERRORLEVEL% )
echo OK

:: ============================================
:: Step 4: Create Functions
:: ============================================
echo [4/11] Creating functions...
sqlcmd -I -f 65001 -S "%DB_SERVER%" -d "%DB_NAME%" -U "%DB_USER%" -P "%DB_PASSWORD%" -i "04_CreateFunctions.sql"
if %ERRORLEVEL% NEQ 0 ( echo FAILED! & pause & exit /b %ERRORLEVEL% )
echo OK

:: ============================================
:: Step 5: Create Stored Procedures
:: ============================================
echo [5/11] Creating stored procedures...
sqlcmd -I -f 65001 -S "%DB_SERVER%" -d "%DB_NAME%" -U "%DB_USER%" -P "%DB_PASSWORD%" -i "05_CreateStoredProcedures.sql"
if %ERRORLEVEL% NEQ 0 ( echo FAILED! & pause & exit /b %ERRORLEVEL% )
echo OK

:: ============================================
:: Step 6: Create Triggers
:: ============================================
echo [6/11] Creating triggers...
sqlcmd -I -f 65001 -S "%DB_SERVER%" -d "%DB_NAME%" -U "%DB_USER%" -P "%DB_PASSWORD%" -i "06_CreateTriggers.sql"
if %ERRORLEVEL% NEQ 0 ( echo FAILED! & pause & exit /b %ERRORLEVEL% )
echo OK

:: ============================================
:: Step 7: Create Views
:: ============================================
echo [7/11] Creating views...
sqlcmd -I -f 65001 -S "%DB_SERVER%" -d "%DB_NAME%" -U "%DB_USER%" -P "%DB_PASSWORD%" -i "07_CreateViews.sql"
if %ERRORLEVEL% NEQ 0 ( echo FAILED! & pause & exit /b %ERRORLEVEL% )
echo OK

:: ============================================
:: Step 8: Create Analytics
:: ============================================
echo [8/11] Creating analytics objects...
sqlcmd -I -f 65001 -S "%DB_SERVER%" -d "%DB_NAME%" -U "%DB_USER%" -P "%DB_PASSWORD%" -i "09_CreateAnalytics.sql"
if %ERRORLEVEL% NEQ 0 ( echo FAILED! & pause & exit /b %ERRORLEVEL% )
echo OK

:: ============================================
:: Step 9: Create Migration System + Events
:: ============================================
echo [9/11] Creating migration system...
sqlcmd -I -f 65001 -S "%DB_SERVER%" -d "%DB_NAME%" -U "%DB_USER%" -P "%DB_PASSWORD%" -i "10_CreateMigrationSystem.sql"
if %ERRORLEVEL% NEQ 0 ( echo FAILED! & pause & exit /b %ERRORLEVEL% )
echo OK

echo [9b/11] Creating event + KPI snapshots...
sqlcmd -I -f 65001 -S "%DB_SERVER%" -d "%DB_NAME%" -U "%DB_USER%" -P "%DB_PASSWORD%" -i "11_CreateEventAndKPISnapshots.sql"
if %ERRORLEVEL% NEQ 0 ( echo FAILED! & pause & exit /b %ERRORLEVEL% )
echo OK

:: ============================================
:: Step 10: Seed Data
:: ============================================
echo [10/11] Seeding data (this may take a moment)...
sqlcmd -I -f 65001 -S "%DB_SERVER%" -d "%DB_NAME%" -U "%DB_USER%" -P "%DB_PASSWORD%" -i "03_SeedData.sql"
if %ERRORLEVEL% NEQ 0 ( echo FAILED! & pause & exit /b %ERRORLEVEL% )
echo OK

:: ============================================
:: Step 11: Create Batch Jobs
:: ============================================
echo [11/11] Creating batch jobs...
sqlcmd -I -f 65001 -S "%DB_SERVER%" -d "%DB_NAME%" -U "%DB_USER%" -P "%DB_PASSWORD%" -i "08_CreateBatchJobs.sql"
if %ERRORLEVEL% NEQ 0 ( echo FAILED! & pause & exit /b %ERRORLEVEL% )
echo OK

:: ============================================
:: Done
:: ============================================
echo.
echo ============================================
echo Installation completed successfully!
echo ============================================
echo.
echo Default credentials:
echo   Admin:    admin01@gmail.com / Admin@123
echo   Manager:  manager01..03 / Manager@123
echo   Customer: customer01..50 / Customer@123
echo.
pause
