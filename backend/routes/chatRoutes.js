
import express from 'express';
import admin, { db } from '../firebase-admin.js';

const router = express.Router();

// Ruta para enviar un nuevo mensaje
router.post('/messages', async (req, res) => {
    try {
        const { chatId, senderId, receiverId, content, isUser } = req.body;

        const messageRef = db.collection('chats').doc(chatId).collection('messages');
        await messageRef.add({
            senderId,
            receiverId,
            content,      // Coincide con el modelo MessageModel
            isUser,       // Campo booleano que indica si el mensaje es del usuario o IA
            timestamp: new Date(),
        });

        res.status(200).json({ message: 'Mensaje enviado correctamente' });
    } catch (error) {
        console.error('Error sending message:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// Ruta para obtener el historial de mensajes de un chat
router.get('/messages/:chatId', async (req, res) => {
    try {
        const { chatId } = req.params;

        const messagesRef = db.collection('chats').doc(chatId).collection('messages');
        const q = query(messagesRef, orderBy('timestamp'));

        const querySnapshot = await getDocs(q);
        const messages = querySnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                content: data.content,
                senderId: data.senderId,
                receiverId: data.receiverId,
                isUser: data.isUser,
                timestamp: data.timestamp.toDate(),
            };
        });

        res.status(200).json(messages);
    } catch (error) {
        console.error('Error fetching chat messages:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

export default router;
