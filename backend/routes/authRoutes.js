const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');

// Register
router.post('/register', async (req, res) => {
  console.log('\n=== REGISTRATION REQUEST ===');
  console.log('Headers:', req.headers);
  console.log('Body:', req.body);
  
  try {
    const { username, email, password } = req.body;

    // Validate input
    console.log('Validating input fields...');
    if (!username || !email || !password) {
      console.log('Validation failed - Missing fields:', {
        hasUsername: !!username,
        hasEmail: !!email,
        hasPassword: !!password
      });
      return res.status(400).json({ 
        message: 'All fields are required',
        missingFields: {
          username: !username,
          email: !email,
          password: !password
        }
      });
    }
    console.log('Input validation successful');

    // Test database connection
    try {
      console.log('Testing database connection...');
      await db.execute('SELECT 1');
      console.log('Database connection successful');
    } catch (dbError) {
      console.error('Database connection error:', dbError);
      return res.status(500).json({ 
        message: 'Database connection error',
        error: dbError.message
      });
    }

    // Check if user exists
    console.log('Checking for existing user with email:', email);
    try {
      const [existingUsers] = await db.execute(
        'SELECT id FROM users WHERE email = ?',
        [email]
      );
      console.log('Existing users found:', existingUsers.length);

      if (existingUsers.length > 0) {
        console.log('User already exists with email:', email);
        return res.status(400).json({ message: 'User already exists' });
      }
    } catch (dbError) {
      console.error('Error checking existing user:', dbError);
      return res.status(500).json({ 
        message: 'Error checking existing user',
        error: dbError.message
      });
    }

    // Hash password
    console.log('Hashing password...');
    const hashedPassword = await bcrypt.hash(password, 10);
    console.log('Password hashed successfully');

    // Create user
    console.log('Creating new user with username:', username);
    try {
      const [result] = await db.execute(
        'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
        [username, email, hashedPassword]
      );
      console.log('User created successfully with ID:', result.insertId);

      // Generate token
      console.log('Generating JWT token...');
      const token = jwt.sign(
        { id: result.insertId },
        process.env.JWT_SECRET || 'ayo_app_secret_key_2024',
        { expiresIn: '24h' }
      );
      console.log('JWT token generated successfully');

      const response = {
        token,
        user: {
          id: result.insertId,
          username,
          email
        }
      };
      console.log('Sending response:', response);
      res.status(201).json(response);
      console.log('=== REGISTRATION COMPLETE ===\n');
    } catch (dbError) {
      console.error('Error creating user:', dbError);
      return res.status(500).json({ 
        message: 'Error creating user',
        error: dbError.message
      });
    }
  } catch (error) {
    console.error('=== REGISTRATION ERROR ===');
    console.error('Error details:', error);
    console.error('Stack trace:', error.stack);
    res.status(500).json({ 
      message: 'Error in registration',
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
    console.log('=== REGISTRATION ERROR COMPLETE ===\n');
  }
});

// Login
router.post('/login', async (req, res) => {
  console.log('\n=== LOGIN REQUEST ===');
  console.log('Headers:', req.headers);
  console.log('Body:', req.body);

  try {
    const { email, password } = req.body;

    // Validate input
    console.log('Validating input fields...');
    if (!email || !password) {
      console.log('Validation failed - Missing fields:', {
        hasEmail: !!email,
        hasPassword: !!password
      });
      return res.status(400).json({ 
        message: 'Email and password are required',
        missingFields: {
          email: !email,
          password: !password
        }
      });
    }
    console.log('Input validation successful');

    // Get user
    console.log('Searching for user with email:', email);
    const [users] = await db.execute(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );
    console.log('Users found:', users.length);

    if (users.length === 0) {
      console.log('No user found with email:', email);
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = users[0];
    console.log('User found:', { id: user.id, email: user.email });

    // Check password
    console.log('Verifying password...');
    const isValidPassword = await bcrypt.compare(password, user.password);
    console.log('Password verification result:', isValidPassword);

    if (!isValidPassword) {
      console.log('Invalid password for user:', email);
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Generate token
    console.log('Generating JWT token...');
    const token = jwt.sign(
      { id: user.id },
      process.env.JWT_SECRET || 'your-default-secret',
      { expiresIn: '24h' }
    );
    console.log('JWT token generated successfully');

    const response = {
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email
      }
    };
    console.log('Sending response:', response);
    res.json(response);
    console.log('=== LOGIN COMPLETE ===\n');
  } catch (error) {
    console.error('=== LOGIN ERROR ===');
    console.error('Error details:', error);
    console.error('Stack trace:', error.stack);
    res.status(500).json({ 
      message: 'Error in login',
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
    console.log('=== LOGIN ERROR COMPLETE ===\n');
  }
});

module.exports = router; 