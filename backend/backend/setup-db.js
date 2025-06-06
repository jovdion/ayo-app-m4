const mysql = require('mysql2/promise');
const fs = require('fs').promises;
const path = require('path');
require('dotenv').config();

async function setupDatabase() {
  let connection;
  try {
    console.log('Starting database setup...');

    // Create connection without database selection
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      multipleStatements: true
    });

    console.log('Connected to MySQL server');

    // Read and execute database.sql file
    const sqlPath = path.join(__dirname, 'database.sql');
    const sql = await fs.readFile(sqlPath, 'utf8');
    
    console.log('Executing database.sql...');
    await connection.query(sql);
    console.log('Database and tables created successfully');

  } catch (error) {
    console.error('Error setting up database:', error);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log('Database connection closed');
    }
  }
}

// Run setup if this file is executed directly
if (require.main === module) {
  setupDatabase()
    .then(() => {
      console.log('Database setup completed successfully');
      process.exit(0);
    })
    .catch(error => {
      console.error('Database setup failed:', error);
      process.exit(1);
    });
}

module.exports = setupDatabase;