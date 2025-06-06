const mysql = require('mysql2/promise');
const fs = require('fs').promises;
const path = require('path');

async function initializeDatabase() {
  try {
    // Create connection to MySQL server
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
    });

    console.log('Connected to MySQL server');

    // Create database if not exists
    await connection.query('CREATE DATABASE IF NOT EXISTS `ayo-chat-db`');
    console.log('Database created or already exists');

    // Use the database
    await connection.query('USE `ayo-chat-db`');
    console.log('Using ayo-chat-db');

    // Read and execute the SQL initialization file
    const sqlPath = path.join(__dirname, 'init.sql');
    const sqlContent = await fs.readFile(sqlPath, 'utf8');
    
    // Split SQL commands and execute them separately
    const sqlCommands = sqlContent.split(';').filter(cmd => cmd.trim());
    
    for (const command of sqlCommands) {
      if (command.trim()) {
        await connection.query(command);
        console.log('Executed SQL command:', command.trim().split('\n')[0]);
      }
    }

    console.log('Database initialization completed');
    await connection.end();
  } catch (error) {
    console.error('Error initializing database:', error);
    process.exit(1);
  }
}

initializeDatabase(); 