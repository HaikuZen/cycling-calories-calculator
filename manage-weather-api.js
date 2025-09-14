#!/usr/bin/env node

const CyclingDatabase = require('./database.js');

/**
 * Command line utility to manage weather API key configuration
 */
class WeatherApiManager {
    constructor() {
        this.args = process.argv.slice(2);
        this.command = this.args[0];
        this.options = this.parseArguments();
    }

    parseArguments() {
        const options = {
            dbPath: './cycling_data.db',
            apiKey: null,
            baseUrl: null,
            timeout: null,
            show: false,
            help: false
        };

        for (let i = 1; i < this.args.length; i++) {
            const arg = this.args[i];
            
            switch (arg) {
                case '--help':
                case '-h':
                    options.help = true;
                    break;
                case '--db':
                case '-d':
                    if (i + 1 < this.args.length) {
                        options.dbPath = this.args[i + 1];
                        i++;
                    }
                    break;
                case '--key':
                case '-k':
                    if (i + 1 < this.args.length) {
                        options.apiKey = this.args[i + 1];
                        i++;
                    }
                    break;
                case '--url':
                case '-u':
                    if (i + 1 < this.args.length) {
                        options.baseUrl = this.args[i + 1];
                        i++;
                    }
                    break;
                case '--timeout':
                case '-t':
                    if (i + 1 < this.args.length) {
                        options.timeout = parseInt(this.args[i + 1]);
                        i++;
                    }
                    break;
                case '--show':
                case '-s':
                    options.show = true;
                    break;
                default:
                    // If no flag and it looks like an API key, use it as such
                    if (!arg.startsWith('-') && arg.length > 10) {
                        options.apiKey = arg;
                    }
                    break;
            }
        }

        return options;
    }

    showHelp() {
        console.log(`
🌤️  Weather API Key Manager

USAGE:
    node manage-weather-api.js <command> [options]

COMMANDS:
    set                Set weather API key and configuration
    get                Get current weather API configuration
    check              Check if API key is configured
    clear              Clear the weather API key

OPTIONS:
    -k, --key <key>    Weather API key
    -u, --url <url>    Weather API base URL
    -t, --timeout <ms> API timeout in milliseconds
    -d, --db <path>    Database file path (default: ./cycling_data.db)
    -s, --show         Show API key value (otherwise masked)
    -h, --help         Show this help message

EXAMPLES:
    # Set API key
    node manage-weather-api.js set --key "your-api-key-here"
    
    # Set API key with custom URL and timeout
    node manage-weather-api.js set -k "api-key" -u "https://api.weather.com" -t 10000
    
    # Get current configuration
    node manage-weather-api.js get
    
    # Show configuration with visible API key
    node manage-weather-api.js get --show
    
    # Check if API key is configured
    node manage-weather-api.js check
    
    # Clear API key
    node manage-weather-api.js clear
    
    # Use different database
    node manage-weather-api.js get --db ./production_data.db

WEATHER API PROVIDERS:
    • OpenWeatherMap: https://openweathermap.org/api
    • WeatherAPI: https://www.weatherapi.com/
    • AccuWeather: https://developer.accuweather.com/
    • Visual Crossing: https://www.visualcrossing.com/weather-api

NOTES:
    - API keys are stored securely in the database
    - Use environment variables for sensitive keys in production
    - Some commands may require the database to exist first
`);
    }

    maskApiKey(apiKey) {
        if (!apiKey || apiKey.length < 8) return apiKey;
        return apiKey.substring(0, 4) + '****' + apiKey.substring(apiKey.length - 4);
    }

    async executeCommand() {
        const db = new CyclingDatabase(this.options.dbPath);
        
        try {
            await db.initialize();

            switch (this.command) {
                case 'set':
                    await this.setApiKey(db);
                    break;
                case 'get':
                    await this.getApiKey(db);
                    break;
                case 'check':
                    await this.checkApiKey(db);
                    break;
                case 'clear':
                    await this.clearApiKey(db);
                    break;
                default:
                    console.error(`❌ Unknown command: ${this.command}`);
                    console.log('Use --help to see available commands');
                    return false;
            }

            return true;

        } catch (error) {
            console.error(`❌ Error: ${error.message}`);
            return false;
        } finally {
            await db.close();
        }
    }

    async setApiKey(db) {
        const { apiKey, baseUrl, timeout } = this.options;

        if (!apiKey) {
            console.error('❌ API key is required. Use --key or -k to specify it.');
            return;
        }

        console.log('🔑 Setting weather API configuration...');

        const config = {};
        if (apiKey) config.apiKey = apiKey;
        if (baseUrl) config.baseUrl = baseUrl;
        if (timeout) config.timeout = timeout;

        await db.setWeatherApiConfig(config);

        const updatedConfig = await db.getWeatherApiConfig();
        
        console.log('✅ Weather API configuration updated:');
        console.log(`   API Key: ${this.options.show ? updatedConfig.apiKey : this.maskApiKey(updatedConfig.apiKey)}`);
        console.log(`   Base URL: ${updatedConfig.baseUrl}`);
        console.log(`   Timeout: ${updatedConfig.timeout}ms`);
        console.log(`   Status: ${updatedConfig.hasKey ? '✅ Configured' : '❌ Not configured'}`);
    }

    async getApiKey(db) {
        console.log('📋 Current weather API configuration:');
        
        const config = await db.getWeatherApiConfig();
        
        console.log(`   API Key: ${config.apiKey ? (this.options.show ? config.apiKey : this.maskApiKey(config.apiKey)) : '❌ Not configured'}`);
        console.log(`   Base URL: ${config.baseUrl}`);
        console.log(`   Timeout: ${config.timeout}ms`);
        console.log(`   Status: ${config.hasKey ? '✅ Configured' : '❌ Not configured'}`);

        if (!config.hasKey) {
            console.log('\n💡 To set an API key, use:');
            console.log('   node manage-weather-api.js set --key "your-api-key-here"');
        }
    }

    async checkApiKey(db) {
        const hasKey = await db.hasWeatherApiKey();
        const config = await db.getWeatherApiConfig();
        
        if (hasKey) {
            console.log('✅ Weather API key is configured');
            console.log(`   Provider: ${config.baseUrl}`);
            console.log(`   Key length: ${config.apiKey.length} characters`);
        } else {
            console.log('❌ Weather API key is not configured');
            console.log('   Use "set" command to configure it');
        }

        return hasKey;
    }

    async clearApiKey(db) {
        console.log('🗑️  Clearing weather API key...');
        
        await db.setConfig('weather_api_key', '', 'string', 'Weather API key (OpenWeatherMap or similar)', 'api');
        
        console.log('✅ Weather API key cleared');
        
        const config = await db.getWeatherApiConfig();
        console.log(`   Status: ${config.hasKey ? '✅ Still configured' : '❌ Not configured'}`);
    }

    async run() {
        if (this.options.help || !this.command) {
            this.showHelp();
            return;
        }

        console.log('🌤️  Weather API Key Manager\n');

        const success = await this.executeCommand();
        process.exit(success ? 0 : 1);
    }
}

// Run the manager if called directly
if (require.main === module) {
    const manager = new WeatherApiManager();
    manager.run().catch(error => {
        console.error('❌ Fatal error:', error.message);
        process.exit(1);
    });
}

module.exports = WeatherApiManager;