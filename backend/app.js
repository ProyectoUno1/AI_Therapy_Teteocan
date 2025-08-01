// C:\Users\Aby15\OneDrive\Escritorio\AI_Therapy_Teteocan\backend\app.js

import express from 'express';
import cors from 'cors';
// No necesitas dotenv.config() aquí si ya lo haces en server.js o en firebase-admin.js
// import dotenv from 'dotenv';
// dotenv.config(); // Solo si es el primer lugar donde cargas variables de entorno



// --- Importa tus Routers usando sintaxis ES y con extensión .js ---
import aiRoutes from './routes/aiRoutes.js';
import patientsRoutes from './routes/patients.js';
import psychologistsRoutes from './routes/psychologists.js';
import aiChatRoutes from './routes/aiChatRoutes.js';

import { auth, db } from './firebase-admin.js';

const app = express();

// --- Middlewares Globales ---
app.use(cors());
app.use(express.json()); // Para interpretar cuerpos de petición JSON

// --- Middleware de Autenticación Firebase (Adaptado para Desarrollo) ---
// Este middleware es CRÍTICO para asegurar quién hace la petición.
// 'admin' ya estará inicializado gracias a la importación de 'firebase-admin.js'
app.use(async (req, res, next) => {
    // La variable 'idToken' y la lógica de 'if (!idToken)' está correcta
    const idToken = req.headers.authorization?.split('Bearer ')[1];

    if (!idToken) {
        console.warn('⚠️ No se proporcionó token de autorización. Usando userId de PRUEBA para desarrollo.');
        req.userId = 'test_dev_user_id';
        return next();
    }

    try {
        // --- ¡CORRECCIÓN CLAVE AQUÍ! ---
        // Usa la instancia 'auth' que importaste directamente
        const decodedToken = await auth.verifyIdToken(idToken); // <-- ¡Cambia 'admin.auth()' a 'auth'!
        req.userId = decodedToken.uid;
        console.log(`👤 Usuario autenticado (Firebase): ${req.userId}`);
        next();
    } catch (error) {
        console.error('❌ Error al verificar token de Firebase:', error);
        console.error('❌ Código de error:', error.code); // Mostrar el código de error para más detalle
        return res.status(403).json({ error: 'Token de autenticación inválido o expirado.' });
    }
});

app.get('/', (req, res) => {
    res.send('¡Aurora Backend funcionando en modo DESARROLLO!');
});

app.use('/api/patients', patientsRoutes);
app.use('/api/psychologists', psychologistsRoutes);

app.use('/api/ai', aiRoutes);
app.use('/api/chats/ai-chat', aiChatRoutes);

// --- Manejador de Errores Global ---
app.use((error, req, res, next) => {
    console.error('💥 Error global capturado:', error);
    res.status(error.status || 500).json({
        error: error.message || 'Internal server error' 
    });
});


export default app;