// backend/routes/aiChatRoutes.js

import express from 'express';
const router = express.Router();
import { processUserMessage, loadChatMessages, validateMessageLimit } from '../routes/services/chatService.js';
import { getOrCreateAIChatId } from '../routes/services/chatService.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { decrypt } from '../utils/encryptionUtils.js';
import { db } from '../firebase-admin.js';

// --- Ruta para ENVIAR un mensaje al chat de IA y obtener la respuesta ---

router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;
        const { message } = req.body;

        if (!userId || !message) {
            return res.status(400).json({ error: 'Faltan datos de usuario o mensaje.' });
        }

        // Valida si el usuario ha alcanzado el límite de mensajes
        const hasReachedLimit = await validateMessageLimit(userId);
        if (hasReachedLimit) {
            return res.status(403).json({ error: 'Se ha alcanzado el límite de mensajes gratuitos. Por favor, actualiza tu plan.' });
        }

        await getOrCreateAIChatId(userId);

        const aiResponseContent = await processUserMessage(userId, message);

        res.status(200).json({ aiMessage: aiResponseContent });
    } catch (error) {
        console.error('Error en /api/chats/ai-chat/messages (POST):', error);
        res.status(500).json({ error: 'Error interno del servidor al enviar mensaje de chat.' });
    }
});

// --- Ruta para OBTENER el historial de mensajes del chat de IA ---

router.get('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;
        if (!userId) {
            return res.status(401).json({ error: 'Usuario no autenticado.' });
        }

        await getOrCreateAIChatId(userId);

        const messages = await loadChatMessages(userId);

        const formattedMessages = messages.map(msg => ({
            id: msg.id,
            text: decrypt(msg.content),
            isUser: !msg.isAI,
            timestamp: msg.timestamp?.toISOString(),
        }));

        res.status(200).json(formattedMessages);
    } catch (error) {
        console.error('Error en /api/chats/ai-chat/messages (GET):', error);
        res.status(500).json({ error: 'Error interno del servidor al cargar el historial de chat.' });
    }
});

export default router;