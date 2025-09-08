// backend/routes/aiRoutes.js

import express from 'express';
import { db } from '../firebase-admin.js';
import { getOrCreateAIChatId, processUserMessage, loadChatMessages } from './services/chatService.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js'; 

const router = express.Router();

// --- Para obtener o crear el ID del chat de la IA ---
router.get('/chat-id', verifyFirebaseToken, async (req, res, next) => {
    try {
        const userId = req.firebaseUser.uid;
        if (!userId) {
            return res.status(401).json({ error: 'Usuario no autenticado.' });
        }

        const chatId = await getOrCreateAIChatId(userId);

        res.status(200).json({ chatId });
    } catch (error) {
        console.error('Error en /api/ai/chat-id (GET):', error);
        next(error);
    }
});

// --- Ruta para ENVIAR un mensaje al chat de IA y obtener la respuesta ---
router.post('/chat', verifyFirebaseToken, async (req, res, next) => {
    try {
        const userId = req.firebaseUser.uid;
        const { message } = req.body;

        if (!userId || !message) {
            return res.status(400).json({ error: 'Faltan datos de usuario o mensaje.' });
        }
        
        await getOrCreateAIChatId(userId);

        const aiResponseContent = await processUserMessage(userId, message);

        res.status(200).json({ aiMessage: aiResponseContent });
    } catch (error) {
        console.error('Error en /api/ai/chat (POST):', error);
        next(error);
    }
});

// --- Ruta para OBTENER el historial de mensajes del chat de IA ---
router.get('/chat-history', verifyFirebaseToken, async (req, res, next) => {
    try {
        const userId = req.firebaseUser.uid;
        if (!userId) {
            return res.status(401).json({ error: 'Usuario no autenticado.' });
        }

        const messages = await loadChatMessages(userId);

        const formattedMessages = messages.map(msg => ({
            id: msg.id,
            content: msg.content,
            isUser: !msg.isAI,
            timestamp: msg.timestamp?.toDate(),
        }));

        res.status(200).json(formattedMessages);
    } catch (error) {
        console.error('Error en /api/ai/chat-history (GET):', error);
        next(error);
    }
});

export default router;