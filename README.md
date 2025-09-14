# 🚴 Elevation-Adjusted Cycling Calorie Calculator with SQLite Database

A comprehensive Node.js application that calculates calorie burn for cycling activities with precise elevation adjustments, weather impact analysis, high-resolution elevation data enhancement, and **automatic data persistence using SQLite database**.

## Features

### Core Calculation Features
- **GPX File Processing**: Parse GPX files to extract distance, duration, and elevation data
- **Elevation Enhancement**: Uses GPXZ.io API to add high-resolution elevation data to low-quality GPX files
- **Weather Integration**: Incorporates weather data for accurate calculations:
  - **Historical Weather**: For rides older than 5 days, fetches historical weather data
  - **Current Weather**: For recent rides, uses current weather conditions
  - Considers wind, humidity, and temperature impacts
- **Smart Date Detection**: Automatically extracts ride date from GPX timestamps
- **Advanced Calorie Modeling**: Considers multiple factors:
  - Base metabolic equivalent (MET) values based on cycling speed
  - Elevation gain adjustments
  - Wind resistance calculations
  - Temperature and humidity impacts
- **Detailed Analytics**: Provides comprehensive breakdown of calorie burn factors

### 🆕 New Database Features
- **Automatic Data Storage**: All calculations are automatically saved to a local SQLite database
- **Ride History**: View your past rides with `--history` command
- **Comprehensive Statistics**: Track your progress with `--stats` command
- **Data Export**: Export all your data to JSON format with `--export` command
- **Date Range Queries**: Query rides within specific date ranges
- **Detailed Ride Breakdown**: Store and retrieve detailed calorie breakdown for each ride
- **Local Storage**: All data stored locally - no external dependencies or privacy concerns

## Installation

1. Clone the repository:
```bash
git clone https://github.com/HaikuZen/cycling-calories-calculator.git
cd cycling-calorie-calculator
```

2. Install dependencies:
```bash
npm install
```
**Note**: The sqlite3 package is now included for database functionality.

3. Set up API keys (optional but recommended):
```bash
export GPXZ_API_KEY="your_gpxz_api_key"
export WEATHER_API_KEY="your_openweathermap_api_key"
```

## API Keys Setup

