#!/bin/bash

# Bash script to create cycling database
set -e  # Exit on any error

# Default values
DB_PATH="cycling_data.db"
FORCE=false
HELP=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${BLUE}🚴 Cycling Calorie Calculator - Database Creator${NC}"
    echo ""
    echo "USAGE:"
    echo "    ./create-db.sh [options] [database_path]"
    echo ""
    echo "OPTIONS:"
    echo "    -h, --help          Show this help message"
    echo "    -f, --force         Overwrite existing database file"
    echo "    -v, --verbose       Enable verbose output"
    echo ""
    echo "EXAMPLES:"
    echo "    ./create-db.sh                           # Create default database"
    echo "    ./create-db.sh my_cycling_data.db        # Create database with custom name"
    echo "    ./create-db.sh --force                   # Force overwrite existing database"
    echo "    ./create-db.sh --verbose                 # Create with verbose output"
    echo ""
    echo "DESCRIPTION:"
    echo "    This script creates and initializes an empty cycling database with all"
    echo "    required tables and indexes. If the database already exists, it will not"
    echo "    be modified unless --force is specified."
    echo ""
    echo "REQUIREMENTS:"
    echo "    - SQLite3 command line tool (sqlite3 in PATH)"
    echo "    - Download from: https://sqlite.org/download.html"
    echo ""
}

check_sqlite() {
    if ! command -v sqlite3 &> /dev/null; then
        return 1
    fi
    return 0
}

show_manual_instructions() {
    local db_path="$1"
    
    echo ""
    echo -e "${CYAN}📝 MANUAL SETUP INSTRUCTIONS:${NC}"
    echo ""
    echo "Since sqlite3 command line tool is not available, you can create the database manually:"
    echo ""
    echo "1. Install SQLite3:"
    echo "   - Ubuntu/Debian: sudo apt-get install sqlite3"
    echo "   - CentOS/RHEL: sudo yum install sqlite"
    echo "   - macOS: brew install sqlite3"
    echo "   - Or download from: https://sqlite.org/download.html"
    echo ""
    echo "2. Or use any SQLite browser/GUI tool like:"
    echo "   - DB Browser for SQLite (https://sqlitebrowser.org/)"
    echo "   - SQLiteStudio (https://sqlitestudio.pl/)"
    echo "   - DBeaver (https://dbeaver.io/)"
    echo ""
    echo "3. Create a new database: $db_path"
    echo ""
    echo "4. Execute the SQL schema from: schema.sql"
    echo ""
    echo "5. The schema.sql file contains all table definitions and default data"
    echo ""
    echo "ALTERNATIVE - Using bash with sqlite3:"
    echo "If you install sqlite3, run:"
    echo "   sqlite3 \"$db_path\" \".read schema.sql\""
    echo ""
}

show_database_info() {
    local db_path="$1"
    
    echo ""
    echo -e "${GREEN}📈 DATABASE SUMMARY:${NC}"
    echo -e "${GREEN}   Path: $(realpath "$db_path")${NC}"
    echo -e "${GREEN}   Tables: rides, calorie_breakdown, configuration${NC}"
    echo -e "${GREEN}   Indexes: Optimized for queries on date, distance, calories${NC}"
    echo ""
    echo -e "${GREEN}🚴 READY TO USE:${NC}"
    echo -e "${GREEN}   Your cycling database is ready! You can now:${NC}"
    echo -e "${GREEN}   • Import GPX files and calculate calories${NC}"
    echo -e "${GREEN}   • Store ride data and history${NC}"
    echo -e "${GREEN}   • Manage application configuration${NC}"
    echo -e "${GREEN}   • Export data for analysis${NC}"
}

create_database() {
    local db_path="$1"
    local force_create="$2"
    
    # Convert to absolute path
    local abs_path=$(realpath "$db_path" 2>/dev/null || echo "$(pwd)/$db_path")
    
    # Check if database exists
    if [ -f "$abs_path" ]; then
        if [ "$force_create" != true ]; then
            echo -e "${YELLOW}⚠️  Database already exists: $abs_path${NC}"
            echo "Use --force to overwrite or specify a different path"
            return 1
        else
            if [ "$VERBOSE" == true ]; then
                echo -e "${YELLOW}🗑️  Removing existing database: $abs_path${NC}"
            fi
            rm -f "$abs_path"
        fi
    fi
    
    # Create directory if it doesn't exist
    local db_dir=$(dirname "$abs_path")
    if [ ! -d "$db_dir" ]; then
        if [ "$VERBOSE" == true ]; then
            echo -e "${GREEN}📁 Creating directory: $db_dir${NC}"
        fi
        mkdir -p "$db_dir"
    fi
    
    echo -e "${GREEN}🚀 Creating new database: $abs_path${NC}"
    
    # Check if sqlite3 is available
    if check_sqlite; then
        if [ "$VERBOSE" == true ]; then
            echo -e "${CYAN}📋 Using sqlite3 command line tool...${NC}"
        fi
        
        # Check if schema file exists
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local schema_path="$script_dir/schema.sql"
        
        if [ ! -f "$schema_path" ]; then
            echo -e "${RED}❌ Schema file not found: $schema_path${NC}"
            return 1
        fi
        
        # Execute schema file with sqlite3
        if sqlite3 "$abs_path" ".read '$schema_path'"; then
            echo -e "${GREEN}✅ Database created successfully!${NC}"
            echo -e "${CYAN}📊 Database location: $abs_path${NC}"
            echo -e "${CYAN}⚙️  Default configuration values initialized${NC}"
            
            show_database_info "$abs_path"
            return 0
        else
            echo -e "${RED}❌ Error creating database with sqlite3${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  sqlite3 command not found in PATH${NC}"
        show_manual_instructions "$abs_path"
        return 1
    fi
}

# Parse command line arguments
while [ $# -gt 0 ]; do
    case $1 in
        -h|--help)
            HELP=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo "Use --help to see available options"
            exit 1
            ;;
        *)
            # Treat as database path
            DB_PATH="$1"
            shift
            ;;
    esac
done

# Main execution
if [ "$HELP" == true ]; then
    show_help
    exit 0
fi

echo -e "${BLUE}🚴 Cycling Calorie Calculator - Database Creator${NC}"
echo ""

if create_database "$DB_PATH" "$FORCE"; then
    exit 0
else
    exit 1
fi