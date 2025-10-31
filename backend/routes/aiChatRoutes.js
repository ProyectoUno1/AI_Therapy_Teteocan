// backend/routes/aiChatRoutes.js
// ✅ VERSIÓN FINAL SIN E2EE - SOLO CIFRADO/DESCIFRADO EN EL BACKEND

import express from 'express';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import {
    getOrCreateAIChatId,
    loadChatMessages,
    validateMessageLimit,
    // [CORRECCIÓN D] Importar la función simple
    processUserMessage, 
} from './services/chatService.js';
// [CORRECCIÓN E] Quitar 'encrypt' (lo hace el servicio)
import { decrypt } from '../utils/encryptionUtils.js'; 

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
        // 'message' es el texto plano enviado desde el cliente
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

        // [CORRECCIÓN F] Llamar a la función simple y pasar solo el texto plano
        // El servicio se encarga de cifrarlo antes de guardar.
        const aiResponse = await processUserMessage(userId, message); 

        res.status(200).json({
            aiMessage: aiResponse,
            success: true,
        });

    } catch (error) {
        // [CORRECCIÓN G] Log mejorado para diagnosticar el Error 500
        console.error('❌ ERROR GRAVE EN POST /ai-chat/messages:', error.stack || error.message);
        
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

// ==================== OBTENER MENSAJES ====================
router.get('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;
        const chatId = userId;

        console.log('📥 Cargando mensajes para:', userId);

        const messages = await loadChatMessages(chatId);

        // [CORRECCIÓN H] Desencriptar condicionalmente (si no es de la IA, está cifrado)
        const decryptedMessages = messages.map(msg => {
            let decryptedText = msg.content;
            
            // Si el mensaje NO es de la IA (senderId es 'aurora'), está cifrado y debe descifrarse.
            if (msg.senderId !== 'aurora' && !msg.isAI) {
                 decryptedText = decrypt(msg.content);
            }
            // Si es de 'aurora' (la IA), se guardó en texto plano y pasa sin cambios.

            return {
                ...msg,
                text: decryptedText, // Campo final que el cliente usa
            };
        });

        res.status(200).json(decryptedMessages);

    } catch (error) {
        console.error('❌ Error cargando mensajes de IA:', error.message);
        res.status(500).json({ error: 'Error al cargar mensajes' });
    }
});

export default router;