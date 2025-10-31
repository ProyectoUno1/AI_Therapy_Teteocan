// backend/routes/aiChatRoutes.js
// ✅ VERSIÓN SIN E2EE - ENCRIPTACIÓN BACKEND

import express from 'express';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import {
    getOrCreateAIChatId,
    loadChatMessages,
    validateMessageLimit,
} from './services/chatService.js';
import { decrypt } from '../utils/encryptionUtils.js';

const router = express.Router();

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

        // Procesar mensaje (se encripta dentro del servicio)
        const aiResponse = await processUserMessage(userId, message);

        res.status(200).json({
            aiMessage: aiResponse,
            success: true,
        });

    } catch (error) {
        console.error('❌ Error procesando mensaje:', error);
        
        if (error.message.includes('límite')) {
            return res.status(403).json({
                error: error.message,
                limitReached: true,
            });
        }

        res.status(500).json({
            error: 'Error procesando tu mensaje. Por favor, intenta de nuevo.',
        });
    }
});

// ==================== OBTENER MENSAJES ====================
router.get('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;
        const chatId = userId;

        console.log('📥 Cargando mensajes para:', userId);

        const messages = await loadChatMessages(chatId);

        // ✅ Desencriptar mensajes antes de enviar
        const decryptedMessages = messages.map(msg => ({
            ...msg,
            text: decrypt(msg.content),
        }));

        res.status(200).json(decryptedMessages);

    } catch (error) {
        console.error('❌ Error cargando mensajes:', error);
        res.status(500).json({ error: 'Error al cargar mensajes' });
    }
});

export default router;