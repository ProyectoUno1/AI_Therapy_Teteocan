// C:\Users\Aby15\OneDrive\Escritorio\AI_Therapy_Teteocan\backend\firebase-admin.js

import admin from 'firebase-admin';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);

// Cargar variables de entorno al principio
import dotenv from 'dotenv';
dotenv.config();

// Define si estamos en modo desarrollo/emuladores
const IS_DEVELOPMENT_ENV = process.env.NODE_ENV === 'development';
const USE_EMULATORS_FLAG = process.env.USE_EMULATORS === 'true';

const SHOULD_USE_EMULATORS = IS_DEVELOPMENT_ENV || USE_EMULATORS_FLAG;

// --- Define tu Project ID de Firebase aquí ---
// Puedes encontrarlo en la Consola de Firebase -> Configuración del proyecto
// Es el ID de tu proyecto real, aunque estemos usando emuladores.
const FIREBASE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'tu-project-id-aqui'; // <-- ¡IMPORTANTE: Reemplaza con tu Project ID real!

if (!admin.apps.length) {
    if (SHOULD_USE_EMULATORS) {
        console.log('🔗 [Firebase Admin] Configurando para usar EMULADORES...');

        process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
        process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';

        // Inicializa Firebase Admin SDK con el Project ID
        // Esto le dice a GoogleAuth a qué proyecto "simulado" se debe asociar.
        admin.initializeApp({
            projectId: FIREBASE_PROJECT_ID, // <-- ¡PASAMOS EL PROJECT ID AQUÍ!
        });
        console.log(`✅ Firebase Admin SDK inicializado para EMULADORES (Project ID: ${FIREBASE_PROJECT_ID}).`);

    } else {
        console.log('🌐 [Firebase Admin] Configurando para usar CLOUD (Producción)...');
        const serviceAccount = require('./serviceAccountKey.json');
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: FIREBASE_PROJECT_ID, // También es buena práctica incluirlo aquí
        });
        console.log('✅ Firebase Admin SDK inicializado para CLOUD.');
    }
} else {
    console.log('✅ [Firebase Admin] SDK ya estaba inicializado.');
}

// Exporta las instancias
export const db = admin.firestore();
export const auth = admin.auth();