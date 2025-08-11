// AI_Therapy_Teteocan/backend/firebase-admin.js

import admin from 'firebase-admin';
import { getFirestore } from 'firebase-admin/firestore';
import dotenv from 'dotenv';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);

dotenv.config();

// Define si estamos en modo desarrollo/emuladores
const IS_DEVELOPMENT_ENV = process.env.NODE_ENV === 'development';
const USE_EMULATORS_FLAG = process.env.USE_EMULATORS === 'true';
const SHOULD_USE_EMULATORS = IS_DEVELOPMENT_ENV || USE_EMULATORS_FLAG;

// Es el ID de tu proyecto real, aunque estemos usando emuladores.
const FIREBASE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'tu-project-id-aqui'; // <-- ¡IMPORTANTE: Reemplaza con tu Project ID real!

if (!admin.apps.length) {
    if (SHOULD_USE_EMULATORS) {
        console.log('🔗 [Firebase Admin] Configurando para usar EMULADORES...');

        process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
        process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';

        admin.initializeApp({
            projectId: FIREBASE_PROJECT_ID,
        });
        console.log(`✅ Firebase Admin SDK inicializado para EMULADORES (Project ID: ${FIREBASE_PROJECT_ID}).`);
    } else {
        console.log('🌐 [Firebase Admin] Configurando para usar CLOUD (Producción)...');
        const serviceAccount = require('./serviceAccountKey.json');
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: FIREBASE_PROJECT_ID,
        });
        console.log('✅ Firebase Admin SDK inicializado para CLOUD.');
    }
} else {
    console.log('✅ [Firebase Admin] SDK ya estaba inicializado.');
}

// Exporta las instancias de Firebase que usarás en otras partes de la app
export const db = getFirestore();
export const auth = admin.auth();

// Exporta 'admin' como la exportación por defecto
export default admin;