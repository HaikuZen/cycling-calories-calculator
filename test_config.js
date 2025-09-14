const CyclingDatabase = require('./database.js');

/**
 * Test script to demonstrate the configuration table functionality
 */
async function testConfiguration() {
    const db = new CyclingDatabase('./test_config.db');
    
    try {
        console.log('🚀 Initializing database...');
        await db.initialize();
        
        console.log('\n📋 Setting up default configuration...');
        await db.initializeDefaultConfig();
        
        console.log('\n⚙️ Setting custom configuration values...');
        await db.setConfig('app_name', 'Cycling Calorie Calculator', 'string', 'Application name', 'app');
        await db.setConfig('max_file_size', 50, 'number', 'Maximum file size in MB', 'limits');
        await db.setConfig('debug_mode', false, 'boolean', 'Enable debug logging', 'system');
        await db.setConfig('supported_formats', ['gpx', 'tcx', 'fit'], 'json', 'Supported file formats', 'formats');
        
        console.log('\n📖 Reading configuration values...');
        const appName = await db.getConfig('app_name');
        const maxFileSize = await db.getConfig('max_file_size');
        const debugMode = await db.getConfig('debug_mode');
        const formats = await db.getConfig('supported_formats');
        const defaultWeight = await db.getConfig('default_rider_weight');
        const nonExistent = await db.getConfig('non_existent_key', 'default_value');
        
        console.log(`App Name: ${appName} (${typeof appName})`);
        console.log(`Max File Size: ${maxFileSize} MB (${typeof maxFileSize})`);
        console.log(`Debug Mode: ${debugMode} (${typeof debugMode})`);
        console.log(`Supported Formats: ${JSON.stringify(formats)} (${typeof formats})`);
        console.log(`Default Weight: ${defaultWeight} kg (${typeof defaultWeight})`);
        console.log(`Non-existent key: ${nonExistent} (${typeof nonExistent})`);
        
        console.log('\n📚 Getting all configuration by category...');
        const systemConfig = await db.getAllConfig('system');
        console.log('System Configuration:', JSON.stringify(systemConfig, null, 2));
        
        console.log('\n📚 Getting all configuration...');
        const allConfig = await db.getAllConfig();
        console.log('All Configuration keys:', Object.keys(allConfig));
        
        console.log('\n🔄 Updating existing configuration...');
        await db.setConfig('debug_mode', true, 'boolean', 'Enable debug logging (updated)', 'system');
        const updatedDebugMode = await db.getConfig('debug_mode');
        console.log(`Updated Debug Mode: ${updatedDebugMode} (${typeof updatedDebugMode})`);
        
        console.log('\n🗑️ Deleting a configuration value...');
        const deleted = await db.deleteConfig('max_file_size');
        console.log(`Deletion successful: ${deleted}`);
        
        const deletedValue = await db.getConfig('max_file_size', 'NOT_FOUND');
        console.log(`Deleted value check: ${deletedValue}`);
        
        console.log('\n🌤️ Testing Weather API key functionality...');
        
        // Check if weather API key is configured
        const hasKey = await db.hasWeatherApiKey();
        console.log(`Has weather API key: ${hasKey}`);
        
        // Try to get weather API key (should be empty initially)
        const initialKey = await db.getWeatherApiKey();
        console.log(`Initial API key: ${initialKey || 'Not configured'}`);
        
        // Set a test weather API key
        await db.setWeatherApiKey('test_api_key_12345');
        
        // Get the weather API key
        const retrievedKey = await db.getWeatherApiKey();
        console.log(`Retrieved API key: ${retrievedKey}`);
        
        // Check if weather API key is now configured
        const hasKeyNow = await db.hasWeatherApiKey();
        console.log(`Has weather API key now: ${hasKeyNow}`);
        
        // Get full weather API configuration
        const weatherConfig = await db.getWeatherApiConfig();
        console.log('Weather API Configuration:', JSON.stringify(weatherConfig, null, 2));
        
        // Update weather API configuration
        await db.setWeatherApiConfig({
            apiKey: 'new_test_key_67890',
            baseUrl: 'https://api.custom-weather.com/v1',
            timeout: 10000
        });
        
        // Get updated weather API configuration
        const updatedWeatherConfig = await db.getWeatherApiConfig();
        console.log('Updated Weather API Configuration:', JSON.stringify(updatedWeatherConfig, null, 2));
        
        console.log('\n✅ Configuration test completed successfully!');
        
    } catch (error) {
        console.error('❌ Error during configuration test:', error.message);
    } finally {
        await db.close();
    }
}

// Run the test
if (require.main === module) {
    testConfiguration();
}

module.exports = testConfiguration;