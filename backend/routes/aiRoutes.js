// backend/routes/aiRoutes.js

import express from 'express';
import { admin, db } from '../firebase-admin.js';
import { getOrCreateAIChatId, processUserMessage, loadChatMessages } from './services/chatService.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js'; // Asegúrate de importar el middleware

const router = express.Router();

// Ruta para obtener o crear el ID del chat de IA
router.get('/chat-id', verifyFirebaseToken, async (req, res, next) => { 
    try {
        const userId = req.firebaseUser.uid; 
        const chatId = await getOrCreateAIChatId(userId); 
        res.json({ chatId });
    } catch (error) {
        console.error('Error al obtener/crear chat ID:', error);
        next(error);
    }
});

// Ruta para enviar mensajes a la IA
router.post('/chat', verifyFirebaseToken, async (req, res, next) => { 
    const { message } = req.body;
    const userId = req.firebaseUser.uid;
    const chatId = userId; 

    if (!message) { 
        return res.status(400).json({ error: 'El mensaje es requerido.' });
    }

    try {
        const aiResponse = await processUserMessage(userId, message); 
        res.json({ aiMessage: aiResponse });
    } catch (error) {
        console.error('Error al procesar mensaje con IA:', error);
        next(error);
    }
});

// Ruta para cargar el historial de mensajes
router.get('/:chatId/messages', verifyFirebaseToken, async (req, res, next) => { 
    const { chatId } = req.params;
    const userId = req.firebaseUser.uid;

    if (chatId !== userId) {
        return res.status(403).json({ error: 'Acceso denegado a este chat.' });
    }

    try {
        const messages = await loadChatMessages(chatId);
        res.json(messages);
    } catch (error) {
        console.error('Error al cargar mensajes:', error);
        next(error);
    }
});

export default router;