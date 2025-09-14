@echo off
setlocal enabledelayedexpansion

REM Batch script to create cycling database
set "DB_PATH=cycling_data.db"
set "FORCE="
set "HELP="

:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--help" (
    set "HELP=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-h" (
    set "HELP=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--force" (
    set "FORCE=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-f" (
    set "FORCE=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--path" (
    set "DB_PATH=%~2"
    shift
    shift
    goto :parse_args
)
REM If no flag, treat as database path
if not "%~1"=="" (
    set "DB_PATH=%~1"
    shift
    goto :parse_args
)

:args_done

if defined HELP (
    call :show_help
    exit /b 0
)

echo 🚴 Cycling Calorie Calculator - Database Creator
echo.

call :create_database "%DB_PATH%" "%FORCE%"
if !errorlevel! equ 0 (
    exit /b 0
) else (
    exit /b 1
)

:show_help
echo 🚴 Cycling Calorie Calculator - Database Creator
echo.
echo USAGE:
echo     create-db.bat [options] [database_path]
echo.
echo OPTIONS:
echo     --help, -h          Show this help message
echo     --path ^<path^>       Specify database file path
echo     --force, -f         Overwrite existing database file
echo.
echo EXAMPLES:
echo     create-db.bat                           # Create default database
echo     create-db.bat my_cycling_data.db        # Create database with custom name
echo     create-db.bat --path ./data/rides.db    # Create database in specific path
echo     create-db.bat --force                   # Force overwrite existing database
echo.
echo DESCRIPTION:
echo     This script creates and initializes an empty cycling database with all
echo     required tables and indexes. If the database already exists, it will not
echo     be modified unless --force is specified.
echo.
echo REQUIREMENTS:
echo     - SQLite3 command line tool (sqlite3.exe in PATH or current directory)
echo     - Download from: https://sqlite.org/download.html
echo.
goto :eof

:create_database
set "DB_PATH=%~1"
set "FORCE_CREATE=%~2"

REM Convert to absolute path
for %%i in ("%DB_PATH%") do set "ABS_PATH=%%~fi"

REM Check if database exists
if exist "%ABS_PATH%" (
    if not defined FORCE_CREATE (
        echo ⚠️  Database already exists: %ABS_PATH%
        echo Use --force to overwrite or specify a different path
        exit /b 1
    ) else (
        echo 🗑️  Removing existing database: %ABS_PATH%
        del "%ABS_PATH%"
    )
)

REM Create directory if it doesn't exist
for %%i in ("%ABS_PATH%") do set "DB_DIR=%%~dpi"
if not exist "%DB_DIR%" (
    echo 📁 Creating directory: %DB_DIR%
    mkdir "%DB_DIR%" 2>nul
)

echo 🚀 Creating new database: %ABS_PATH%

REM Check if sqlite3 is available
where sqlite3 >nul 2>&1
if %errorlevel% equ 0 (
    echo 📋 Using sqlite3 command line tool...
    
    REM Check if schema file exists
    if not exist "schema.sql" (
        echo ❌ Schema file not found: schema.sql
        exit /b 1
    )
    
    REM Execute schema file with sqlite3
    sqlite3 "%ABS_PATH%" ".read schema.sql"
    
    if !errorlevel! equ 0 (
        echo ✅ Database created successfully!
        echo 📊 Database location: %ABS_PATH%
        echo ⚙️  Default configuration values initialized
        call :show_database_info "%ABS_PATH%"
        exit /b 0
    ) else (
        echo ❌ Error creating database with sqlite3
        exit /b 1
    )
) else (
    echo ⚠️  sqlite3 command not found in PATH
    call :show_manual_instructions "%ABS_PATH%"
    exit /b 1
)

:show_database_info
echo.
echo 📈 DATABASE SUMMARY:
echo    Path: %~1
echo    Tables: rides, calorie_breakdown, configuration
echo    Indexes: Optimized for queries on date, distance, calories
echo.   
echo 🚴 READY TO USE:
echo    Your cycling database is ready! You can now:
echo    • Import GPX files and calculate calories
echo    • Store ride data and history
echo    • Manage application configuration
echo    • Export data for analysis
goto :eof

:show_manual_instructions
echo.
echo 📝 MANUAL SETUP INSTRUCTIONS:
echo.
echo Since sqlite3 command line tool is not available, you can create the database manually:
echo.
echo 1. Download SQLite3 from: https://sqlite.org/download.html
echo    - For Windows: download sqlite-tools-win32-x86-*.zip
echo    - Extract sqlite3.exe to your PATH or current directory
echo.
echo 2. Or use any SQLite browser/GUI tool like:
echo    - DB Browser for SQLite (https://sqlitebrowser.org/)
echo    - SQLiteStudio (https://sqlitestudio.pl/)
echo.
echo 3. Create a new database: %~1
echo.
echo 4. Execute the SQL schema from: schema.sql
echo.
echo 5. The schema.sql file contains all table definitions and default data
echo.
echo ALTERNATIVE - Using CMD with sqlite3.exe:
echo If you download sqlite3.exe to this directory, run:
echo    sqlite3.exe "%~1" ".read schema.sql"
echo.
goto :eof