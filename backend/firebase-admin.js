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

const FIREBASE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID;


if (!admin.apps.length) {
    if (SHOULD_USE_EMULATORS) {
        console.log(' [Firebase Admin] Configurando para usar EMULADORES...');
        console.log(` Firebase Auth Emulator Host: ${process.env.FIREBASE_AUTH_EMULATOR_HOST}`);
        console.log(` Firestore Emulator Host: ${process.env.FIRESTORE_EMULATOR_HOST}`);

        process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
        process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';

        admin.initializeApp({
            projectId: FIREBASE_PROJECT_ID,
        });
        console.log(` Firebase Admin SDK inicializado para EMULADORES (Project ID: ${FIREBASE_PROJECT_ID}).`);
    } else {
        console.log(' [Firebase Admin] Configurando para usar CLOUD (Producción)...');
        try {
            
            

            const serviceAccount = require('./serviceAccountKey.json');
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
                projectId: FIREBASE_PROJECT_ID,
            });
            console.log(' Firebase Admin SDK inicializado para CLOUD.');
        } catch (err) {
            console.error('❌ Error: No se pudo cargar el archivo serviceAccountKey.json.');
            console.error('❌ Por favor, descarga la clave privada de tu proyecto desde la Consola de Firebase, renómbrala a \"serviceAccountKey.json\" y colócala en la carpeta \"backend\".');
            throw err;
        }
    }
} else {
    console.log('✅ [Firebase Admin] SDK ya estaba inicializado.');
}

const auth = admin.auth();
const db = getFirestore();

// Exportamos 'admin' explícitamente para que pueda ser importado
export { admin, auth, db };