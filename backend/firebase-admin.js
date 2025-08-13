// AI_Therapy_Teteocan/backend/firebase-admin.js

import admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";
import dotenv from "dotenv";
import { createRequire } from "module";
const require = createRequire(import.meta.url);

dotenv.config();

// Define si estamos en modo desarrollo/emuladores
const IS_DEVELOPMENT_ENV = process.env.NODE_ENV === "development";
const USE_EMULATORS_FLAG = process.env.USE_EMULATORS === "true";
const SHOULD_USE_EMULATORS = IS_DEVELOPMENT_ENV || USE_EMULATORS_FLAG;

// Es el ID de tu proyecto real, aunque estemos usando emuladores.
const FIREBASE_PROJECT_ID =
    process.env.FIREBASE_PROJECT_ID || "aurora-2b8f4";

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
        console.log(
            "🌐 [Firebase Admin] Configurando para usar CLOUD (Producción)..."
        );

        // Verificar si existe el archivo de credenciales
        try {
            const serviceAccount = require("./serviceAccountKey.json");
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
                projectId: FIREBASE_PROJECT_ID,
            });
            console.log(
                "✅ Firebase Admin SDK inicializado para CLOUD con serviceAccountKey.json."
            );
        } catch (error) {
            console.error(
                "❌ ERROR FATAL: No se encontró serviceAccountKey.json o las credenciales no son válidas.",
                "Asegúrate de que el archivo esté en la ruta correcta y que tu servidor lo pueda leer."
            );
            
            throw new Error("No se pudo inicializar Firebase Admin sin credenciales válidas.");
        }
    }
} else {
    console.log("✅ [Firebase Admin] SDK ya estaba inicializado.");
}


export const db = getFirestore();
export const auth = admin.auth();


export default admin;