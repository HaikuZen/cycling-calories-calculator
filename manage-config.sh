#!/bin/bash

# Bash script to manage database configuration
set -e  # Exit on any error

# Default values
DB_PATH="cycling_data.db"
COMMAND=""
CONFIG_KEY=""
CONFIG_VALUE=""
CONFIG_TYPE="string"
CONFIG_DESCRIPTION=""
CONFIG_CATEGORY="general"
HELP=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${CYAN}⚙️  Configuration Manager${NC}"
    echo ""
    echo "USAGE:"
    echo "    ./manage-config.sh <command> [options]"
    echo ""
    echo "COMMANDS:"
    echo "    set                Set a configuration value"
    echo "    get                Get a configuration value"
    echo "    list               List all configuration values"
    echo "    delete             Delete a configuration value"
    echo "    category           List configuration by category"
    echo "    reset              Reset to default configuration"
    echo ""
    echo "OPTIONS:"
    echo "    -k, --key <key>         Configuration key"
    echo "    -v, --value <value>     Configuration value"
    echo "    -t, --type <type>       Value type (string|number|boolean|json)"
    echo "    -d, --description <desc> Configuration description"
    echo "    -c, --category <cat>    Configuration category"
    echo "    --db <path>             Database file path (default: ./cycling_data.db)"
    echo "    -h, --help              Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "    # Set a string value"
    echo "    ./manage-config.sh set -k \"rider_name\" -v \"John Doe\" -d \"Rider name\""
    echo ""
    echo "    # Set a number value"
    echo "    ./manage-config.sh set -k \"default_weight\" -v 75 -t number -c rider"
    echo ""
    echo "    # Set a boolean value"
    echo "    ./manage-config.sh set -k \"debug_mode\" -v true -t boolean -c system"
    echo ""
    echo "    # Get a configuration value"
    echo "    ./manage-config.sh get -k \"default_rider_weight\""
    echo ""
    echo "    # List all configuration"
    echo "    ./manage-config.sh list"
    echo ""
    echo "    # List configuration by category"
    echo "    ./manage-config.sh category rider"
    echo ""
    echo "    # Delete a configuration value"
    echo "    ./manage-config.sh delete -k \"old_setting\""
    echo ""
    echo "    # Reset to defaults (WARNING: removes all custom configuration)"
    echo "    ./manage-config.sh reset"
    echo ""
    echo "CONFIGURATION CATEGORIES:"
    echo "    • rider      - Rider-specific settings"
    echo "    • api        - API-related configurations"
    echo "    • processing - Data processing settings"
    echo "    • physics    - Physics calculations parameters"
    echo "    • system     - System-level settings"
    echo "    • export     - Export/import settings"
    echo "    • general    - General settings"
    echo ""
}

check_database_exists() {
    local db_path="$1"
    if [[ ! -f "$db_path" ]]; then
        echo -e "${RED}❌ Database not found: $db_path${NC}"
        echo "Create the database first using create-db.sh or create-db.bat"
        return 1
    fi
    return 0
}

get_config_value() {
    local db_path="$1"
    local key="$2"
    sqlite3 "$db_path" "SELECT value, value_type FROM configuration WHERE key='$key';" 2>/dev/null
}

set_config_value() {
    local db_path="$1"
    local key="$2"
    local value="$3"
    local value_type="$4"
    local description="$5"
    local category="$6"
    
    sqlite3 "$db_path" "
    INSERT INTO configuration (key, value, value_type, description, category, updated_at) 
    VALUES ('$key', '$value', '$value_type', '$description', '$category', CURRENT_TIMESTAMP)
    ON CONFLICT(key) DO UPDATE SET 
        value = excluded.value,
        value_type = excluded.value_type,
        description = excluded.description,
        category = excluded.category,
        updated_at = CURRENT_TIMESTAMP;
    " 2>/dev/null
}

delete_config_value() {
    local db_path="$1"
    local key="$2"
    sqlite3 "$db_path" "DELETE FROM configuration WHERE key='$key';" 2>/dev/null
}

list_all_config() {
    local db_path="$1"
    sqlite3 "$db_path" "SELECT key, value, value_type, description, category, updated_at FROM configuration ORDER BY category, key;" 2>/dev/null
}

list_config_by_category() {
    local db_path="$1"
    local category="$2"
    sqlite3 "$db_path" "SELECT key, value, value_type, description, updated_at FROM configuration WHERE category='$category' ORDER BY key;" 2>/dev/null
}

parse_and_display_value() {
    local value="$1"
    local type="$2"
    
    case "$type" in
        "boolean")
            if [[ "$value" == "true" ]]; then
                echo -e "${GREEN}✅ true${NC}"
            else
                echo -e "${RED}❌ false${NC}"
            fi
            ;;
        "number")
            echo -e "${CYAN}$value${NC}"
            ;;
        "json")
            echo -e "${YELLOW}$value${NC}"
            ;;
        *)
            echo "$value"
            ;;
    esac
}

