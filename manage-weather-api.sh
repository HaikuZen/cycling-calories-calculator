#!/bin/bash

# Bash script to manage weather API key configuration
set -e  # Exit on any error

# Default values
DB_PATH="cycling_data.db"
COMMAND=""
API_KEY=""
BASE_URL=""
TIMEOUT=""
SHOW_KEY=false
HELP=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${CYAN}🌤️  Weather API Key Manager${NC}"
    echo ""
    echo "USAGE:"
    echo "    ./manage-weather-api.sh <command> [options]"
    echo ""
    echo "COMMANDS:"
    echo "    set                Set weather API key and configuration"
    echo "    get                Get current weather API configuration"
    echo "    check              Check if API key is configured"
    echo "    clear              Clear the weather API key"
    echo ""
    echo "OPTIONS:"
    echo "    -k, --key <key>    Weather API key"
    echo "    -u, --url <url>    Weather API base URL"
    echo "    -t, --timeout <ms> API timeout in milliseconds"
    echo "    -d, --db <path>    Database file path (default: ./cycling_data.db)"
    echo "    -s, --show         Show API key value (otherwise masked)"
    echo "    -h, --help         Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "    # Set API key"
    echo "    ./manage-weather-api.sh set --key \"your-api-key-here\""
    echo ""
    echo "    # Set API key with custom URL and timeout"
    echo "    ./manage-weather-api.sh set -k \"api-key\" -u \"https://api.weather.com\" -t 10000"
    echo ""
    echo "    # Get current configuration"
    echo "    ./manage-weather-api.sh get"
    echo ""
    echo "    # Show configuration with visible API key"
    echo "    ./manage-weather-api.sh get --show"
    echo ""
    echo "    # Check if API key is configured"
    echo "    ./manage-weather-api.sh check"
    echo ""
    echo "    # Clear API key"
    echo "    ./manage-weather-api.sh clear"
    echo ""
    echo "    # Use different database"
    echo "    ./manage-weather-api.sh get --db ./production_data.db"
    echo ""
    echo "WEATHER API PROVIDERS:"
    echo "    • OpenWeatherMap: https://openweathermap.org/api"
    echo "    • WeatherAPI: https://www.weatherapi.com/"
    echo "    • AccuWeather: https://developer.accuweather.com/"
    echo "    • Visual Crossing: https://www.visualcrossing.com/weather-api"
    echo ""
    echo "NOTES:"
    echo "    - API keys are stored securely in the database"
    echo "    - Use environment variables for sensitive keys in production"
    echo "    - Some commands may require the database to exist first"
    echo ""
}

