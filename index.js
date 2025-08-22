// cycling-calorie-calculator/index.js
const fs = require('fs').promises;
const path = require('path');
const axios = require('axios');
const xml2js = require('xml2js');

class CyclingCalorieCalculator {
    constructor(config = {}) {
        this.config = {
            gpxzApiKey: config.gpxzApiKey || process.env.GPXZ_API_KEY,
            weatherApiKey: config.weatherApiKey || process.env.WEATHER_API_KEY,
            weatherApiUrl: config.weatherApiUrl || 'http://api.openweathermap.org/data/2.5/weather',
            weatherHistoricalApiUrl: config.weatherHistoricalApiUrl || 'http://api.openweathermap.org/data/3.0/onecall/timemachine',
            gpxzApiUrl: config.gpxzApiUrl || 'https://api.gpxz.io/v1/elevation/point',
            ...config
        };
    }

    /**
     * Main calculation function
     * @param {Object} params - Calculation parameters
     * @param {number} params.weight - Rider weight in kg
     * @param {string} params.gpxFilePath - Path to GPX file
     * @returns {Object} Detailed calorie burn analysis
     */
    async calculateCalorieBurn(params) {
        try {
            console.log('🚴 Starting elevation-adjusted calorie burn calculation...');
            
            // Step 1: Parse GPX file
            const gpxData = await this.parseGpxFile(params.gpxFilePath);
            console.log(`📊 GPX Data: ${gpxData.distance}km, ${gpxData.duration}min, ${gpxData.points.length} points`);
            console.log(`📍 Location: ${gpxData.startLocation.lat}, ${gpxData.startLocation.lon}`);
            
            // Step 2: Enhance elevation data using GPXZ
            const enhancedGpxData = await this.enhanceElevationData(gpxData);
            console.log(`⛰️  Enhanced elevation gain: ${enhancedGpxData.elevationGain}m`);
            
            // Step 3: Get weather data using coordinates and date from GPX
            const weatherData = await this.getWeatherData(
                gpxData.startLocation.lat, 
                gpxData.startLocation.lon, 
                gpxData.startTime
            );
            console.log(`🌤️  Weather for ${gpxData.startTime ? gpxData.startTime.toDateString() : 'today'}: ${weatherData.windSpeed}m/s, ${weatherData.humidity}%`);
            
            // Step 4: Calculate calories with all factors
            const calorieData = this.calculateDetailedCalories({
                weight: params.weight,
                distance: enhancedGpxData.distance,
                duration: enhancedGpxData.duration,
                elevationGain: enhancedGpxData.elevationGain,
                averageSpeed: enhancedGpxData.averageSpeed,
                weather: weatherData
            });
            
            return {
                summary: calorieData,
                gpxData: enhancedGpxData,
                weatherData,
                breakdown: this.getCalorieBreakdown(calorieData),
                location: gpxData.startLocation
            };
            
        } catch (error) {
            console.error('❌ Error calculating calories:', error.message);
            throw error;
        }
    }

