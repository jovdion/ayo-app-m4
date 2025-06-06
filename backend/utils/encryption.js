const crypto = require('crypto');

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || 'ayo-chat-default-encryption-key-2024';
const ALGORITHM = 'aes-256-cbc';

function encrypt(text) {
  try {
    const iv = crypto.randomBytes(16);
    const key = crypto.scryptSync(ENCRYPTION_KEY, 'salt', 32);
    const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
    
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    return {
      encrypted,
      iv: iv.toString('hex')
    };
  } catch (error) {
    console.error('Encryption error:', error);
    throw new Error('Failed to encrypt data');
  }
}

function decrypt(encryptedText, ivHex) {
  try {
    const key = crypto.scryptSync(ENCRYPTION_KEY, 'salt', 32);
    const iv = Buffer.from(ivHex, 'hex');
    const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
    
    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  } catch (error) {
    console.error('Decryption error:', error);
    throw new Error('Failed to decrypt data');
  }
}

function encryptLocation(latitude, longitude) {
  try {
    console.log('Encrypting location:', { latitude, longitude });
    const locationData = JSON.stringify({ latitude, longitude });
    const result = encrypt(locationData);
    console.log('Location encrypted successfully');
    return result;
  } catch (error) {
    console.error('Location encryption error:', error);
    throw new Error('Failed to encrypt location data');
  }
}

function decryptLocation(encryptedData, iv) {
  if (!encryptedData || !iv) {
    console.log('No encrypted location data available');
    return null;
  }
  
  try {
    const decrypted = decrypt(encryptedData, iv);
    const location = JSON.parse(decrypted);
    console.log('Location decrypted successfully');
    return location;
  } catch (error) {
    console.error('Location decryption error:', error);
    return null;
  }
}

module.exports = {
  encryptLocation,
  decryptLocation
}; 