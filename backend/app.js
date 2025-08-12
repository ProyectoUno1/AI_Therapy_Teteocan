// \AI_Therapy_Teteocan\backend\app.js

import express from 'express';
import cors from 'cors';
import aiRoutes from './routes/aiRoutes.js';
import patientsRoutes from './routes/patients.js';
import psychologistsRoutes from './routes/psychologists.js';
import aiChatRoutes from './routes/aiChatRoutes.js';
import chatRoutes from './routes/chatRoutes.js'; 
import psychologistProfessionalProfileRoutes from './routes/psychologist_professional_profile.js';

import { auth, db } from './firebase-admin.js';

const app = express();

// --- Middlewares Globales ---
app.use(cors());
app.use(express.json()); // Para interpretar cuerpos de petición JSON

app.get('/', (req, res) => {
    res.send('¡Aurora Backend funcionando en modo DESARROLLO!');
});


// --- Configuración de rutas ---
app.use('/api/patients', patientsRoutes);
app.use('/api/psychologists', psychologistsRoutes);
app.use('/api/psychologists', psychologistProfessionalProfileRoutes);

app.use('/api/ai', aiRoutes);
app.use('/api/chats/ai-chat', aiChatRoutes);
app.use('/api/chats', chatRoutes);


// --- Manejador de Errores Global ---
app.use((error, req, res, next) => {
    
    console.error('💥 Error global capturado:', error);
    res.status(error.status || 500).json({
        error: error.message || 'Internal server error' 
    });
});


export default app;