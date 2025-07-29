const admin = require('firebase-admin');


const serviceAccount = require('./serviceAccountKey.json'); 


if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
   
  });
}

// Configuración para conectarse a los emuladores
if (process.env.NODE_ENV !== 'production' && process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  admin.auth().emulatorConfig = {
    host: process.env.FIREBASE_AUTH_EMULATOR_HOST,
    port: process.env.FIREBASE_AUTH_EMULATOR_HOST.split(':')[1] || 9099, // Usa el puerto si está en la var de entorno, sino 9099
  };
}

if (process.env.NODE_ENV !== 'production' && process.env.FIRESTORE_EMULATOR_HOST) {
  admin.firestore().settings({
    host: process.env.FIRESTORE_EMULATOR_HOST,
    ssl: false,
    preferRest: true, // Esto ayuda a evitar problemas de conexión con algunos entornos de emuladores
  });
}

module.exports = admin;