set_config() {
    local db_path="$1"
    
    if [[ -z "$CONFIG_KEY" ]]; then
        echo -e "${RED}❌ Configuration key is required. Use --key or -k to specify it.${NC}"
        return 1
    fi
    
    if [[ -z "$CONFIG_VALUE" ]]; then
        echo -e "${RED}❌ Configuration value is required. Use --value or -v to specify it.${NC}"
        return 1
    fi
    
    if ! check_database_exists "$db_path"; then
        return 1
    fi
    
    echo -e "${BLUE}⚙️  Setting configuration...${NC}"
    
    set_config_value "$db_path" "$CONFIG_KEY" "$CONFIG_VALUE" "$CONFIG_TYPE" "$CONFIG_DESCRIPTION" "$CONFIG_CATEGORY"
    
    echo -e "${GREEN}✅ Configuration set:${NC}"
    echo "   Key: $CONFIG_KEY"
    echo "   Value: $(parse_and_display_value "$CONFIG_VALUE" "$CONFIG_TYPE")"
    echo "   Type: $CONFIG_TYPE"
    echo "   Category: $CONFIG_CATEGORY"
    if [[ -n "$CONFIG_DESCRIPTION" ]]; then
        echo "   Description: $CONFIG_DESCRIPTION"
    fi
}

get_config() {
    local db_path="$1"
    
    if [[ -z "$CONFIG_KEY" ]]; then
        echo -e "${RED}❌ Configuration key is required. Use --key or -k to specify it.${NC}"
        return 1
    fi
    
    if ! check_database_exists "$db_path"; then
        return 1
    fi
    
    local result=$(get_config_value "$db_path" "$CONFIG_KEY")
    
    if [[ -z "$result" ]]; then
        echo -e "${RED}❌ Configuration key not found: $CONFIG_KEY${NC}"
        return 1
    fi
    
    local value=$(echo "$result" | cut -d'|' -f1)
    local type=$(echo "$result" | cut -d'|' -f2)
    
    echo -e "${BLUE}📋 Configuration value:${NC}"
    echo "   Key: $CONFIG_KEY"
    echo "   Value: $(parse_and_display_value "$value" "$type")"
    echo "   Type: $type"
}

list_config() {
    local db_path="$1"
    
    if ! check_database_exists "$db_path"; then
        return 1
    fi
    
    echo -e "${BLUE}📋 All configuration values:${NC}"
    echo ""
    
    local current_category=""
    
    while IFS='|' read -r key value type description category updated_at; do
        if [[ "$category" != "$current_category" ]]; then
            current_category="$category"
            echo -e "${CYAN}[$category]${NC}"
        fi
        
        echo -n "   $key = "
        parse_and_display_value "$value" "$type"
        
        if [[ -n "$description" ]]; then
            echo "      📝 $description"
        fi
        echo ""
    done < <(list_all_config "$db_path")
}

list_by_category() {
    local db_path="$1"
    local category="$2"
    
    if [[ -z "$category" ]]; then
        echo -e "${RED}❌ Category is required${NC}"
        return 1
    fi
    
    if ! check_database_exists "$db_path"; then
        return 1
    fi
    
    echo -e "${BLUE}📋 Configuration values in category: ${CYAN}$category${NC}"
    echo ""
    
    while IFS='|' read -r key value type description updated_at; do
        echo -n "   $key = "
        parse_and_display_value "$value" "$type"
        
        if [[ -n "$description" ]]; then
            echo "      📝 $description"
        fi
        echo ""
    done < <(list_config_by_category "$db_path" "$category")
}

delete_config() {
    local db_path="$1"
    
    if [[ -z "$CONFIG_KEY" ]]; then
        echo -e "${RED}❌ Configuration key is required. Use --key or -k to specify it.${NC}"
        return 1
    fi
    
    if ! check_database_exists "$db_path"; then
        return 1
    fi
    
    echo -e "${YELLOW}🗑️  Deleting configuration: $CONFIG_KEY${NC}"
    
    delete_config_value "$db_path" "$CONFIG_KEY"
    
    echo -e "${GREEN}✅ Configuration deleted${NC}"
}

