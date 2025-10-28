// backend/routes/aiChatRoutes.js - CORREGIDO

import express from 'express';
const router = express.Router();
import { db } from '../firebase-admin.js';
import { FieldValue } from 'firebase-admin/firestore';
import { processUserMessageE2EE, loadChatMessages } from '../routes/services/chatService.js';
import { getOrCreateAIChatId } from '../routes/services/chatService.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';

// ✅ RUTA PARA ENVIAR MENSAJE A IA CON E2EE
router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;
        const { message, encryptedForStorage } = req.body;

        console.log('📨 Recibiendo mensaje para IA');
        console.log('👤 UserId:', userId);
        console.log('📝 Mensaje (plano):', message?.substring(0, 50));
        console.log('🔐 Tiene versión cifrada:', !!encryptedForStorage);

        if (!message || message.trim() === '') {
            return res.status(400).json({ error: 'El mensaje no puede estar vacío' });
        }

        // Procesar mensaje con IA (texto plano para Gemini, cifrado para storage)
        const aiResponse = await processUserMessageE2EE(
            userId,
            message,                // Texto plano para Gemini
            encryptedForStorage     // Cifrado para guardar (opcional)
        );

        console.log('✅ Respuesta generada por IA');

        res.status(200).json({
            aiMessage: aiResponse,  // Respuesta en texto plano
            success: true
        });

    } catch (error) {
        console.error('❌ Error en /ai-chat/messages:', error);

        if (error.message === 'LIMIT_REACHED') {
            return res.status(403).json({
                error: 'Has alcanzado tu límite de mensajes gratuitos. Actualiza a Premium para continuar.',
                limitReached: true
            });
        }

        res.status(500).json({
            error: 'Error al procesar el mensaje',
            details: error.message
        });
    }
});

// ✅ RUTA PARA OBTENER MENSAJES DE IA (CORREGIDA)
router.get('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;
        
        console.log('📥 Cargando mensajes de IA para usuario:', userId);

        // Cargar mensajes desde Firestore
        const messages = await loadChatMessages(userId);

        console.log(`✅ Mensajes cargados: ${messages.length}`);

        // Transformar al formato esperado por el frontend
        const formattedMessages = messages.map(msg => ({
            id: msg.id,
            text: msg.content,           // ✅ Contenido (puede estar cifrado)
            isUser: !msg.isAI,           // ✅ true si es del usuario
            senderId: msg.senderId,
            timestamp: msg.timestamp,
            isE2EE: msg.isE2EE || false, // ✅ Indicar si está cifrado
        }));

        res.status(200).json(formattedMessages);

    } catch (error) {
        console.error('❌ Error cargando mensajes de IA:', error);
        res.status(500).json({
            error: 'Error al cargar mensajes',
            details: error.message
        });
    }
});

// ✅ RUTA PARA OBTENER/CREAR CHAT ID
router.get('/chat-id', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;
        const chatId = await getOrCreateAIChatId(userId);
        
        res.status(200).json({ chatId });
    } catch (error) {
        console.error('Error obteniendo chat ID:', error);
        res.status(500).json({ error: 'Error al obtener ID del chat' });
    }
});

export default router;