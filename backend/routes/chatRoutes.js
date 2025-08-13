// backend/routes/chatRoutes.js

import express from 'express'; 
import { db } from '../firebase-admin.js'; // Solo importamos 'db'
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { FieldValue } from 'firebase-admin/firestore'; // Importamos FieldValue directamente

const router = express.Router();

// Ruta para enviar un nuevo mensaje (AHORA CON AUTENTICACIÓN)
router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId, senderId, receiverId, content, isUser } = req.body;
        
        // Opcional: Verificar que el senderId coincide con el usuario autenticado
        if (req.firebaseUser.uid !== senderId) {
            return res.status(403).json({ error: 'ID de remitente no coincide con el usuario autenticado.' });
        }

        const messageRef = db.collection('chats').doc(chatId).collection('messages');
        await messageRef.add({
            senderId,
            receiverId,
            content,
            isUser,
            timestamp: FieldValue.serverTimestamp(), // Usamos FieldValue importado
        });

        res.status(200).json({ message: 'Mensaje enviado correctamente' });
    } catch (error) {
        console.error('Error sending message:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// Ruta para obtener el historial de mensajes de un chat (AHORA CON AUTENTICACIÓN)
router.get('/messages/:chatId', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const userId = req.firebaseUser.uid;

        // Opcional: Verificar que el usuario autenticado tenga acceso al chat
        if (chatId !== userId) {
            return res.status(403).json({ error: 'Acceso denegado a este chat.' });
        }

        const messagesRef = db.collection('chats').doc(chatId).collection('messages');
        const q = messagesRef.orderBy('timestamp');

        const querySnapshot = await q.get();
        const messages = querySnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                content: data.content,
                senderId: data.senderId,
                receiverId: data.receiverId,
                isUser: data.isUser,
                timestamp: data.timestamp?.toDate(),
            };
        });

        res.status(200).json(messages);
    } catch (error) {
        console.error('Error fetching chat messages:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

export default router;