### GPXZ.io API Key (Free)
1. Visit [gpxz.io](https://gpxz.io)
2. Sign up for a free account
3. Get your API key from the dashboard
4. The free tier includes 1000 requests per month

### OpenWeatherMap API Key (Free/Paid)
1. Visit [OpenWeatherMap API](https://openweathermap.org/api)
2. Sign up for a free account
3. Get your API key
4. **Free tier**: Current weather only (1000 calls/day)
5. **Paid tier**: Historical weather access required for rides older than 5 days

**Note**: Historical weather data (for rides older than 5 days) requires a paid OpenWeatherMap subscription. The free tier will fall back to current weather conditions with a warning.

## Usage

### Command Line Interface

#### Basic Calorie Calculation (with automatic database storage)
```bash
node index.js <weight_kg> <gpx_file_path>
```

**Example:**
```bash
node index.js 70 ./examples/sample-ride.gpx
```

#### Database Commands
```bash
# View your ride history (last 10 rides by default)
node index.js --history

# View last 20 rides
node index.js --history 20

# Show comprehensive riding statistics
node index.js --stats

# Export all data to JSON file
node index.js --export

# Export to custom file
node index.js --export my-cycling-data.json

# Show help
node index.js --help
```

The calculator automatically extracts coordinates from the first trackpoint in the GPX file for weather data lookup and **saves all results to a local SQLite database**.

### As a Module

#### Basic Usage (with database storage)
```javascript
const CyclingCalorieCalculator = require('./index.js');

const calculator = new CyclingCalorieCalculator({
    gpxzApiKey: 'your_gpxz_api_key',
    weatherApiKey: 'your_weather_api_key',
    saveToDatabase: true, // Default: true
    databasePath: './my-cycling-data.db' // Optional custom path
});

const result = await calculator.calculateCalorieBurn({
    weight: 70,
    gpxFilePath: './ride.gpx'
});

console.log(`Total calories burned: ${result.summary.totalCalories} kcal`);
console.log(`Saved as ride ID: ${result.rideId}`);
```

#### Database Operations
```javascript
// Get ride history
const recentRides = await calculator.getHistoricalRides(10);
console.log(`Found ${recentRides.length} recent rides`);

// Get comprehensive statistics
const stats = await calculator.getRideStatistics();
console.log(`Total distance: ${stats.total_distance} km`);
console.log(`Average speed: ${stats.avg_speed} km/h`);
console.log(`Total calories: ${stats.total_calories} kcal`);

// Get rides in date range
const startDate = new Date('2024-01-01');
const endDate = new Date('2024-12-31');
const ridesInRange = await calculator.getRidesByDateRange(startDate, endDate);

// Export all data
await calculator.exportData('./backup.json');
```

#### Disable Database Storage (for one-time calculations)
```javascript
const calculator = new CyclingCalorieCalculator({
    saveToDatabase: false // Disable database storage
});
```

## Sample Output

```
🚴 Starting elevation-adjusted calorie burn calculation...
📊 GPX Data: 25.3km, 87.5min, 1247 points
🔍 Enhancing elevation data with GPXZ...
⛰️  Enhanced elevation gain: 456.2m
🌤️  Weather: 3.2m/s, 68%

🎯 CALORIE BURN RESULTS
========================
Total Calories: 892 kcal
Distance: 25.3 km
Duration: 87.5 minutes
Elevation Gain: 456.2 m
Average Speed: 17.4 km/h
Calories per km: 35 kcal/km
Calories per hour: 612 kcal/h

📍 LOCATION & TIME
===================
Start coordinates: 45.464200, 9.190000
Ride date: Wed Aug 21 2024
Ride time: 8:00:00 AM

📊 BREAKDOWN
=============
Base Activity: 698 kcal (78%)
  MET 6.8 cycling activity
Elevation Gain: 136 kcal (15%)
  Additional energy for climbing
Wind Resistance: 42 kcal (5%)
  Wind conditions impact
Environmental: 16 kcal (2%)
  Temperature and humidity effects

🌤️ WEATHER CONDITIONS
====================
Date: Wed Aug 21 2024
Wind: 3.2 m/s
Humidity: 68%
Temperature: 18°C
Data source: historical

✅ Elevation data enhanced with GPXZ

💾 DATA SAVED
==========
Ride ID: 15
Data has been saved to the database.
Use --history to view past rides or --stats for statistics.
```

### Database Command Examples

#### Ride History Output
```
📊 RIDE HISTORY (Last 5 rides)
==================================================

1. Ride #15 - 12/14/2024
   File: morning-commute.gpx
   Distance: 15.2km, Duration: 45.3min
   Calories: 456 kcal (30 kcal/km)
   Elevation: 123m, Speed: 20.1km/h
   Weight: 70kg

2. Ride #14 - 12/13/2024
   File: weekend-long-ride.gpx
   Distance: 52.7km, Duration: 168.4min
   Calories: 1,678 kcal (32 kcal/km)
   Elevation: 892m, Speed: 18.8km/h
   Weight: 70kg
```

#### Statistics Output
```
📈 RIDING STATISTICS
==============================
Total Rides: 15
Total Distance: 487.3 km
Total Duration: 25.8 hours
Total Elevation Gain: 6,245 m
Total Calories Burned: 15,847 kcal
Average Speed: 18.9 km/h
Average Calories/km: 33 kcal/km
First Ride: 11/15/2024
Last Ride: 12/14/2024
```

## Technical Details

### Calorie Calculation Methodology

1. **Base Calories**: Uses MET (Metabolic Equivalent) values based on cycling speed:
   - < 16 km/h: 4.0 MET (light effort)
   - 16-19 km/h: 6.8 MET (moderate effort)
   - 19-22 km/h: 8.5 MET (vigorous effort)
   - 22-25 km/h: 10.0 MET (very vigorous)
   - > 25 km/h: 12.0 MET (racing)

2. **Elevation Adjustment**: ~10 calories per kg per 100m of elevation gain

3. **Wind Resistance**: Calculated using simplified aerodynamic model considering:
   - Rider speed
   - Wind speed and direction
   - Exponential relationship between speed and air resistance

4. **Environmental Factors**:
   - Temperature: Optimal range 15-25°C, deviations increase energy expenditure
   - Humidity: Higher humidity increases calorie burn

### GPX Processing

The application handles:
- Multi-segment tracks
- Missing elevation data
- Time-based duration calculation
- Distance calculation using Haversine formula
- Automatic data validation and cleanup

### Database Schema

The application creates two main tables:

#### `rides` Table
- **Route Data**: Distance, duration, elevation gain, average speed, GPS coordinates
- **Rider Data**: Weight, ride date/time
- **Calorie Results**: Total calories, breakdown by factor, rates per km/hour
- **Weather Data**: Wind speed/direction, humidity, temperature, pressure
- **Metadata**: GPX filename, data enhancement flags, timestamps

#### `calorie_breakdown` Table
- **Detailed Factors**: Base activity, elevation, wind resistance, environmental
- **Percentages**: Contribution of each factor to total calorie burn
- **Descriptions**: Human-readable explanations for each factor

### Error Handling

- Graceful fallbacks when API keys are not available
- Continues with original elevation data if GPXZ enhancement fails
- Uses default weather conditions if weather API is unavailable
- Database operations continue even if database save fails
- Comprehensive error messages for debugging

## File Structure

```
cycling-calorie-calculator/
├── index.js                    # Main application file
├── database.js                # Database operations module
├── package.json               # Dependencies and scripts
├── README.md                  # This file
├── cycling_data.db            # SQLite database (auto-created)
├── examples/
│   ├── example.js            # Usage examples
│   └── sample-ride.gpx       # Sample GPX file
├── test/
│   └── test.js              # Basic tests
└── .env.example             # Environment variables template
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -am 'Add feature'`
4. Push to branch: `git push origin feature-name`
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Limitations

- GPXZ free tier: 1000 elevation requests per month
- Weather API free tier: 1000 calls per day
- Wind direction calculation assumes straight-line riding direction
- Environmental factors use simplified models

## Database Notes

- **Local Storage**: All data is stored locally in `cycling_data.db` - no external servers
- **Privacy**: Your ride data never leaves your machine
- **Backup**: Use `--export` command to create JSON backups
- **Portability**: Database file can be copied to other machines
- **Size**: Typical database grows ~1KB per ride

## Future Enhancements

- Support for power meter data integration
- Heart rate zone analysis
- Multiple weather station data sources
- Advanced aerodynamic calculations
- GUI interface for database exploration
- Export to fitness platforms (Strava, etc.)
- Data visualization charts and graphs
- Training load and recovery analysis

## Support

For issues and questions:
1. Check existing GitHub issues
2. Create a new issue with detailed description
3. Include sample GPX files when possible