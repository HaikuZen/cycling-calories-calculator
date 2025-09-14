-- Cycling Calorie Calculator Database Schema
-- This file contains all SQL statements needed to create the database structure

-- Create rides table
CREATE TABLE IF NOT EXISTS rides (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    gpx_filename TEXT,
    rider_weight REAL NOT NULL,
    ride_date TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    -- Route data
    distance REAL NOT NULL,
    duration REAL,
    elevation_gain REAL,
    average_speed REAL,
    start_latitude REAL,
    start_longitude REAL,
    
    -- Calorie calculation results
    total_calories INTEGER NOT NULL,
    base_calories INTEGER,
    elevation_calories INTEGER,
    wind_adjustment INTEGER,
    environmental_adjustment INTEGER,
    base_met REAL,
    calories_per_km INTEGER,
    calories_per_hour INTEGER,
    
    -- Weather data
    wind_speed REAL,
    wind_direction REAL,
    humidity REAL,
    temperature REAL,
    pressure REAL,
    weather_source TEXT,
    
    -- Metadata
    elevation_enhanced BOOLEAN DEFAULT 0,
    has_elevation_data BOOLEAN DEFAULT 0
);

-- Create calorie breakdown table
CREATE TABLE IF NOT EXISTS calorie_breakdown (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ride_id INTEGER NOT NULL,
    factor TEXT NOT NULL,
    calories INTEGER NOT NULL,
    percentage INTEGER NOT NULL,
    description TEXT,
    FOREIGN KEY (ride_id) REFERENCES rides (id) ON DELETE CASCADE
);

-- Create configuration table
CREATE TABLE IF NOT EXISTS configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    value_type TEXT NOT NULL DEFAULT 'string',
    description TEXT,
    category TEXT DEFAULT 'general',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_rides_date ON rides (ride_date);
CREATE INDEX IF NOT EXISTS idx_rides_distance ON rides (distance);
CREATE INDEX IF NOT EXISTS idx_rides_calories ON rides (total_calories);
CREATE INDEX IF NOT EXISTS idx_breakdown_ride ON calorie_breakdown (ride_id);
CREATE INDEX IF NOT EXISTS idx_config_key ON configuration (key);
CREATE INDEX IF NOT EXISTS idx_config_category ON configuration (category);

-- Insert default configuration values
INSERT OR IGNORE INTO configuration (key, value, value_type, description, category) VALUES
('default_rider_weight', '75', 'number', 'Default rider weight in kg', 'rider'),
('weather_api_key', '', 'string', 'Weather API key (OpenWeatherMap or similar)', 'api'),
('weather_api_timeout', '5000', 'number', 'Weather API timeout in milliseconds', 'api'),
('weather_api_base_url', 'https://api.openweathermap.org/data/2.5', 'string', 'Weather API base URL', 'api'),
('enable_elevation_enhancement', 'true', 'boolean', 'Enable elevation data enhancement', 'processing'),
('default_wind_resistance', '0.9', 'number', 'Default wind resistance coefficient', 'physics'),
('database_backup_enabled', 'false', 'boolean', 'Enable automatic database backups', 'system'),
('max_rides_per_export', '1000', 'number', 'Maximum number of rides per export', 'export');
