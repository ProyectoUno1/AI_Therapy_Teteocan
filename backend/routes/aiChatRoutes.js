// backend/routes/aiChatRoutes.js

import express from 'express';
const router = express.Router();
import { processUserMessage, loadChatMessages } from '../routes/services/chatService.js';
import { getOrCreateAIChatId } from '../routes/services/chatService.js'; 
import verifyFirebaseToken from '../middlewares/auth_middleware.js';

// --- Ruta para ENVIAR un mensaje al chat de IA y obtener la respuesta ---

router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.userId; 
        const { message } = req.body; 

        if (!userId || !message) {
            return res.status(400).json({ error: 'Faltan datos de usuario o mensaje.' });
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
        const userId = req.userId; 
        if (!userId) {
            return res.status(401).json({ error: 'Usuario no autenticado.' });
        }

        // Asegurarse de que el chat exista o se crea si es la primera vez
        await getOrCreateAIChatId(userId);

        // Llama a la función de tu chatService para cargar los mensajes
        const messages = await loadChatMessages(userId);

       
        const formattedMessages = messages.map(msg => ({
            id: msg.id,
            text: msg.content,
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