const crypto = require('crypto');

// Generate a 256-bit (32 bytes) random key
const key = crypto.randomBytes(32);

// Convert to base64 for easy storage
const base64Key = key.toString('base64');

console.log('Generated Encryption Key (save this securely):');
console.log(base64Key);

// Example of how to use in .env file
console.log('\nAdd this to your .env file:');
console.log(`ENCRYPTION_KEY=${base64Key}`); 