    /**
     * Parse GPX file and extract basic data
     */
    async parseGpxFile(filePath) {
        try {
            const gpxContent = await fs.readFile(filePath, 'utf-8');
            const parser = new xml2js.Parser();
            const result = await parser.parseStringPromise(gpxContent);
            
            const track = result.gpx.trk[0];
            const segments = track.trkseg;
            
            let points = [];
            let totalDistance = 0;
            let totalElevationGain = 0;
            let minTime, maxTime;
            let startLocation = null;
            let startTime = null;
            
            for (const segment of segments) {
                const segmentPoints = segment.trkpt.map(point => ({
                    lat: parseFloat(point.$.lat),
                    lon: parseFloat(point.$.lon),
                    ele: point.ele ? parseFloat(point.ele[0]) : null,
                    time: point.time ? new Date(point.time[0]) : null
                }));
                
                points = points.concat(segmentPoints);
            }
            
            // Get starting location and time from first trackpoint
            if (points.length > 0) {
                startLocation = {
                    lat: points[0].lat,
                    lon: points[0].lon
                };
                
                // Find first point with time data
                const pointWithTime = points.find(p => p.time !== null);
                if (pointWithTime) {
                    startTime = pointWithTime.time;
                }
            } else {
                throw new Error('No trackpoints found in GPX file');
            }
            
            // Calculate distance and basic elevation
            for (let i = 1; i < points.length; i++) {
                const prev = points[i - 1];
                const curr = points[i];
                
                // Distance calculation using Haversine formula
                totalDistance += this.calculateDistance(prev.lat, prev.lon, curr.lat, curr.lon);
                
                // Basic elevation gain (if available)
                if (prev.ele !== null && curr.ele !== null && curr.ele > prev.ele) {
                    totalElevationGain += curr.ele - prev.ele;
                }
                
                // Time tracking
                if (curr.time) {
                    if (!minTime) minTime = curr.time;
                    maxTime = curr.time;
                }
            }
            
            const duration = minTime && maxTime ? (maxTime - minTime) / (1000 * 60) : null; // minutes
            const averageSpeed = duration ? (totalDistance / (duration / 60)) : null; // km/h
            
            return {
                points,
                distance: parseFloat(totalDistance.toFixed(2)),
                elevationGain: parseFloat(totalElevationGain.toFixed(1)),
                duration: duration ? parseFloat(duration.toFixed(1)) : null,
                averageSpeed: averageSpeed ? parseFloat(averageSpeed.toFixed(1)) : null,
                hasElevation: points.some(p => p.ele !== null),
                startLocation,
                startTime
            };
            
        } catch (error) {
            throw new Error(`Failed to parse GPX file: ${error.message}`);
        }
    }

    /**
     * Enhance elevation data using GPXZ API
     */
    async enhanceElevationData(gpxData) {
        if (!this.config.gpxzApiKey) {
            console.warn('⚠️  No GPXZ API key provided, using original elevation data');
            return gpxData;
        }

        try {
            console.log('🔍 Enhancing elevation data with GPXZ...');
            
            // Prepare points for elevation enhancement
            const pointsToEnhance = gpxData.points.slice(0, 1000); // Limit to avoid API limits
            const enhancedPoints = [];
            
            // Process points in batches to respect API limits
            const batchSize = 10; // Conservative batch size
            
            for (let i = 0; i < pointsToEnhance.length; i += batchSize) {
                const batch = pointsToEnhance.slice(i, i + batchSize);
                
                console.log(`Processing elevation batch ${Math.floor(i/batchSize) + 1}/${Math.ceil(pointsToEnhance.length/batchSize)}`);
                
                const batchPromises = batch.map(async (point) => {
                    try {
                        const response = await axios.get(this.config.gpxzApiUrl, {
                            params: {
                                lat: point.lat,
                                lon: point.lon
                            },
                            headers: {
                                'x-api-key': this.config.gpxzApiKey
                            },
                            timeout: 10000
                        });
                        
                        return {
                            ...point,
                            ele: response.data.elevation || point.ele
                        };
                        
                    } catch (error) {
                        console.warn(`⚠️  Failed to get elevation for point ${point.lat}, ${point.lon}:`, error.message);
                        return point; // Return original point if enhancement fails
                    }
                });
                
                const batchResults = await Promise.all(batchPromises);
                enhancedPoints.push(...batchResults);
                
                // Add delay between batches to respect rate limits
                if (i + batchSize < pointsToEnhance.length) {
                    await new Promise(resolve => setTimeout(resolve, 100));
                }
            }
            
            // Add any remaining points that weren't processed
            if (gpxData.points.length > pointsToEnhance.length) {
                enhancedPoints.push(...gpxData.points.slice(pointsToEnhance.length));
            }
            
            // Recalculate elevation gain with enhanced data
            let enhancedElevationGain = 0;
            for (let i = 1; i < enhancedPoints.length; i++) {
                const prev = enhancedPoints[i - 1];
                const curr = enhancedPoints[i];
                
                if (prev.ele !== null && curr.ele !== null && curr.ele > prev.ele) {
                    enhancedElevationGain += curr.ele - prev.ele;
                }
            }
            
            console.log(`✅ Enhanced ${enhancedPoints.length} points with GPXZ elevation data`);
            
            return {
                ...gpxData,
                points: enhancedPoints,
                elevationGain: parseFloat(enhancedElevationGain.toFixed(1)),
                hasElevation: true,
                elevationEnhanced: true
            };
            
        } catch (error) {
            console.warn('⚠️  Failed to enhance elevation data:', error.message);
            return { ...gpxData, elevationEnhanced: false };
        }
    }

