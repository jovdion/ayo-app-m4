const admin = require('firebase-admin');
const dotenv = require('dotenv');

dotenv.config();

const serviceAccount = {
  projectId: process.env.FIREBASE_PROJECT_ID,
  privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
};

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const messaging = admin.messaging();

module.exports = {
  admin,
  messaging,
  async sendNotification(token, title, body, data = {}) {
    try {
      const message = {
        notification: {
          title,
          body,
        },
        data,
        token,
      };

      const response = await messaging.send(message);
      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      throw error;
    }
  }
}; 