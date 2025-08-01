// backend/routes/aiRoutes.js

import express from 'express';
import { getOrCreateAIChatId, processUserMessage, loadChatMessages } from './services/chatService.js';

const router = express.Router();

// Ruta para obtener o crear el ID del chat de IA
router.get('/chat-id', async (req, res, next) => { 
    try {
        
        const userId = req.userId || 'test_user_id'; 
        const chatId = await getOrCreateAIChatId(userId); 
        res.json({ chatId });
    } catch (error) {
        console.error('Error al obtener/crear chat ID:', error);
        // Pasa el error al manejador de errores global
        next(error);
    }
});

// Ruta para enviar mensajes a la IA
router.post('/chat', async (req, res, next) => { 
    const { message } = req.body;
    const userId = req.userId || 'test_user_id'; 
    const chatId = userId; 

    if (!message) { 
        return res.status(400).json({ error: 'El mensaje es requerido.' });
    }

    try {
        const aiResponse = await processUserMessage(userId, message); 
        res.json({ aiMessage: aiResponse });
    } catch (error) {
        console.error('Error al procesar mensaje con IA:', error);
        // Pasa el error al manejador de errores global
        next(error);
    }
});

// Ruta para cargar el historial de mensajes
router.get('/:chatId/messages', async (req, res, next) => { 
    const { chatId } = req.params;
    const userId = req.userId || 'test_user_id'; 

    if (chatId !== userId) {
        return res.status(403).json({ error: 'Acceso denegado a este chat.' });
    }

    try {
        const messages = await loadChatMessages(chatId);
        res.json(messages);
    } catch (error) {
        console.error('Error al cargar mensajes:', error);
        // Pasa el error al manejador de errores global
        next(error);
    }
});

export default router;