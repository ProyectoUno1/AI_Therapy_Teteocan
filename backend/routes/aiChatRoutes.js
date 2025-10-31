// backend/routes/aiChatRoutes.js
// ✅ VERSIÓN SIN ENCRIPTACIÓN

import express from 'express';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import {
    getOrCreateAIChatId,
    loadChatMessages,
    validateMessageLimit,
    processUserMessage,
} from './services/chatService.js';

const router = express.Router();
const IS_PRODUCTION = process.env.NODE_ENV === 'production';

// ==================== OBTENER/CREAR CHAT ID ====================
router.get('/chat-id', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;
        const chatId = await getOrCreateAIChatId(userId);
        res.status(200).json({ chatId });
    } catch (error) {
        console.error('❌ Error obteniendo chat ID:', error);
        res.status(500).json({ error: 'Error al obtener chat ID' });
    }
});

// ==================== ENVIAR MENSAJE A IA ====================
router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;
        const { message } = req.body;

        if (!message || message.trim() === '') {
            return res.status(400).json({ error: 'El mensaje no puede estar vacío' });
        }

        console.log('📨 Mensaje recibido de usuario:', userId);

        // Validar límite de mensajes
        const isLimitReached = await validateMessageLimit(userId);
        if (isLimitReached) {
            return res.status(403).json({
                error: 'Has alcanzado tu límite de mensajes gratuitos. Actualiza a Premium para continuar.',
                limitReached: true,
            });
        }

        // ✅ Procesar mensaje (SIN ENCRIPTACIÓN)
        const aiResponse = await processUserMessage(userId, message);

        res.status(200).json({
            aiMessage: aiResponse,
            success: true,
        });

    } catch (error) {
        console.error('❌ Error procesando mensaje:', error.stack || error.message);
        
        if (error.message.includes('límite')) {
            return res.status(403).json({
                error: error.message,
                limitReached: true,
            });
        }

        const errorMessage = IS_PRODUCTION
                           ? 'Error procesando tu mensaje. Por favor, intenta de nuevo.'
                           : `Error del servidor: ${error.message}`;

        res.status(500).json({
            error: errorMessage,
        });
    }
});

// ==================== OBTENER MENSAJES (SIN DESENCRIPTACIÓN) ====================
router.get('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;
        const chatId = userId;

        console.log('📥 Cargando mensajes para:', userId);

        // ✅ Cargar mensajes (YA SON TEXTO PLANO)
        const messages = await loadChatMessages(chatId);

        // ✅ Devolver mensajes tal como están
        const formattedMessages = messages.map(msg => ({
            id: msg.id,
            senderId: msg.senderId,
            text: msg.content, // ✅ YA ES TEXTO PLANO
            timestamp: msg.timestamp,
            isAI: msg.isAI,
        }));

        res.status(200).json(formattedMessages);

    } catch (error) {
        console.error('❌ Error cargando mensajes:', error);
        res.status(500).json({ error: 'Error al cargar mensajes' });
    }
});

export default router;