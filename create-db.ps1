# PowerShell script to create cycling database
param(
    [string]$DatabasePath = "cycling_data.db",
    [switch]$Force = $false,
    [switch]$Help = $false
)

function Show-Help {
    Write-Host "🚴 Cycling Calorie Calculator - Database Creator"
    Write-Host ""
    Write-Host "USAGE:"
    Write-Host "    .\create-db.ps1 [-DatabasePath <path>] [-Force] [-Help]"
    Write-Host ""
    Write-Host "PARAMETERS:"
    Write-Host "    -DatabasePath <path>    Database file path (default: cycling_data.db)"
    Write-Host "    -Force                  Overwrite existing database"
    Write-Host "    -Help                   Show this help message"
    Write-Host ""
    Write-Host "EXAMPLES:"
    Write-Host "    .\create-db.ps1                                    # Create default database"
    Write-Host "    .\create-db.ps1 -DatabasePath 'my_rides.db'       # Create with custom name"
    Write-Host "    .\create-db.ps1 -Force                             # Overwrite existing database"
    Write-Host "    .\create-db.ps1 -DatabasePath 'data\rides.db'     # Create in subdirectory"
    Write-Host ""
    Write-Host "DESCRIPTION:"
    Write-Host "    This script creates a new SQLite database for the Cycling Calorie Calculator"
    Write-Host "    with all required tables, indexes, and default configuration values."
    Write-Host ""
    Write-Host "REQUIREMENTS:"
    Write-Host "    - SQLite3 command line tool (can be downloaded from https://sqlite.org)"
    Write-Host "    - Or use the manual method with any SQLite browser/tool"
}

function Test-SqliteAvailable {
    try {
        $null = Get-Command sqlite3 -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Create-Database {
    param([string]$DbPath, [bool]$ForceCreate)
    
    $absolutePath = Resolve-Path -Path $DbPath -ErrorAction SilentlyContinue
    if (-not $absolutePath) {
        $absolutePath = [System.IO.Path]::GetFullPath($DbPath)
    }
    
    # Check if database exists
    if (Test-Path $absolutePath) {
        if (-not $ForceCreate) {
            Write-Host "⚠️  Database already exists: $absolutePath" -ForegroundColor Yellow
            Write-Host "Use -Force to overwrite or specify a different path" -ForegroundColor Yellow
            return $false
        } else {
            Write-Host "🗑️  Removing existing database: $absolutePath" -ForegroundColor Yellow
            Remove-Item $absolutePath -Force
        }
    }
    
    # Create directory if it doesn't exist
    $dbDir = Split-Path $absolutePath -Parent
    if (-not (Test-Path $dbDir)) {
        Write-Host "📁 Creating directory: $dbDir" -ForegroundColor Green
        New-Item -ItemType Directory -Path $dbDir -Force | Out-Null
    }
    
    Write-Host "🚀 Creating new database: $absolutePath" -ForegroundColor Green
    
    # Check if sqlite3 is available
    if (Test-SqliteAvailable) {
        Write-Host "📋 Using sqlite3 command line tool..." -ForegroundColor Cyan
        
        try {
            # Execute schema file with sqlite3
            $schemaPath = Join-Path $PSScriptRoot "schema.sql"
            if (-not (Test-Path $schemaPath)) {
                Write-Host "❌ Schema file not found: $schemaPath" -ForegroundColor Red
                return $false
            }
            
            sqlite3 $absolutePath ".read `"$schemaPath`""
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Database created successfully!" -ForegroundColor Green
                Write-Host "📊 Database location: $absolutePath" -ForegroundColor Cyan
                Write-Host "⚙️  Default configuration values initialized" -ForegroundColor Cyan
                
                Show-DatabaseInfo -DbPath $absolutePath
                return $true
            } else {
                Write-Host "❌ Error creating database with sqlite3" -ForegroundColor Red
                return $false
            }
        } catch {
            Write-Host "❌ Error executing sqlite3: $_" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "⚠️  sqlite3 command not found in PATH" -ForegroundColor Yellow
        Show-ManualInstructions -DbPath $absolutePath
        return $false
    }
}

function Show-DatabaseInfo {
    param([string]$DbPath)
    
    Write-Host "" -ForegroundColor Green
    Write-Host "📈 DATABASE SUMMARY:" -ForegroundColor Green
    Write-Host "   Path: $DbPath" -ForegroundColor Green
    Write-Host "   Tables: rides, calorie_breakdown, configuration" -ForegroundColor Green
    Write-Host "   Indexes: Optimized for queries on date, distance, calories" -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    Write-Host "🚴 READY TO USE:" -ForegroundColor Green
    Write-Host "   Your cycling database is ready! You can now:" -ForegroundColor Green
    Write-Host "   • Import GPX files and calculate calories" -ForegroundColor Green
    Write-Host "   • Store ride data and history" -ForegroundColor Green
    Write-Host "   • Manage application configuration" -ForegroundColor Green
    Write-Host "   • Export data for analysis" -ForegroundColor Green
}

function Show-ManualInstructions {
    param([string]$DbPath)
    
    Write-Host "" -ForegroundColor Cyan
    Write-Host "📏 MANUAL SETUP INSTRUCTIONS:" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    Write-Host "Since sqlite3 command line tool is not available, you can create the database manually:" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    Write-Host "1. Download SQLite3 from: https://sqlite.org/download.html" -ForegroundColor Cyan
    Write-Host "   - For Windows: download sqlite-tools-win32-x86-*.zip" -ForegroundColor Cyan
    Write-Host "   - Extract sqlite3.exe to your PATH or current directory" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    Write-Host "2. Or use any SQLite browser/GUI tool like:" -ForegroundColor Cyan
    Write-Host "   - DB Browser for SQLite (https://sqlitebrowser.org/)" -ForegroundColor Cyan
    Write-Host "   - SQLiteStudio (https://sqlitestudio.pl/)" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    Write-Host "3. Create a new database: $DbPath" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    Write-Host "4. Execute the SQL schema from: schema.sql" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    Write-Host "5. The schema.sql file contains all table definitions and default data" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    Write-Host "ALTERNATIVE - Using PowerShell with sqlite3.exe:" -ForegroundColor Cyan
    Write-Host "If you download sqlite3.exe to this directory, run:" -ForegroundColor Cyan
    Write-Host "   .\sqlite3.exe '$DbPath' '.read schema.sql'" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Host "🚴 Cycling Calorie Calculator - Database Creator`n" -ForegroundColor Blue

$success = Create-Database -DbPath $DatabasePath -ForceCreate $Force

if ($success) {
    exit 0
} else {
    exit 1
}