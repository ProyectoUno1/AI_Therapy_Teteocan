// backend/routes/aiChatRoutes.js

import express from 'express';
const router = express.Router();
import { processUserMessage, loadChatMessages, validateMessageLimit } from '../routes/services/chatService.js';
import { getOrCreateAIChatId } from '../routes/services/chatService.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';

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
        if (error.message.includes('límite de mensajes gratuitos')) {
            return res.status(403).json({ error: error.message });
        }
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

        // loadChatMessages devuelve los mensajes ya desencriptados
        const messages = await loadChatMessages(userId);

        console.log(`[AI Routes] 📨 Enviando ${messages.length} mensajes al frontend:`);
        messages.forEach((msg, index) => {
            console.log(`   Mensaje ${index}: "${msg.content?.substring(0, 30)}..." | isAI: ${msg.isAI}`);
        });

        // ✅ CORREGIDO: Usar 'text' en lugar de 'content' para coincidir con el frontend
        const formattedMessages = messages.map(msg => ({
            id: msg.id,
            text: msg.content, // ← Cambiar 'content' por 'text'
            isUser: !msg.isAI, // ← Cambiar 'isAI' por 'isUser'
            senderId: msg.senderId,
            timestamp: msg.timestamp?.toISOString(),
        }));

        res.status(200).json(formattedMessages);
    } catch (error) {
        console.error('Error en /api/chats/ai-chat/messages (GET):', error);
        res.status(500).json({ error: 'Error interno del servidor al cargar el historial de chat.' });
    }
});

export default router;