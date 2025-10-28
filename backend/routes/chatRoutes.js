// backend/routes/chatRoutes.js

import express from 'express'; 
import { db } from '../firebase-admin.js'; 
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js'; // Asumiendo este módulo existe
import { FieldValue } from 'firebase-admin/firestore';
import { createNotification } from './notifications.js'; // Asumiendo este módulo existe
import { encrypt, decrypt } from '../utils/encryptionUtils.js';

const router = express.Router();

// backend/routes/chatRoutes.js

router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId, senderId, receiverId, content, isE2EE } = req.body;
        
        if (req.firebaseUser.uid !== senderId) {
            return res.status(403).json({ 
                error: 'ID de remitente no coincide con el usuario autenticado.' 
            });
        }

        console.log('📨 Recibiendo mensaje');
        console.log('🔐 Es E2EE:', isE2EE);
        console.log('📝 Content (primeros 100 chars):', content.substring(0, 100));

        // ✅ NO REENCRIPTAR - Guardar tal cual viene
        const contentToStore = content; // Ya viene cifrado si isE2EE = true

        // Guardar el mensaje TAL CUAL
        const messageRef = db.collection('chats').doc(chatId).collection('messages');
        await messageRef.add({
            senderId,
            receiverId,
            content: contentToStore, // ✅ Sin modificar
            isRead: false,
            isE2EE: isE2EE || false, // ✅ Marcar si es E2EE
            timestamp: FieldValue.serverTimestamp(), 
        });

        console.log('✅ Mensaje guardado correctamente');

        // Crear notificación (con preview genérico para E2EE)
        if (receiverId !== 'aurora' && receiverId !== senderId) {
            try {
                let senderName = 'Usuario';
                
                const patientDoc = await db.collection('patients').doc(senderId).get();
                if (patientDoc.exists) {
                    senderName = patientDoc.data().username || 'Paciente';
                } else {
                    const psychologistDoc = await db.collection('psychologists').doc(senderId).get();
                    if (psychologistDoc.exists) {
                        senderName = psychologistDoc.data().fullName || 
                                     psychologistDoc.data().username || 'Psicólogo';
                    }
                }

                // ✅ Preview genérico para mensajes E2EE
                const notificationBody = isE2EE 
                    ? `${senderName} te envió un mensaje cifrado` 
                    : `${senderName}: ${content.substring(0, 50)}${content.length > 50 ? '...' : ''}`;

                await db.collection('notifications').doc().set({
                    userId: receiverId,
                    title: 'Nuevo mensaje',
                    body: notificationBody,
                    type: 'chat_message',
                    isRead: false,
                    timestamp: FieldValue.serverTimestamp(),
                    data: {
                        chatId: chatId,
                        senderId: senderId,
                        senderName: senderName,
                        messagePreview: isE2EE ? '[Mensaje cifrado]' : content.substring(0, 100),
                        timestamp: new Date().toISOString()
                    }
                });

                console.log('✅ Notificación creada');
            } catch (notificationError) {
                console.error('Error creando notificación:', notificationError);
            }
        }

        res.status(200).json({ 
            message: 'Mensaje enviado correctamente',
            notificationCreated: (receiverId !== 'aurora' && receiverId !== senderId)
        });

    } catch (error) {
        console.error('❌ Error sending message:', error);
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
            
            // 🟢 Desencriptar directamente. El manejo de errores está en encryptionUtils.js
            const decryptedContent = decrypt(data.content);
            
            return {
                id: doc.id,
                content: decryptedContent,
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