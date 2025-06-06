const express = require('express');
const router = express.Router();
const db = require('../config/database');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

// Middleware to verify JWT token
const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ message: 'No token provided' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'ayo_app_secret_key_2024');
    req.userId = decoded.id;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid token' });
  }
};

// Get all users except the current user
router.get('/', verifyToken, async (req, res) => {
  try {
    console.log('Getting users list for user ID:', req.userId);
    
    const [users] = await db.execute(
      'SELECT id, username, email FROM users WHERE id != ?',
      [req.userId]
    );
    
    console.log('Found users:', users.length);
    res.json(users);
  } catch (error) {
    console.error('Error getting users:', error);
    res.status(500).json({ 
      message: 'Error getting users',
      error: error.message 
    });
  }
});

// Get user profile
router.get('/profile/:userId', verifyToken, async (req, res) => {
  try {
    console.log('Getting profile for user ID:', req.params.userId);
    
    const [users] = await db.execute(
      'SELECT id, username, email FROM users WHERE id = ?',
      [req.params.userId]
    );
    
    if (users.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json(users[0]);
  } catch (error) {
    console.error('Error getting user profile:', error);
    res.status(500).json({ 
      message: 'Error getting user profile',
      error: error.message 
    });
  }
});

// Update user profile
router.put('/profile', verifyToken, async (req, res) => {
  try {
    console.log('Updating profile for user ID:', req.userId);
    const { username, email, password } = req.body;

    // Check if email is already taken by another user
    const [existingUsers] = await db.execute(
      'SELECT id FROM users WHERE email = ? AND id != ?',
      [email, req.userId]
    );

    if (existingUsers.length > 0) {
      return res.status(400).json({ message: 'Email already in use' });
    }

    // Check if username is already taken by another user
    const [existingUsernames] = await db.execute(
      'SELECT id FROM users WHERE username = ? AND id != ?',
      [username, req.userId]
    );

    if (existingUsernames.length > 0) {
      return res.status(400).json({ message: 'Username already in use' });
    }

    let query = 'UPDATE users SET username = ?, email = ?';
    let params = [username, email];

    // If password is provided, hash it and include in update
    if (password) {
      const hashedPassword = await bcrypt.hash(password, 10);
      query += ', password = ?';
      params.push(hashedPassword);
    }

    query += ' WHERE id = ?';
    params.push(req.userId);

    await db.execute(query, params);

    // Get updated user data
    const [users] = await db.execute(
      'SELECT id, username, email FROM users WHERE id = ?',
      [req.userId]
    );

    res.json(users[0]);
  } catch (error) {
    console.error('Error updating user profile:', error);
    res.status(500).json({ 
      message: 'Error updating user profile',
      error: error.message 
    });
  }
});

module.exports = router; 