    /**
     * Get weather data from API for specific date
     */
    async getWeatherData(lat, lon, rideDate = null) {
        if (!this.config.weatherApiKey) {
            console.warn('⚠️  No weather API key provided, using default conditions');
            return {
                windSpeed: 0,
                windDirection: 0,
                humidity: 50,
                temperature: 20,
                source: 'default',
                date: rideDate ? rideDate.toDateString() : 'current'
            };
        }

        try {
            let response;
            let weatherData;
            
            // Check if we need historical data (ride date is more than 5 days ago)
            const now = new Date();
            const fiveDaysAgo = new Date(now.getTime() - (5 * 24 * 60 * 60 * 1000));
            
            if (rideDate && rideDate < fiveDaysAgo) {
                // Use historical weather API (OpenWeatherMap One Call API 3.0)
                console.log('🕒 Fetching historical weather data...');
                
                const timestamp = Math.floor(rideDate.getTime() / 1000);
                
                response = await axios.get(this.config.weatherHistoricalApiUrl, {
                    params: {
                        lat,
                        lon,
                        dt: timestamp,
                        appid: this.config.weatherApiKey,
                        units: 'metric'
                    },
                    timeout: 10000
                });
                
                const historicalData = response.data.data[0];
                
                weatherData = {
                    windSpeed: historicalData.wind_speed || 0,
                    windDirection: historicalData.wind_deg || 0,
                    humidity: historicalData.humidity || 50,
                    temperature: historicalData.temp || 20,
                    pressure: historicalData.pressure || 1013,
                    source: 'historical',
                    date: rideDate.toDateString()
                };
                
            } else {
                // Use current weather API for recent dates or when no date is available
                console.log('🌐 Fetching current/recent weather data...');
                
                response = await axios.get(this.config.weatherApiUrl, {
                    params: {
                        lat,
                        lon,
                        appid: this.config.weatherApiKey,
                        units: 'metric'
                    },
                    timeout: 10000
                });
                
                const currentData = response.data;
                
                weatherData = {
                    windSpeed: currentData.wind?.speed || 0,
                    windDirection: currentData.wind?.deg || 0,
                    humidity: currentData.main?.humidity || 50,
                    temperature: currentData.main?.temp || 20,
                    pressure: currentData.main?.pressure || 1013,
                    source: 'current',
                    date: rideDate ? rideDate.toDateString() : 'current'
                };
            }
            
            return weatherData;
            
        } catch (error) {
            console.warn('⚠️  Failed to get weather data:', error.message);
            
            // If historical API fails, try current weather as fallback
            if (rideDate && error.response?.status === 401) {
                console.warn('⚠️  Historical weather requires paid API plan, using current weather as fallback');
                try {
                    const response = await axios.get(this.config.weatherApiUrl, {
                        params: {
                            lat,
                            lon,
                            appid: this.config.weatherApiKey,
                            units: 'metric'
                        },
                        timeout: 10000
                    });
                    
                    const data = response.data;
                    return {
                        windSpeed: data.wind?.speed || 0,
                        windDirection: data.wind?.deg || 0,
                        humidity: data.main?.humidity || 50,
                        temperature: data.main?.temp || 20,
                        pressure: data.main?.pressure || 1013,
                        source: 'current_fallback',
                        date: 'current (historical unavailable)'
                    };
                } catch (fallbackError) {
                    // Fall through to default values
                }
            }
            
            return {
                windSpeed: 0,
                windDirection: 0,
                humidity: 50,
                temperature: 20,
                source: 'fallback',
                date: rideDate ? rideDate.toDateString() : 'default'
            };
        }
    }

