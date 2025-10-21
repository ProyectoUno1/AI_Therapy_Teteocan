// AI_Therapy_Teteocan/backend/firebase-admin.js

import admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";
import dotenv from "dotenv";
import { createRequire } from "module";
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const require = createRequire(import.meta.url);
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config();

// Define si estamos en modo desarrollo/emuladores
const IS_DEVELOPMENT_ENV = process.env.NODE_ENV === "development";
const USE_EMULATORS_FLAG = process.env.USE_EMULATORS === "true";
const SHOULD_USE_EMULATORS = IS_DEVELOPMENT_ENV || USE_EMULATORS_FLAG;

const FIREBASE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID || "aurora-2b8f4";

if (!admin.apps.length) {
    if (SHOULD_USE_EMULATORS) {
        console.log("🔗 [Firebase Admin] Configurando para usar EMULADORES...");

        admin.initializeApp({
            projectId: FIREBASE_PROJECT_ID,
        });
        console.log(
            `✅ Firebase Admin SDK inicializado para EMULADORES (Project ID: ${FIREBASE_PROJECT_ID}).`
        );
    } else {
        console.log("☁️ [Firebase Admin] Configurando para usar CLOUD (Producción)...");

        try {
            // PRIORIDAD 1: Intentar cargar desde variable de entorno (RENDER)
            if (process.env.FIREBASE_SERVICE_ACCOUNT) {
                console.log("📝 Cargando credenciales desde variable de entorno...");
                const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
                
                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount),
                    projectId: FIREBASE_PROJECT_ID,
                });
                console.log("✅ Firebase Admin SDK inicializado con credenciales de variable de entorno.");
            } 
            // PRIORIDAD 2: Fallback a archivo local (DESARROLLO)
            else {
                console.log("📄 Cargando credenciales desde archivo local...");
                const serviceAccountPath = join(__dirname, 'serviceAccountKey.json');
                const serviceAccount = require(serviceAccountPath);
                
                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount),
                    projectId: FIREBASE_PROJECT_ID,
                });
                console.log("✅ Firebase Admin SDK inicializado con serviceAccountKey.json.");
            }
        } catch (error) {
            console.error("❌ ERROR FATAL: No se pudieron cargar las credenciales de Firebase.");
            console.error("Detalles:", error.message);
            
            // En producción, intentar usar Application Default Credentials como último recurso
            if (process.env.NODE_ENV === 'production') {
                console.log("🔄 Intentando usar Application Default Credentials...");
                try {
                    admin.initializeApp({
                        projectId: FIREBASE_PROJECT_ID,
                    });
                    console.log("✅ Firebase Admin SDK inicializado con ADC.");
                } catch (adcError) {
                    console.error("❌ No se pudo inicializar con ADC:", adcError.message);
                    throw new Error("No se pudo inicializar Firebase Admin SDK.");
                }
            } else {
                throw new Error("No se pudo inicializar Firebase Admin sin credenciales válidas.");
            }
        }
    }
} else {
    console.log("ℹ️ [Firebase Admin] SDK ya estaba inicializado.");
}

export const db = getFirestore();
export const auth = admin.auth();

export default admin;