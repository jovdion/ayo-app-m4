const mysql = require('mysql2/promise');
const fs = require('fs').promises;
const path = require('path');
require('dotenv').config();

async function setupDatabase() {
  try {
    // 1. Koneksi tanpa database
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || '104.198.194.69',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
    });

    console.log('Connected to MySQL server');

    // 2. Buat database jika belum ada
    const dbName = process.env.DB_NAME || 'ayo-chat-db';
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\`;`);
    console.log(`Database ${dbName} created or already exists`);
    await connection.end();

    // 3. Koneksi ulang dengan database
    const db = await mysql.createConnection({
      host: process.env.DB_HOST || '104.198.194.69',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'ayo-chat-db',
      multipleStatements: true,
    });

    console.log(`Connected to database ${dbName}`);

    // 4. Baca dan jalankan file database.sql
    const sqlPath = path.join(__dirname, 'database.sql');
    const sql = await fs.readFile(sqlPath, 'utf8');
    
    console.log('Executing database.sql...');
    await db.query(sql);
    console.log('Database tables created successfully');

    await db.end();
    console.log('Database setup completed successfully');
    
  } catch (error) {
    console.error('Error setting up database:', error);
    process.exit(1);
  }
}

setupDatabase().catch(console.error);