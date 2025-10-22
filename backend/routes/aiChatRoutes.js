// backend/routes/aiChatRoutes.js - ACTUALIZADO PARA E2EE

import express from 'express';
const router = express.Router();
import { processUserMessageE2EE, loadChatMessages, validateMessageLimit } from '../routes/services/chatService.js';
import { getOrCreateAIChatId } from '../routes/services/chatService.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';

// --- Ruta para ENVIAR un mensaje al chat de IA con E2EE ---
router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;
        const { message, encryptedForStorage } = req.body;

        if (!userId || !message) {
            return res.status(400).json({ error: 'Faltan datos de usuario o mensaje.' });
        }

        // Validar límite de mensajes
        const hasReachedLimit = await validateMessageLimit(userId);
        if (hasReachedLimit) {
            return res.status(403).json({ 
                error: 'Se ha alcanzado el límite de mensajes gratuitos. Por favor, actualiza tu plan.' 
            });
        }

        await getOrCreateAIChatId(userId);

        // ✅ Procesar mensaje: texto plano para Gemini, cifrado para storage
        const aiResponseContent = await processUserMessageE2EE(
            userId, 
            message,              // Mensaje plano para Gemini
            encryptedForStorage   // Mensaje cifrado para guardar (opcional)
        );

        res.status(200).json({ aiMessage: aiResponseContent });
    } catch (error) {
        console.error('Error en /api/chats/ai-chat/messages (POST):', error);
        if (error.message.includes('límite de mensajes gratuitos')) {
            return res.status(403).json({ error: error.message });
        }
        res.status(500).json({ error: 'Error interno del servidor al enviar mensaje de chat.' });
    }
});

// --- Ruta para OBTENER el historial de mensajes (pueden estar cifrados) ---
router.get('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;
        if (!userId) {
            return res.status(401).json({ error: 'Usuario no autenticado.' });
        }

        await getOrCreateAIChatId(userId);

        // ✅ Cargar mensajes (cifrados o no - el cliente decide)
        const messages = await loadChatMessages(userId);

        console.log(`[AI Routes] 📨 Enviando ${messages.length} mensajes al frontend`);

        const formattedMessages = messages.map(msg => ({
            id: msg.id,
            text: msg.content,  // Puede estar cifrado
            isUser: !msg.isAI,
            senderId: msg.senderId,
            timestamp: msg.timestamp?.toISOString(),
            isE2EE: msg.isE2EE || false, // Flag para que cliente sepa si descifrar
        }));

        res.status(200).json(formattedMessages);
    } catch (error) {
        console.error('Error en /api/chats/ai-chat/messages (GET):', error);
        res.status(500).json({ error: 'Error interno del servidor al cargar el historial de chat.' });
    }
});

export default router;