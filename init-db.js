#!/usr/bin/env node

const CyclingDatabase = require('./database.js');
const fs = require('fs');
const path = require('path');

/**
 * Command line utility to initialize an empty cycling database
 */
class DatabaseInitializer {
    constructor() {
        this.args = process.argv.slice(2);
        this.options = this.parseArguments();
    }

    parseArguments() {
        const options = {
            dbPath: './cycling_data.db',
            force: false,
            withDefaults: true,
            help: false,
            verbose: false
        };

        for (let i = 0; i < this.args.length; i++) {
            const arg = this.args[i];
            
            switch (arg) {
                case '--help':
                case '-h':
                    options.help = true;
                    break;
                case '--force':
                case '-f':
                    options.force = true;
                    break;
                case '--no-defaults':
                    options.withDefaults = false;
                    break;
                case '--verbose':
                case '-v':
                    options.verbose = true;
                    break;
                case '--path':
                case '-p':
                    if (i + 1 < this.args.length) {
                        options.dbPath = this.args[i + 1];
                        i++; // Skip next argument
                    } else {
                        console.error('❌ Error: --path requires a database file path');
                        process.exit(1);
                    }
                    break;
                default:
                    if (!arg.startsWith('-')) {
                        // Treat as database path if no extension specified, add .db
                        options.dbPath = arg.endsWith('.db') ? arg : `${arg}.db`;
                    } else {
                        console.error(`❌ Unknown option: ${arg}`);
                        console.error('Use --help to see available options');
                        process.exit(1);
                    }
                    break;
            }
        }

        return options;
    }

    showHelp() {
        console.log(`
🚴 Cycling Calorie Calculator - Database Initializer

USAGE:
    node init-db.js [options] [database_path]

OPTIONS:
    -h, --help          Show this help message
    -p, --path <path>   Specify database file path (default: ./cycling_data.db)
    -f, --force         Overwrite existing database file
    -v, --verbose       Enable verbose output
    --no-defaults       Skip creating default configuration values

EXAMPLES:
    node init-db.js                           # Create default database
    node init-db.js my_cycling_data.db        # Create database with custom name
    node init-db.js --path ./data/rides.db    # Create database in specific path
    node init-db.js --force --verbose         # Force overwrite with verbose output
    node init-db.js --no-defaults             # Create database without default config

DESCRIPTION:
    This utility creates and initializes an empty cycling database with all
    required tables and indexes. If the database already exists, it will not
    be modified unless --force is specified.

TABLES CREATED:
    • rides              - Store cycling ride data and calculations
    • calorie_breakdown   - Store detailed calorie breakdown per ride
    • configuration       - Store application configuration settings
`);
    }

    async checkDatabaseExists() {
        const absolutePath = path.resolve(this.options.dbPath);
        
        try {
            await fs.promises.access(absolutePath);
            return true;
        } catch {
            return false;
        }
    }

    async createDatabase() {
        const absolutePath = path.resolve(this.options.dbPath);
        const exists = await this.checkDatabaseExists();

        // Check if database exists and handle accordingly
        if (exists && !this.options.force) {
            console.log(`⚠️  Database already exists: ${absolutePath}`);
            console.log('Use --force to overwrite or specify a different path');
            return false;
        }

        if (exists && this.options.force) {
            if (this.options.verbose) {
                console.log(`🗑️  Removing existing database: ${absolutePath}`);
            }
            try {
                await fs.promises.unlink(absolutePath);
            } catch (error) {
                console.error(`❌ Error removing existing database: ${error.message}`);
                return false;
            }
        }

        // Ensure directory exists
        const dbDir = path.dirname(absolutePath);
        try {
            await fs.promises.mkdir(dbDir, { recursive: true });
            if (this.options.verbose) {
                console.log(`📁 Created directory: ${dbDir}`);
            }
        } catch (error) {
            if (error.code !== 'EEXIST') {
                console.error(`❌ Error creating directory: ${error.message}`);
                return false;
            }
        }

        console.log(`🚀 Creating new database: ${absolutePath}`);

        try {
            const db = new CyclingDatabase(this.options.dbPath);
            
            if (this.options.verbose) {
                console.log('📋 Initializing database connection...');
            }
            
            await db.initialize();

            if (this.options.withDefaults) {
                if (this.options.verbose) {
                    console.log('⚙️  Setting up default configuration...');
                }
                await db.initializeDefaultConfig();
            }

            if (this.options.verbose) {
                console.log('🔐 Closing database connection...');
            }
            
            await db.close();

            console.log('✅ Database created successfully!');
            console.log(`📊 Database location: ${absolutePath}`);
            
            if (this.options.withDefaults) {
                console.log('⚙️  Default configuration values initialized');
            }

            // Show database info
            await this.showDatabaseInfo();

            return true;

        } catch (error) {
            console.error(`❌ Error creating database: ${error.message}`);
            if (this.options.verbose) {
                console.error(error.stack);
            }
            return false;
        }
    }

    async showDatabaseInfo() {
        console.log(`
📈 DATABASE SUMMARY:
   Path: ${path.resolve(this.options.dbPath)}
   Tables: rides, calorie_breakdown, configuration
   Indexes: Optimized for queries on date, distance, calories
   
🚴 READY TO USE:
   Your cycling database is ready! You can now:
   • Import GPX files and calculate calories
   • Store ride data and history
   • Manage application configuration
   • Export data for analysis
`);
    }

    async run() {
        if (this.options.help) {
            this.showHelp();
            return;
        }

        console.log('🚴 Cycling Calorie Calculator - Database Initializer\n');

        const success = await this.createDatabase();
        process.exit(success ? 0 : 1);
    }
}

// Run the initializer if called directly
if (require.main === module) {
    const initializer = new DatabaseInitializer();
    initializer.run().catch(error => {
        console.error('❌ Fatal error:', error.message);
        process.exit(1);
    });
}

module.exports = DatabaseInitializer;