reset_config() {
    local db_path="$1"
    
    if ! check_database_exists "$db_path"; then
        return 1
    fi
    
    echo -e "${YELLOW}⚠️  WARNING: This will delete ALL custom configuration and reset to defaults.${NC}"
    echo -n "Are you sure? (y/N): "
    read -r confirmation
    
    if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
        echo "Operation cancelled."
        return 0
    fi
    
    echo -e "${YELLOW}🗑️  Clearing all configuration...${NC}"
    
    sqlite3 "$db_path" "DELETE FROM configuration;" 2>/dev/null
    
    echo -e "${BLUE}📋 Restoring default configuration...${NC}"
    
    # Re-run the default configuration insert statements
    sqlite3 "$db_path" "
    INSERT OR IGNORE INTO configuration (key, value, value_type, description, category) VALUES
    ('default_rider_weight', '70', 'number', 'Default rider weight in kg', 'rider'),
    ('weather_api_key', '', 'string', 'Weather API key (OpenWeatherMap or similar)', 'api'),
    ('weather_api_timeout', '5000', 'number', 'Weather API timeout in milliseconds', 'api'),
    ('weather_api_base_url', 'https://api.openweathermap.org/data/2.5', 'string', 'Weather API base URL', 'api'),
    ('enable_elevation_enhancement', 'true', 'boolean', 'Enable elevation data enhancement', 'processing'),
    ('default_wind_resistance', '0.9', 'number', 'Default wind resistance coefficient', 'physics'),
    ('database_backup_enabled', 'false', 'boolean', 'Enable automatic database backups', 'system'),
    ('max_rides_per_export', '1000', 'number', 'Maximum number of rides per export', 'export');
    " 2>/dev/null
    
    echo -e "${GREEN}✅ Configuration reset to defaults${NC}"
}

# Parse command line arguments
if [[ $# -eq 0 ]]; then
    HELP=true
else
    COMMAND="$1"
    shift
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                HELP=true
                shift
                ;;
            --db)
                if [[ -n "$2" ]]; then
                    DB_PATH="$2"
                    shift 2
                else
                    echo -e "${RED}❌ --db requires a database path${NC}"
                    exit 1
                fi
                ;;
            -k|--key)
                if [[ -n "$2" ]]; then
                    CONFIG_KEY="$2"
                    shift 2
                else
                    echo -e "${RED}❌ --key requires a key name${NC}"
                    exit 1
                fi
                ;;
            -v|--value)
                if [[ -n "$2" ]]; then
                    CONFIG_VALUE="$2"
                    shift 2
                else
                    echo -e "${RED}❌ --value requires a value${NC}"
                    exit 1
                fi
                ;;
            -t|--type)
                if [[ -n "$2" ]]; then
                    CONFIG_TYPE="$2"
                    shift 2
                else
                    echo -e "${RED}❌ --type requires a type${NC}"
                    exit 1
                fi
                ;;
            -d|--description)
                if [[ -n "$2" ]]; then
                    CONFIG_DESCRIPTION="$2"
                    shift 2
                else
                    echo -e "${RED}❌ --description requires a description${NC}"
                    exit 1
                fi
                ;;
            -c|--category)
                if [[ -n "$2" ]]; then
                    CONFIG_CATEGORY="$2"
                    shift 2
                else
                    echo -e "${RED}❌ --category requires a category${NC}"
                    exit 1
                fi
                ;;
            -*)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                echo "Use --help to see available options"
                exit 1
                ;;
            *)
                # For category command, treat as category name
                if [[ "$COMMAND" == "category" && -z "$CONFIG_CATEGORY" ]]; then
                    CONFIG_CATEGORY="$1"
                fi
                shift
                ;;
        esac
    done
fi

# Main execution
if [[ "$HELP" == true ]]; then
    show_help
    exit 0
fi

# Check if sqlite3 is available
if ! command -v sqlite3 &> /dev/null; then
    echo -e "${RED}❌ sqlite3 command not found${NC}"
    echo "Please install SQLite3:"
    echo "  - Ubuntu/Debian: sudo apt-get install sqlite3"
    echo "  - CentOS/RHEL: sudo yum install sqlite"
    echo "  - macOS: brew install sqlite3"
    exit 1
fi

echo -e "${CYAN}⚙️  Configuration Manager${NC}"
echo ""

case "$COMMAND" in
    set)
        if set_config "$DB_PATH"; then
            exit 0
        else
            exit 1
        fi
        ;;
    get)
        if get_config "$DB_PATH"; then
            exit 0
        else
            exit 1
        fi
        ;;
    list)
        if list_config "$DB_PATH"; then
            exit 0
        else
            exit 1
        fi
        ;;
    delete)
        if delete_config "$DB_PATH"; then
            exit 0
        else
            exit 1
        fi
        ;;
    category)
        if list_by_category "$DB_PATH" "$CONFIG_CATEGORY"; then
            exit 0
        else
            exit 1
        fi
        ;;
    reset)
        if reset_config "$DB_PATH"; then
            exit 0
        else
            exit 1
        fi
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $COMMAND${NC}"
        echo "Available commands: set, get, list, delete, category, reset"
        echo "Use --help to see detailed usage information"
        exit 1
        ;;
esac