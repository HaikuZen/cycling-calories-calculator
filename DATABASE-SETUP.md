# Database Setup Guide

The Cycling Calorie Calculator uses SQLite to store ride data, calorie calculations, and configuration settings. This guide explains how to create and set up the database.

## Quick Start

### Option 1: Using Scripts

**Windows (Batch):**
```cmd
# Create default database
create-db.bat

# Create database with custom name
create-db.bat my_rides.db

# Force overwrite existing database
create-db.bat --force

# Show help
create-db.bat --help
```

**Linux/macOS (Bash):**
```bash
# Make script executable (first time only)
chmod +x create-db.sh

# Create default database
./create-db.sh

# Create database with custom name
./create-db.sh my_rides.db

# Force overwrite existing database
./create-db.sh --force --verbose

# Show help
./create-db.sh --help
```

### Option 2: Using npm Scripts
```cmd
# Create default database (if sqlite3 is working)
npm run init-db

# Force overwrite with verbose output
npm run init-db:force

# Using PowerShell script
npm run create-db
npm run create-db:force

# Using bash script
npm run create-db:bash
```

### Option 3: Manual Setup
1. Download SQLite3 from: https://sqlite.org/download.html
2. Extract `sqlite3.exe` to your PATH or project directory
3. Run: `sqlite3 cycling_data.db ".read schema.sql"`

## Database Structure

The database contains three main tables:

### `rides` Table
Stores cycling ride data and calorie calculations:
- Route information (distance, duration, elevation)
- Calorie calculation results
- Weather data
- GPX file metadata

### `calorie_breakdown` Table
Stores detailed breakdown of calorie calculations per ride:
- Calorie factors (base, elevation, wind, etc.)
- Percentages and descriptions

### `configuration` Table
Stores application configuration settings:
- Default rider weight
- API timeouts and settings
- Processing preferences
- System settings

## Default Configuration

The following default values are automatically created:

| Key | Value | Type | Category | Description |
|-----|-------|------|----------|-------------|
| `default_rider_weight` | 70 | number | rider | Default rider weight in kg |
| `weather_api_key` | '' | string | api | Weather API key (OpenWeatherMap or similar) |
| `weather_api_timeout` | 5000 | number | api | Weather API timeout in milliseconds |
| `weather_api_base_url` | https://api.openweathermap.org/data/2.5 | string | api | Weather API base URL |
| `enable_elevation_enhancement` | true | boolean | processing | Enable elevation data enhancement |
| `default_wind_resistance` | 0.9 | number | physics | Default wind resistance coefficient |
| `database_backup_enabled` | false | boolean | system | Enable automatic database backups |
| `max_rides_per_export` | 1000 | number | export | Maximum number of rides per export |

## Configuration Management

```javascript
const CyclingDatabase = require('./database.js');
const db = new CyclingDatabase();
await db.initialize();

// Set configuration
await db.setConfig('rider_name', 'John Doe', 'string', 'Rider name', 'rider');
await db.setConfig('preferred_units', 'metric', 'string', 'Measurement units', 'ui');

// Get configuration
const riderWeight = await db.getConfig('default_rider_weight'); // Returns: 70
const riderName = await db.getConfig('rider_name', 'Unknown'); // With default value

// Get all config for a category
const riderConfig = await db.getAllConfig('rider');

// Delete configuration
await db.deleteConfig('old_setting');

// Weather API specific methods
await db.setWeatherApiKey('your-api-key-here');
const apiKey = await db.getWeatherApiKey();
const hasKey = await db.hasWeatherApiKey();
const weatherConfig = await db.getWeatherApiConfig();
```

## Weather API Management

The application includes specialized tools for managing weather API configuration:

### Using Command Line Tools

**Node.js Version:**
```cmd
# Set weather API key
node manage-weather-api.js set --key "your-api-key-here"

# Get current configuration (masked)
node manage-weather-api.js get

# Show configuration with visible API key
node manage-weather-api.js get --show

# Check if API key is configured
node manage-weather-api.js check

# Clear API key
node manage-weather-api.js clear

# Set with custom URL and timeout
node manage-weather-api.js set -k "api-key" -u "https://api.weather.com" -t 10000
```

**Bash Version (Linux/macOS):**
```bash
# Make script executable (first time only)
chmod +x manage-weather-api.sh

# Set weather API key
./manage-weather-api.sh set --key "your-api-key-here"

# Get current configuration
./manage-weather-api.sh get

# Check if configured
./manage-weather-api.sh check
```

