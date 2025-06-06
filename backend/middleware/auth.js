const jwt = require('jsonwebtoken');

const auth = (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ message: 'Authentication required' });
    }

    // Use a strong JWT secret from environment variable
    const secret = process.env.JWT_SECRET;
    if (!secret) {
      console.error('JWT_SECRET not set in environment variables');
      return res.status(500).json({ message: 'Internal server error' });
    }

    const decoded = jwt.verify(token, secret);
    req.user = decoded;
    next();
  } catch (error) {
    // Don't expose error details to client
    res.status(401).json({ message: 'Invalid token' });
  }
};

module.exports = auth; 