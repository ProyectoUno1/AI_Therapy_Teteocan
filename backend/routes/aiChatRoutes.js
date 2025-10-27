// backend/routes/aiChatRoutes.js - ACTUALIZADO PARA E2EE

import express from 'express';
const router = express.Router();
import { processUserMessageE2EE, loadChatMessages, validateMessageLimit } from '../routes/services/chatService.js';
import { getOrCreateAIChatId } from '../routes/services/chatService.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';

// --- Ruta para ENVIAR un mensaje al chat de IA con E2EE ---
router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId, senderId, receiverId, content, isE2EE } = req.body;
        
        if (req.firebaseUser.uid !== senderId) {
            return res.status(403).json({ 
                error: 'ID de remitente no coincide con el usuario autenticado.' 
            });
        }

        // ✅ Guardar el mensaje TAL CUAL viene (ya cifrado si es E2EE)
        const messageRef = db.collection('chats').doc(chatId).collection('messages');
        await messageRef.add({
            senderId,
            receiverId,
            content: content, // ✅ NO reencriptar
            isRead: false,
            isE2EE: isE2EE || false, // ✅ Marcar si es E2EE
            timestamp: FieldValue.serverTimestamp(), 
        });

        // Crear notificación (con preview genérico si es E2EE)
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
                        senderName = profDoc.exists 
                            ? profDoc.data().fullName 
                            : psychologistDoc.data().username || 'Psicólogo';
                    }
                }

                // ✅ Preview genérico para mensajes E2EE
                const notificationBody = isE2EE 
                    ? `${senderName} te envió un mensaje` 
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

            } catch (notificationError) {
                console.error('Error creando notificación:', notificationError);
            }
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


// --- Ruta para OBTENER el historial de mensajes (pueden estar cifrados) ---
router.get('/:chatId/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const userId = req.firebaseUser.uid;

        // Verificar que el usuario sea parte del chat
        const [userId1, userId2] = chatId.split('_').sort();
        if (userId !== userId1 && userId !== userId2) {
            return res.status(403).json({ error: 'Acceso denegado a este chat.' });
        }

        const messagesRef = db.collection('chats').doc(chatId).collection('messages');
        const querySnapshot = await messagesRef.orderBy('timestamp').get();

        // ✅ Devolver mensajes SIN desencriptar (cliente los desencripta)
        const messages = querySnapshot.docs.map(doc => {
            const data = doc.data();
            
            return {
                id: doc.id,
                content: data.content, // ✅ Devolver tal cual (cifrado o plano)
                senderId: data.senderId,
                receiverId: data.receiverId,
                isRead: data.isRead || false,
                isE2EE: data.isE2EE || false, // ✅ Indicar si es E2EE
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