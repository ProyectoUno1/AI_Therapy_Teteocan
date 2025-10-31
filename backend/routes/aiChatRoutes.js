// backend/routes/aiChatRoutes.js
// ✅ VERSIÓN SIN E2EE - ENCRIPTACIÓN BACKEND

import express from 'express';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import {
    getOrCreateAIChatId,
    loadChatMessages,
    validateMessageLimit,
    processUserMessage, // <-- ASEGÚRESE DE QUE ESTA FUNCIÓN ESTÉ CORRECTAMENTE IMPORTADA Y DISPONIBLE EN 'chatService.js'
} from './services/chatService.js';
import { decrypt } from '../utils/encryptionUtils.js';

const router = express.Router();

// ... (GET /chat-id - Sin cambios)

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
                error: 'Has alcanzado tu límite de mensajes. Actualiza a Premium para continuar.',
                limitReached: true,
            });
        }

        // Procesar mensaje (se encripta dentro del servicio, se guarda y se devuelve la respuesta)
        // 💡 El error 500 ocurre casi siempre DENTRO de processUserMessage
        const aiResponse = await processUserMessage(userId, message);

        res.status(200).json({
            aiMessage: aiResponse,
            success: true,
        });

    } catch (error) {
        // [CORRECCIÓN CLAVE] Log más detallado del error 500
        console.error('❌ ERROR GRAVE EN POST /ai-chat/messages:', error.stack || error.message);
        
        if (error.message.includes('límite')) {
            return res.status(403).json({
                error: error.message,
                limitReached: true,
            });
        }

        // [CORRECCIÓN CLAVE] Devolver información útil en desarrollo
        const errorMessage = process.env.NODE_ENV !== 'production' 
                           ? `Error del servidor: ${error.message}` 
                           : 'Error procesando tu mensaje. Por favor, intenta de nuevo.';

        res.status(500).json({
            error: errorMessage,
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
            // Si decrypt falla (AuthTag o clave incorrecta), devuelve el 'content' original.
            text: decrypt(msg.content),
        }));

        res.status(200).json(decryptedMessages);

    } catch (error) {
        // [CORRECCIÓN] Log más útil
        console.error('❌ Error cargando mensajes de IA:', error.message);
        res.status(500).json({ error: 'Error al cargar mensajes' });
    }
});

export default router;