    /**
     * Calculate detailed calorie burn with all factors
     */
    calculateDetailedCalories(params) {
        const {
            weight,
            distance,
            duration,
            elevationGain,
            averageSpeed,
            weather
        } = params;

        // Base metabolic equivalent (MET) values for cycling
        const getBaseMET = (speed) => {
            if (speed < 16) return 4.0;      // Light effort
            if (speed < 19) return 6.8;      // Moderate effort
            if (speed < 22) return 8.5;      // Vigorous effort
            if (speed < 25) return 10.0;     // Very vigorous
            return 12.0;                     // Racing
        };

        const baseMET = getBaseMET(averageSpeed);
        
        // Base calories (without adjustments)
        const baseCalories = baseMET * weight * (duration / 60);
        
        // Elevation adjustment
        // Additional calories for elevation gain (approximately 10 calories per kg per 100m)
        const elevationCalories = (elevationGain / 100) * weight * 10;
        
        // Wind resistance adjustment
        const windFactor = this.calculateWindResistance(averageSpeed, weather.windSpeed, weather.windDirection);
        const windAdjustment = baseCalories * windFactor;
        
        // Temperature and humidity adjustments
        const tempFactor = this.calculateTemperatureFactor(weather.temperature);
        const humidityFactor = this.calculateHumidityFactor(weather.humidity);
        const environmentalAdjustment = baseCalories * (tempFactor + humidityFactor - 2);
        
        const totalCalories = baseCalories + elevationCalories + windAdjustment + environmentalAdjustment;
        
        return {
            totalCalories: Math.round(totalCalories),
            baseCalories: Math.round(baseCalories),
            elevationCalories: Math.round(elevationCalories),
            windAdjustment: Math.round(windAdjustment),
            environmentalAdjustment: Math.round(environmentalAdjustment),
            baseMET,
            caloriesPerKm: Math.round(totalCalories / distance),
            caloriesPerHour: Math.round(totalCalories / (duration / 60))
        };
    }

    /**
     * Calculate wind resistance factor
     */
    calculateWindResistance(speed, windSpeed, windDirection) {
        // Simplified wind resistance calculation
        // Assumes rider direction is 0 degrees for simplicity
        const headwindComponent = windSpeed * Math.cos((windDirection * Math.PI) / 180);
        const effectiveWindSpeed = headwindComponent;
        
        // Wind resistance increases exponentially with effective speed
        const totalSpeed = speed + effectiveWindSpeed;
        const speedFactor = Math.pow(totalSpeed / speed, 2.5) - 1;
        
        return Math.max(-0.3, Math.min(0.5, speedFactor)); // Cap between -30% and +50%
    }

    /**
     * Calculate temperature adjustment factor
     */
    calculateTemperatureFactor(temperature) {
        // Optimal temperature range is 15-25°C
        if (temperature >= 15 && temperature <= 25) return 1.0;
        if (temperature < 15) return 1.0 + (15 - temperature) * 0.02; // Cold increases calories
        return 1.0 + (temperature - 25) * 0.015; // Heat increases calories
    }

    /**
     * Calculate humidity adjustment factor
     */
    calculateHumidityFactor(humidity) {
        // Higher humidity increases energy expenditure
        return 1.0 + (humidity - 50) * 0.002;
    }

