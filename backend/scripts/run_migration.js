const mysql = require('mysql2/promise');
const fs = require('fs').promises;
const path = require('path');

async function runMigration() {
  const connection = await mysql.createConnection({
    host: '104.198.194.69',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || 'your_password',
    database: 'ayo-chat-db',
    multipleStatements: true
  });

  try {
    console.log('Running migration...');
    
    // Read and execute the migration file
    const migrationPath = path.join(__dirname, '../migrations/add_encrypted_location.sql');
    const migrationSQL = await fs.readFile(migrationPath, 'utf8');
    
    await connection.query(migrationSQL);
    console.log('Migration completed successfully');
  } catch (error) {
    console.error('Error running migration:', error);
    throw error;
  } finally {
    await connection.end();
  }
}

runMigration().catch(console.error); 