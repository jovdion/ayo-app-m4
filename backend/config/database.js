const mysql = require('mysql2');
const dotenv = require('dotenv');

dotenv.config();

// Normalize database configuration
const dbConfig = {
  host: (process.env.DB_HOST || '104.198.194.69').toLowerCase(),
  user: (process.env.DB_USER || 'root').toLowerCase(),
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'ayo-chat-db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  ssl: {
    rejectUnauthorized: false
  }
};

console.log('Initializing database connection with config:', {
  ...dbConfig,
  password: '********' // Hide password in logs
});

const pool = mysql.createPool(dbConfig);

// Convert pool to use promises
const promisePool = pool.promise();

// Test connection
pool.getConnection((err, connection) => {
  if (err) {
    console.error('Error connecting to database:', err);
    if (err.code === 'ER_ACCESS_DENIED_ERROR') {
      console.error('Please check your database credentials');
    }
  } else {
    console.log('Database connection successful');
    connection.release();
  }
});

module.exports = promisePool; 