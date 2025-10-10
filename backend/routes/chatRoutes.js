// backend/routes/chatRoutes.js

import express from 'express'; 
import { db } from '../firebase-admin.js'; 
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { FieldValue } from 'firebase-admin/firestore';
import { createNotification } from './notifications.js';

const router = express.Router();

router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId, senderId, receiverId, content } = req.body;
        if (req.firebaseUser.uid !== senderId) {
            return res.status(403).json({ error: 'ID de remitente no coincide con el usuario autenticado.' });
        }

        // Guardar el mensaje
        const messageRef = db.collection('chats').doc(chatId).collection('messages');
        await messageRef.add({
            senderId,
            receiverId,
            content,
            isRead: false, 
            timestamp: FieldValue.serverTimestamp(), 
        });

        if (receiverId !== 'aurora' && receiverId !== senderId) {
            try {
                let senderName = 'Usuario';
                
                const patientDoc = await db.collection('patients').doc(senderId).get();
                if (patientDoc.exists) {
                    senderName = patientDoc.data().username || 'Paciente';
                } else {
                    const psychologistDoc = await db.collection('psychologists').doc(senderId).get();
                    if (psychologistDoc.exists) {
                        const profDoc = await db.collection('psychologists').doc(senderId).get();
                        senderName = profDoc.exists ? profDoc.data().fullName : psychologistDoc.data().username || 'Psicólogo';
                    }
                }

                // CREAR NOTIFICACIÓN DIRECTAMENTE EN FIRESTORE 
                const notificationRef = db.collection('notifications').doc();
                await notificationRef.set({
                    userId: receiverId,
                    title: 'Nuevo mensaje',
                    body: `${senderName}: ${content.length > 50 ? content.substring(0, 50) + '...' : content}`,
                    type: 'chat_message',
                    isRead: false,
                    timestamp: FieldValue.serverTimestamp(),
                    data: {
                        chatId: chatId,
                        senderId: senderId,
                        senderName: senderName,
                        messagePreview: content,
                        timestamp: new Date().toISOString()
                    }
                });

            } catch (notificationError) {
                console.error('Error creando notificación:', notificationError);
            }
        } else {
            console.log('ℹNo se crea notificación (chat con IA o mensaje)');
        }

        res.status(200).json({ 
            message: 'Mensaje enviado correctamente',
            notificationCreated: (receiverId !== 'aurora' && receiverId !== senderId)
        });

    } catch (error) {
        console.error('Error sending message:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});


router.post('/:chatId/mark-read', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const { userId } = req.body;
        
        if (req.firebaseUser.uid !== userId) {
            return res.status(403).json({ error: 'No autorizado' });
        }

        // Actualizar todos los mensajes no leídos
        const messagesRef = db.collection('chats').doc(chatId).collection('messages');
        const unreadMessages = await messagesRef
            .where('receiverId', '==', userId)
            .where('isRead', '==', false)
            .get();

        const batch = db.batch();
        unreadMessages.docs.forEach(doc => {
            batch.update(doc.ref, { isRead: true });
        });
        
        await batch.commit();
        res.status(200).json({ 
            message: 'Mensajes marcados como leídos',
            count: unreadMessages.size 
        });

    } catch (error) {
        console.error('Error marking messages as read:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

router.get('/:chatId/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const userId = req.firebaseUser.uid;

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
                isRead: data.isRead || false, 
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