### Using npm Scripts
```cmd
# Get weather API configuration
npm run weather-api:get

# Check if API key is configured
npm run weather-api:check

# Use bash version
npm run weather-api:bash get
```

### General Configuration Management

**Bash Version:**
```bash
# Make script executable (first time only)
chmod +x manage-config.sh

# Set configuration values
./manage-config.sh set -k "rider_name" -v "John Doe" -d "Rider name"
./manage-config.sh set -k "debug_mode" -v true -t boolean -c system

# Get configuration value
./manage-config.sh get -k "default_rider_weight"

# List all configuration
./manage-config.sh list

# List by category
./manage-config.sh category api

# Delete configuration
./manage-config.sh delete -k "old_setting"
```

## Files Created

### Database Schema
- **`schema.sql`** - Complete database schema with all tables and default data

### Database Creation Scripts
- **`create-db.bat`** - Windows batch script for database creation
- **`create-db.sh`** - Bash script for database creation (Linux/macOS)
- **`create-db.ps1`** - PowerShell script for database creation
- **`init-db.js`** - Node.js script for database creation (requires working sqlite3)

### Configuration Management Scripts
- **`manage-weather-api.js`** - Node.js script for weather API key management
- **`manage-weather-api.sh`** - Bash script for weather API key management
- **`manage-config.sh`** - Bash script for general configuration management

### Test and Example Scripts
- **`test_config.js`** - Test script demonstrating configuration functionality

## Troubleshooting

### SQLite3 Not Found
If you see "sqlite3 command not found":
1. Download SQLite3 tools from https://sqlite.org/download.html
2. For Windows: download `sqlite-tools-win32-x86-*.zip`
3. Extract `sqlite3.exe` to your project directory or add to PATH

### Node.js sqlite3 Module Issues
If the Node.js scripts fail:
1. Try using the batch script instead: `create-db.bat`
2. Or create database manually using a SQLite browser tool
3. Use the provided `schema.sql` file with any SQLite tool

### Alternative GUI Tools
- **DB Browser for SQLite**: https://sqlitebrowser.org/
- **SQLiteStudio**: https://sqlitestudio.pl/
- **DBeaver**: https://dbeaver.io/ (supports SQLite)

## Examples

```cmd
# Create database in subdirectory
create-db.bat data\cycling_rides.db

# Create test database
create-db.bat test\test_rides.db --force

# Create database with verbose output (Node.js)
node init-db.js --verbose --path ./production_data.db
```

## Database File Location

By default, databases are created in the current directory. The recommended names:
- **Development**: `cycling_data_dev.db`
- **Testing**: `cycling_data_test.db`
- **Production**: `cycling_data.db`

## Backup Recommendations

1. Regular backups: Copy the `.db` file to a safe location
2. Export to JSON: Use `db.exportToJSON()` method
3. Version control: Add `.db` files to `.gitignore` but keep schema files tracked
4. Cloud backup: Store database files in cloud storage for important data

## Application Usage

Once your database is created, you can use the main application with the new argument format:

### New Format (Recommended)
```bash
# Use default weight from database
node index.js ride.gpx

# Use default weight with rider ID tracking
node index.js ride.gpx --rider-id alice

# Legacy format (still supported)
node index.js 70 ride.gpx
```

### Setting Default Weight
```bash
# Using configuration management
./manage-config.sh set -k "default_rider_weight" -v 72 -t number -c rider

# Or using Node.js
node -e "const db=require('./database');(async()=>{const d=new db();await d.initialize();await d.setConfig('default_rider_weight',72,'number','Default rider weight','rider');await d.close()})();"
```

## Testing and Validation

```bash
# Test configuration system
npm run test-config

# Test new argument format
npm run test-args

# Test weather API configuration
npm run weather-api:check
```

## Next Steps

Once your database is created:
1. Set your default rider weight: `./manage-config.sh set -k "default_rider_weight" -v YOUR_WEIGHT -t number`
2. Configure weather API key: `node manage-weather-api.js set --key "your-api-key"`
3. Test the system: `npm run test-args`
4. Start importing GPX files: `node index.js your_ride.gpx`
5. Explore the database using your preferred SQLite browser
6. View ride history: `node index.js --history`
