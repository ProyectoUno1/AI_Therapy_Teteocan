// backend/routes/chatRoutes.js
// ✅ CÓDIGO CORREGIDO: Incluye campo participants

import express from 'express'; 
import { db } from '../firebase-admin.js'; 
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { FieldValue } from 'firebase-admin/firestore';

const router = express.Router();

//enviar mensaje
router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId, senderId, receiverId, content } = req.body;;
        
        if (!chatId || !senderId || !receiverId || !content) {
            return res.status(400).json({ 
                error: 'Faltan campos requeridos (chatId, senderId, receiverId, content)' 
            });
        }
        
        if (req.firebaseUser.uid !== senderId) {
            return res.status(403).json({ 
                error: 'ID de remitente no coincide con el usuario autenticado.' 
            });
        }

        const chatDocRef = db.collection('chats').doc(chatId);
        const messageRef = chatDocRef.collection('messages');
        const messageData = {
            senderId,
            receiverId,
            content: content, 
            timestamp: FieldValue.serverTimestamp(),
            isRead: false,
        };
        
        const newMessageDoc = await messageRef.add(messageData);

        await chatDocRef.set({
            lastMessage: content,
            lastMessageTime: FieldValue.serverTimestamp(),
            lastMessageSenderId: senderId,
            participants: [senderId, receiverId], 
            updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });

        res.status(200).json({ 
            message: 'Mensaje enviado exitosamente', 
            content: content,
            messageId: newMessageDoc.id
        });

    } catch (error) {
        console.error('Error enviando mensaje:', error);
        res.status(500).json({ 
            error: 'Error interno del servidor', 
            details: error.message 
        });
    }
});

// obtener mensajes de un chat
router.get('/:chatId/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const userId = req.firebaseUser.uid;

        // Verificar que el usuario es parte del chat
        const chatParts = chatId.split('_');
        if (!chatParts.includes(userId)) {
            return res.status(403).json({ error: 'Acceso denegado a este chat.' });
        }

        const messagesSnapshot = await db.collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', 'asc')
            .get();

        const messages = messagesSnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                senderId: data.senderId,
                receiverId: data.receiverId,
                content: data.content, 
                timestamp: data.timestamp ? data.timestamp.toDate().toISOString() : null,
                isRead: data.isRead || false,
            };
        });
        res.status(200).json(messages);

    } catch (error) {
        console.error('Error cargando mensajes:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});


router.post('/:chatId/mark-read', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const { userId } = req.body;

        if (req.firebaseUser.uid !== userId) {
            return res.status(403).json({ error: 'Acceso denegado.' });
        }

        const batch = db.batch();
        const messagesSnapshot = await db.collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('receiverId', '==', userId)
            .where('isRead', '==', false)
            .get();
        
        messagesSnapshot.docs.forEach(doc => {
            batch.update(doc.ref, { isRead: true });
        });
        
        await batch.commit();
        res.status(200).json({ 
            message: `Marcados ${messagesSnapshot.size} mensajes como leídos.`,
            count: messagesSnapshot.size
        });

    } catch (error) {
        console.error('Error marcando mensajes como leídos:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});


router.delete('/:chatId/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const userId = req.firebaseUser.uid;

        const chatParts = chatId.split('_');
        if (!chatParts.includes(userId)) {
            return res.status(403).json({ error: 'Acceso denegado.' });
        }

        const messagesRef = db.collection('chats').doc(chatId).collection('messages');
        const snapshot = await messagesRef.get();

        const batch = db.batch();
        snapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        
        await batch.commit();
         
        res.status(200).json({ 
            message: 'Mensajes eliminados',
            count: snapshot.size 
        });

    } catch (error) {
        console.error('Error eliminando mensajes:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

export default router;