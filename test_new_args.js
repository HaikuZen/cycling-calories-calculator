#!/usr/bin/env node

const CyclingDatabase = require('./database.js');

/**
 * Test script to demonstrate new argument format and configuration loading
 */
async function testNewArguments() {
    console.log('🧪 Testing New Argument Format and Database Configuration Loading\n');
    
    const db = new CyclingDatabase('./test_new_args.db');
    
    try {
        console.log('1. Setting up test database...');
        await db.initialize();
        await db.initializeDefaultConfig();
        
        // Set some test configuration values
        await db.setWeatherApiKey('test_weather_key_12345');
        await db.setConfig('default_rider_weight', 75, 'number', 'Test rider weight', 'rider');
        
        console.log('✅ Test database created with configuration');
        
        console.log('\n2. Testing configuration loading...');
        const CyclingCalorieCalculator = require('./index.js');
        
        // Create calculator with database enabled
        const calculator = new CyclingCalorieCalculator({
            saveToDatabase: true,
            databasePath: './test_new_args.db'
        });
        
        // Test getting default rider weight
        const defaultWeight = await calculator.getDefaultRiderWeight();
        console.log(`📏 Default rider weight from database: ${defaultWeight}kg`);
        
        // Test loading database config
        console.log('\n3. Loading database configuration...');
        await calculator.loadDatabaseConfig();
        
        console.log(`🔑 Weather API key loaded: ${calculator.config.weatherApiKey ? 'Yes' : 'No'}`);
        console.log(`🌐 Weather API URL: ${calculator.config.weatherApiUrl}`);
        
        console.log('\n4. Testing argument parsing scenarios:');
        
        console.log('\nScenario 1: New format - GPX file only');
        console.log('Command: node index.js ./test_ride.gpx');
        console.log('Expected: Use default weight from database (75kg)');
        
        console.log('\nScenario 2: New format - GPX file with rider ID');
        console.log('Command: node index.js ./test_ride.gpx --rider-id john');
        console.log('Expected: Use default weight (75kg) with rider ID tracking');
        
        console.log('\nScenario 3: Legacy format - Weight and GPX file');
        console.log('Command: node index.js 80 ./test_ride.gpx');
        console.log('Expected: Use specified weight (80kg) with legacy warning');
        
        console.log('\n5. Database configuration summary:');
        const allConfig = await db.getAllConfig();
        
        console.log('Configuration in database:');
        Object.keys(allConfig).forEach(key => {
            const config = allConfig[key];
            if (key === 'weather_api_key') {
                // Mask the API key for security
                const maskedValue = config.value ? config.value.substring(0, 4) + '****' + config.value.substring(config.value.length - 4) : 'Not set';
                console.log(`  ${key}: ${maskedValue} (${config.type}) - ${config.description}`);
            } else {
                console.log(`  ${key}: ${config.value} (${config.type}) - ${config.description}`);
            }
        });
        
        console.log('\n✅ All tests completed successfully!');
        console.log('\n💡 Usage examples:');
        console.log('  node index.js ride.gpx                    # Uses database default weight');
        console.log('  node index.js ride.gpx --rider-id alice   # Uses database default weight with rider tracking');
        console.log('  node index.js 65 ride.gpx                # Legacy format, uses specified weight');
        console.log('  node manage-weather-api.js set -k "your-api-key"  # Set weather API key');
        console.log('  ./manage-config.sh set -k "default_rider_weight" -v 72 -t number  # Set default weight');
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
        if (process.env.DEBUG) {
            console.error(error.stack);
        }
    } finally {
        await db.close();
    }
}

// Helper function to simulate argument parsing
function simulateArgumentParsing(args) {
    console.log(`\n🔍 Parsing arguments: [${args.join(', ')}]`);
    
    let gpxFilePath;
    let riderId = null;
    let weight = null;
    
    // Check if --rider-id switch is used
    const riderIdIndex = args.indexOf('--rider-id');
    if (riderIdIndex !== -1 && riderIdIndex + 1 < args.length) {
        riderId = args[riderIdIndex + 1];
        // Remove --rider-id and its value from args for GPX file detection
        const filteredArgs = args.filter((arg, index) => 
            index !== riderIdIndex && index !== riderIdIndex + 1
        );
        gpxFilePath = filteredArgs[0];
    } else {
        // Legacy support: if two arguments and second is not a switch, treat as weight + gpx
        if (args.length >= 2 && !args[1].startsWith('--') && !isNaN(parseFloat(args[0]))) {
            console.log('⚠️  Legacy format detected');
            weight = parseFloat(args[0]);
            gpxFilePath = args[1];
        } else {
            gpxFilePath = args[0];
        }
    }
    
    console.log(`  GPX File: ${gpxFilePath}`);
    console.log(`  Rider ID: ${riderId || 'None'}`);
    console.log(`  Weight: ${weight !== null ? weight + 'kg' : 'From database'}`);
    
    return { gpxFilePath, riderId, weight };
}

// Test argument parsing with different scenarios
async function testArgumentParsing() {
    console.log('\n📝 Testing Argument Parsing Logic:');
    console.log('=====================================');
    
    const testCases = [
        ['ride.gpx'],
        ['ride.gpx', '--rider-id', 'alice'],
        ['70', 'ride.gpx'],
        ['--rider-id', 'bob', 'ride.gpx'],
        ['ride.gpx', '--rider-id', 'charlie']
    ];
    
    testCases.forEach((testCase, index) => {
        console.log(`\nTest Case ${index + 1}:`);
        simulateArgumentParsing(testCase);
    });
}

// Run tests if called directly
if (require.main === module) {
    testNewArguments()
        .then(() => testArgumentParsing())
        .catch(error => {
            console.error('❌ Fatal error:', error.message);
            process.exit(1);
        });
}

module.exports = { testNewArguments, testArgumentParsing };