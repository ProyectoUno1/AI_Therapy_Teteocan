// backend/routes/aiRoutes.js

// Importa Express usando la sintaxis de módulos ES
import express from 'express';

// Importa las funciones específicas de chatService.js
// Asegúrate de que chatService.js también use 'export' para estas funciones
// ¡Importante: añade la extensión .js!
import { getOrCreateAIChatId, processUserMessage, loadChatMessages } from './services/chatService.js';

// Si tienes un middleware de autenticación, impórtalo así.
// Asegúrate de que tu archivo auth.js también use 'export default' o 'export'
// import authenticateToken from '../middleware/auth.js'; // Descomenta si lo usas

const router = express.Router();

// Ruta para obtener o crear el ID del chat de IA
router.get('/chat-id', async (req, res, next) => { // Añade 'next' para el manejo de errores
    try {
        // En una app real, el userId vendría del token de autenticación
        // req.userId debería ser establecido por un middleware de autenticación anterior
        const userId = req.userId || 'test_user_id'; // Usa req.userId si está disponible
        const chatId = await getOrCreateAIChatId(userId); // Llama a la función importada
        res.json({ chatId });
    } catch (error) {
        console.error('Error al obtener/crear chat ID:', error);
        // Pasa el error al manejador de errores global
        next(error);
    }
});

// Ruta para enviar mensajes a la IA
router.post('/chat', async (req, res, next) => { // Añade 'next' para el manejo de errores
    const { message } = req.body;
    const userId = req.userId || 'test_user_id'; // Usa req.userId si está disponible
    const chatId = userId; // Asumimos que el chatId para la IA es el mismo que el userId

    if (!message) { // Solo necesitamos el mensaje, userId y chatId se obtienen
        return res.status(400).json({ error: 'El mensaje es requerido.' });
    }

    try {
        const aiResponse = await processUserMessage(userId, message); // Llama a la función importada
        res.json({ aiMessage: aiResponse });
    } catch (error) {
        console.error('Error al procesar mensaje con IA:', error);
        // Pasa el error al manejador de errores global
        next(error);
    }
});

// Ruta para cargar el historial de mensajes
router.get('/:chatId/messages', async (req, res, next) => { // Añade 'next' para el manejo de errores
    const { chatId } = req.params;
    const userId = req.userId || 'test_user_id'; // Asegúrate de que el usuario autenticado tiene acceso

    // Lógica de seguridad: Asegúrate de que el usuario solo pueda ver sus propios chats de IA
    if (chatId !== userId) {
        return res.status(403).json({ error: 'Acceso denegado a este chat.' });
    }

    try {
        const messages = await loadChatMessages(chatId); // Llama a la función importada
        res.json(messages);
    } catch (error) {
        console.error('Error al cargar mensajes:', error);
        // Pasa el error al manejador de errores global
        next(error);
    }
});

// Exporta el router usando la sintaxis de módulos ES
export default router;