# 🚴 Elevation-Adjusted Cycling Calorie Calculator

A comprehensive Node.js application that calculates calorie burn for cycling activities with precise elevation adjustments, weather impact analysis, and high-resolution elevation data enhancement.

## Features

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

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/cycling-calorie-calculator.git
cd cycling-calorie-calculator
```

2. Install dependencies:
```bash
npm install
```

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

```bash
node index.js <weight_kg> <gpx_file_path>
```

**Example:**
```bash
node index.js 70 ./examples/sample-ride.gpx
```

The calculator automatically extracts coordinates from the first trackpoint in the GPX file for weather data lookup.

### As a Module

```javascript
const CyclingCalorieCalculator = require('./index.js');

const calculator = new CyclingCalorieCalculator({
    gpxzApiKey: 'your_gpxz_api_key',
    weatherApiKey: 'your_weather_api_key'
});

const result = await calculator.calculateCalorieBurn({
    weight: 70,
    gpxFilePath: './ride.gpx'
});

console.log(`Total calories burned: ${result.summary.totalCalories} kcal`);
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

### Error Handling

- Graceful fallbacks when API keys are not available
- Continues with original elevation data if GPXZ enhancement fails
- Uses default weather conditions if weather API is unavailable
- Comprehensive error messages for debugging

## File Structure

```
cycling-calorie-calculator/
├── index.js                 # Main application file
├── package.json            # Dependencies and scripts
├── README.md              # This file
├── examples/
│   ├── example.js         # Usage examples
│   └── sample-ride.gpx    # Sample GPX file
├── test/
│   └── test.js           # Basic tests
└── .env.example          # Environment variables template
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

## Future Enhancements

- Support for power meter data integration
- Heart rate zone analysis
- Multiple weather station data sources
- Advanced aerodynamic calculations
- GUI interface
- Export to fitness platforms

## Support

For issues and questions:
1. Check existing GitHub issues
2. Create a new issue with detailed description
3. Include sample GPX files when possible