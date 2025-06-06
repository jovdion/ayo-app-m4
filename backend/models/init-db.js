const fs = require('fs');
const path = require('path');
const db = require('../config/database');

async function waitForDatabase(maxRetries = 5, delay = 5000) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      console.log(`Attempt ${i + 1}/${maxRetries}: Checking database connection...`);
      await db.execute('SELECT 1');
      console.log('Database connection successful!');
      return true;
    } catch (error) {
      console.error(`Attempt ${i + 1}/${maxRetries} failed:`, error.message);
      if (i < maxRetries - 1) {
        console.log(`Waiting ${delay/1000} seconds before next attempt...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }
  return false;
}

async function initializeDatabase() {
  try {
    console.log('Starting database initialization...');
    
    // Wait for database to be ready
    const isDatabaseReady = await waitForDatabase();
    if (!isDatabaseReady) {
      throw new Error('Could not establish database connection after multiple retries');
    }
    
    // Read schema file
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    
    // Split schema into individual statements
    const statements = schema
      .split(';')
      .filter(statement => statement.trim())
      .map(statement => statement.trim() + ';');
    
    // Execute each statement
    for (const statement of statements) {
      try {
        console.log('Executing:', statement);
        await db.execute(statement);
        console.log('Statement executed successfully');
      } catch (error) {
        // If table already exists, continue with next statement
        if (error.code === 'ER_TABLE_EXISTS_ERROR') {
          console.log('Table already exists, continuing...');
          continue;
        }
        throw error;
      }
    }
    
    console.log('Database initialization completed successfully');
    
    // Verify tables exist
    const [tables] = await db.execute('SHOW TABLES');
    console.log('Created tables:', tables.map(t => Object.values(t)[0]).join(', '));
    
    process.exit(0);
  } catch (error) {
    console.error('Error initializing database:', error);
    process.exit(1);
  }
}

// Run initialization
initializeDatabase(); 