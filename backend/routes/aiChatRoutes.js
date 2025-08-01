// backend/routes/aiChatRoutes.js

import express from 'express';
const router = express.Router();

// Importa las funciones de chatService.js que ya tienes
import { processUserMessage, loadChatMessages } from '../routes/services/chatService.js';
import { getOrCreateAIChatId } from '../routes/services/chatService.js'; // También puedes importar esta si la usas aquí

// Importa tu middleware de autenticación
import verifyFirebaseToken from '../middlewares/auth_middleware.js';

// --- Ruta para ENVIAR un mensaje al chat de IA y obtener la respuesta ---
// Esta ruta es la que tu frontend llama para enviar el mensaje del usuario a Aurora.
// Usará `processUserMessage` que ya guarda y responde.
router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.userId; // Asegúrate de que tu middleware adjunte el userId
        const { message } = req.body; // El mensaje que viene de Flutter

        if (!userId || !message) {
            return res.status(400).json({ error: 'Faltan datos de usuario o mensaje.' });
        }

        // Asegúrate de que el chat exista o créalo si es la primera vez
        await getOrCreateAIChatId(userId);

        // Llama a la función de tu chatService para procesar y guardar el mensaje
        const aiResponseContent = await processUserMessage(userId, message);

        res.status(200).json({ aiMessage: aiResponseContent });
    } catch (error) {
        console.error('❌ Error en /api/chats/ai-chat/messages (POST):', error);
        res.status(500).json({ error: 'Error interno del servidor al enviar mensaje de chat.' });
    }
});

// --- Ruta para OBTENER el historial de mensajes del chat de IA ---
// Esta ruta es la que tu frontend llama cuando el usuario entra al chat para cargar los mensajes previos.
// Aquí se solucionará el `Cannot GET` 404.
router.get('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.userId; // Asegúrate de que tu middleware adjunte el userId
        if (!userId) {
            return res.status(401).json({ error: 'Usuario no autenticado.' });
        }

        // Asegúrate de que el chat exista o créalo si es la primera vez
        await getOrCreateAIChatId(userId);

        // Llama a la función de tu chatService para cargar los mensajes
        const messages = await loadChatMessages(userId);

        // Aquí debes adaptar el formato de los mensajes para que coincida con lo que tu Flutter espera.
        // Tu Flutter espera: { id, text, isUser, timestamp }
        // Tu loadChatMessages devuelve: { id, senderId, content, timestamp, isAI, type, attachmentUrl }
        const formattedMessages = messages.map(msg => ({
            id: msg.id,
            text: msg.content,
            isUser: !msg.isAI, // isUser es true si NO es AI
            timestamp: msg.timestamp?.toISOString(), // Convierte Date a ISO string para Flutter
        }));

        res.status(200).json(formattedMessages);
    } catch (error) {
        console.error('❌ Error en /api/chats/ai-chat/messages (GET):', error);
        res.status(500).json({ error: 'Error interno del servidor al cargar el historial de chat.' });
    }
});

export default router;