    /**
     * Calculate distance between two GPS coordinates (Haversine formula)
     */
    calculateDistance(lat1, lon1, lat2, lon2) {
        const R = 6371; // Earth's radius in kilometers
        const dLat = (lat2 - lat1) * Math.PI / 180;
        const dLon = (lon2 - lon1) * Math.PI / 180;
        const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
                Math.sin(dLon/2) * Math.sin(dLon/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c;
    }

    /**
     * Get detailed breakdown of calorie calculation
     */
    getCalorieBreakdown(calorieData) {
        const breakdown = [
            {
                factor: 'Base Activity',
                calories: calorieData.baseCalories,
                percentage: Math.round((calorieData.baseCalories / calorieData.totalCalories) * 100),
                description: `MET ${calorieData.baseMET} cycling activity`
            },
            {
                factor: 'Elevation Gain',
                calories: calorieData.elevationCalories,
                percentage: Math.round((calorieData.elevationCalories / calorieData.totalCalories) * 100),
                description: 'Additional energy for climbing'
            },
            {
                factor: 'Wind Resistance',
                calories: calorieData.windAdjustment,
                percentage: Math.round((calorieData.windAdjustment / calorieData.totalCalories) * 100),
                description: 'Wind conditions impact'
            },
            {
                factor: 'Environmental',
                calories: calorieData.environmentalAdjustment,
                percentage: Math.round((calorieData.environmentalAdjustment / calorieData.totalCalories) * 100),
                description: 'Temperature and humidity effects'
            }
        ];
        
        return breakdown.filter(item => Math.abs(item.calories) > 1);
    }
}

// CLI interface
async function main() {
    const args = process.argv.slice(2);
    
    if (args.length < 2) {
        console.log(`
🚴 Elevation-Adjusted Cycling Calorie Calculator

Usage: node index.js <weight_kg> <gpx_file_path>

Example: node index.js 70 ./ride.gpx

The calculator will automatically extract coordinates from the first trackpoint
in the GPX file for weather data lookup.

Environment Variables:
- GPXZ_API_KEY: Your GPXZ.io API key for elevation enhancement
- WEATHER_API_KEY: Your OpenWeatherMap API key for weather data

Get your free GPXZ API key at: https://gpxz.io
Get your free weather API key at: https://openweathermap.org/api
        `);
        process.exit(1);
    }

    const [weight, gpxFilePath] = args;
    
    const calculator = new CyclingCalorieCalculator();
    
    try {
        const result = await calculator.calculateCalorieBurn({
            weight: parseFloat(weight),
            gpxFilePath
        });
        
        console.log('\n🎯 CALORIE BURN RESULTS');
        console.log('========================');
        console.log(`Total Calories: ${result.summary.totalCalories} kcal`);
        console.log(`Distance: ${result.gpxData.distance} km`);
        console.log(`Duration: ${result.gpxData.duration} minutes`);
        console.log(`Elevation Gain: ${result.gpxData.elevationGain} m`);
        console.log(`Average Speed: ${result.gpxData.averageSpeed} km/h`);
        console.log(`Calories per km: ${result.summary.caloriesPerKm} kcal/km`);
        console.log(`Calories per hour: ${result.summary.caloriesPerHour} kcal/h`);
        
        console.log('\n📍 LOCATION & TIME');
        console.log('===================');
        console.log(`Start coordinates: ${result.location.lat.toFixed(6)}, ${result.location.lon.toFixed(6)}`);
        if (result.gpxData.startTime) {
            console.log(`Ride date: ${result.gpxData.startTime.toDateString()}`);
            console.log(`Ride time: ${result.gpxData.startTime.toLocaleTimeString()}`);
        } else {
            console.log('Ride date: No timestamp data in GPX file');
        }
        
        console.log('\n📊 BREAKDOWN');
        console.log('=============');
        result.breakdown.forEach(item => {
            console.log(`${item.factor}: ${item.calories} kcal (${item.percentage}%)`);
            console.log(`  ${item.description}`);
        });
        
        console.log('\n🌤️ WEATHER CONDITIONS');
        console.log('====================');
        console.log(`Date: ${result.weatherData.date}`);
        console.log(`Wind: ${result.weatherData.windSpeed} m/s`);
        console.log(`Humidity: ${result.weatherData.humidity}%`);
        console.log(`Temperature: ${result.weatherData.temperature}°C`);
        console.log(`Data source: ${result.weatherData.source}`);
        
        if (result.gpxData.elevationEnhanced) {
            console.log('\n✅ Elevation data enhanced with GPXZ');
        } else {
            console.log('\n⚠️  Using original GPX elevation data');
        }
        
    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
}

// Export for use as module
module.exports = CyclingCalorieCalculator;

// Run CLI if called directly
if (require.main === module) {
    main();
}