mask_api_key() {
    local api_key="$1"
    if [[ ${#api_key} -lt 8 ]]; then
        echo "$api_key"
    else
        echo "${api_key:0:4}****${api_key: -4}"
    fi
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
    sqlite3 "$db_path" "SELECT value FROM configuration WHERE key='$key';" 2>/dev/null || echo ""
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

has_weather_api_key() {
    local db_path="$1"
    local api_key=$(get_config_value "$db_path" "weather_api_key")
    if [[ -n "$api_key" && "$api_key" != "" ]]; then
        return 0
    else
        return 1
    fi
}

set_api_key() {
    local db_path="$1"
    
    if [[ -z "$API_KEY" ]]; then
        echo -e "${RED}❌ API key is required. Use --key or -k to specify it.${NC}"
        return 1
    fi
    
    if ! check_database_exists "$db_path"; then
        return 1
    fi
    
    echo -e "${BLUE}🔑 Setting weather API configuration...${NC}"
    
    # Set API key
    set_config_value "$db_path" "weather_api_key" "$API_KEY" "string" "Weather API key (OpenWeatherMap or similar)" "api"
    
    # Set base URL if provided
    if [[ -n "$BASE_URL" ]]; then
        set_config_value "$db_path" "weather_api_base_url" "$BASE_URL" "string" "Weather API base URL" "api"
    fi
    
    # Set timeout if provided
    if [[ -n "$TIMEOUT" ]]; then
        set_config_value "$db_path" "weather_api_timeout" "$TIMEOUT" "number" "Weather API timeout in milliseconds" "api"
    fi
    
    # Get updated configuration
    local updated_key=$(get_config_value "$db_path" "weather_api_key")
    local updated_url=$(get_config_value "$db_path" "weather_api_base_url")
    local updated_timeout=$(get_config_value "$db_path" "weather_api_timeout")
    
    echo -e "${GREEN}✅ Weather API configuration updated:${NC}"
    if [[ "$SHOW_KEY" == true ]]; then
        echo "   API Key: $updated_key"
    else
        echo "   API Key: $(mask_api_key "$updated_key")"
    fi
    echo "   Base URL: ${updated_url:-'Not set'}"
    echo "   Timeout: ${updated_timeout:-'Not set'}ms"
    
    if has_weather_api_key "$db_path"; then
        echo "   Status: ✅ Configured"
    else
        echo "   Status: ❌ Not configured"
    fi
}

get_api_key() {
    local db_path="$1"
    
    if ! check_database_exists "$db_path"; then
        return 1
    fi
    
    echo -e "${BLUE}📋 Current weather API configuration:${NC}"
    
    local api_key=$(get_config_value "$db_path" "weather_api_key")
    local base_url=$(get_config_value "$db_path" "weather_api_base_url")
    local timeout=$(get_config_value "$db_path" "weather_api_timeout")
    
    if [[ -n "$api_key" && "$api_key" != "" ]]; then
        if [[ "$SHOW_KEY" == true ]]; then
            echo "   API Key: $api_key"
        else
            echo "   API Key: $(mask_api_key "$api_key")"
        fi
    else
        echo "   API Key: ❌ Not configured"
    fi
    
    echo "   Base URL: ${base_url:-'Not set'}"
    echo "   Timeout: ${timeout:-'Not set'}ms"
    
    if has_weather_api_key "$db_path"; then
        echo "   Status: ✅ Configured"
    else
        echo "   Status: ❌ Not configured"
        echo ""
        echo -e "${CYAN}💡 To set an API key, use:${NC}"
        echo "   ./manage-weather-api.sh set --key \"your-api-key-here\""
    fi
}

check_api_key() {
    local db_path="$1"
    
    if ! check_database_exists "$db_path"; then
        return 1
    fi
    
    if has_weather_api_key "$db_path"; then
        local api_key=$(get_config_value "$db_path" "weather_api_key")
        local base_url=$(get_config_value "$db_path" "weather_api_base_url")
        
        echo -e "${GREEN}✅ Weather API key is configured${NC}"
        echo "   Provider: ${base_url:-'Default'}"
        echo "   Key length: ${#api_key} characters"
        return 0
    else
        echo -e "${RED}❌ Weather API key is not configured${NC}"
        echo "   Use \"set\" command to configure it"
        return 1
    fi
}

clear_api_key() {
    local db_path="$1"
    
    if ! check_database_exists "$db_path"; then
        return 1
    fi
    
    echo -e "${YELLOW}🗑️  Clearing weather API key...${NC}"
    
    set_config_value "$db_path" "weather_api_key" "" "string" "Weather API key (OpenWeatherMap or similar)" "api"
    
    echo -e "${GREEN}✅ Weather API key cleared${NC}"
    
    if has_weather_api_key "$db_path"; then
        echo "   Status: ✅ Still configured"
    else
        echo "   Status: ❌ Not configured"
    fi
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
            -d|--db)
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
                    API_KEY="$2"
                    shift 2
                else
                    echo -e "${RED}❌ --key requires an API key${NC}"
                    exit 1
                fi
                ;;
            -u|--url)
                if [[ -n "$2" ]]; then
                    BASE_URL="$2"
                    shift 2
                else
                    echo -e "${RED}❌ --url requires a URL${NC}"
                    exit 1
                fi
                ;;
            -t|--timeout)
                if [[ -n "$2" ]]; then
                    TIMEOUT="$2"
                    shift 2
                else
                    echo -e "${RED}❌ --timeout requires a timeout value${NC}"
                    exit 1
                fi
                ;;
            -s|--show)
                SHOW_KEY=true
                shift
                ;;
            -*)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                echo "Use --help to see available options"
                exit 1
                ;;
            *)
                # If it looks like an API key, use it as such
                if [[ ${#1} -gt 10 && "$1" != *" "* ]]; then
                    API_KEY="$1"
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

echo -e "${CYAN}🌤️  Weather API Key Manager${NC}"
echo ""

case "$COMMAND" in
    set)
        if set_api_key "$DB_PATH"; then
            exit 0
        else
            exit 1
        fi
        ;;
    get)
        if get_api_key "$DB_PATH"; then
            exit 0
        else
            exit 1
        fi
        ;;
    check)
        if check_api_key "$DB_PATH"; then
            exit 0
        else
            exit 1
        fi
        ;;
    clear)
        if clear_api_key "$DB_PATH"; then
            exit 0
        else
            exit 1
        fi
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $COMMAND${NC}"
        echo "Available commands: set, get, check, clear"
        echo "Use --help to see detailed usage information"
        exit 1
        ;;
esac