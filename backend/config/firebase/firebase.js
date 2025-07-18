const admin = require('firebase-admin');
const path = require('path');
require('dotenv').config();

// Detectar si estamos en modo desarrollo (usando emulator)
const isEmulator = process.env.USE_FIREBASE_EMULATOR === 'true' || process.env.NODE_ENV === 'development';

if (!admin.apps.length) {
  if (isEmulator) {
    // Configuración para Firebase Emulator
    console.log('🔧 Inicializando Firebase Admin para EMULATOR');
    admin.initializeApp({
      projectId: process.env.FIREBASE_PROJECT_ID || 'aurora-2b8f4',
    });
    
    // Configurar el emulator para Auth
    if (process.env.FIREBASE_AUTH_EMULATOR_HOST) {
      process.env.FIREBASE_AUTH_EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST;
      console.log(`🔧 Firebase Auth Emulator: ${process.env.FIREBASE_AUTH_EMULATOR_HOST}`);
    }
  } else {
    // Configuración para producción
    console.log('🚀 Inicializando Firebase Admin para PRODUCCIÓN');
    const serviceAccount = require(path.join(__dirname, 'firebase_secret_key.json'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }
}

module.exports = admin;