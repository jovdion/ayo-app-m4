const mysql = require('mysql2/promise');
require('dotenv').config();

const dbConfig = {
  host: process.env.DB_HOST || '34.72.200.235',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'ayo-chat-db',
};

async function cleanDatabase() {
  try {
    const connection = await mysql.createConnection(dbConfig);
    console.log('Connected to database');

    // Reset location data
    await connection.execute(`
      UPDATE users 
      SET latitude = NULL, 
          longitude = NULL, 
          last_location_update = NULL
    `);
    console.log('Reset all user locations');

    // Delete all messages
    await connection.execute('DELETE FROM chats');
    console.log('Deleted all messages');

    // Reset auto increment
    await connection.execute('ALTER TABLE chats AUTO_INCREMENT = 1');
    console.log('Reset messages auto increment');

    await connection.end();
    console.log('Database cleaning completed');
  } catch (error) {
    console.error('Error cleaning database:', error);
    process.exit(1);
  }
}

cleanDatabase(); 