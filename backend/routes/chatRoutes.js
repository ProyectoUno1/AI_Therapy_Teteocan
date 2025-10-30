// backend/routes/chatRoutes.js
// ✅ VERSIÓN CORREGIDA - NO DESCIFRA EN BACKEND (E2EE)

import express from 'express'; 
import { db } from '../firebase-admin.js'; 
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { FieldValue } from 'firebase-admin/firestore';

const router = express.Router();

// ==================== ENVIAR MENSAJE ====================
router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId, senderId, receiverId, content, isE2EE, plainTextForSender } = req.body;
        
        if (req.firebaseUser.uid !== senderId) {
            return res.status(403).json({ 
                error: 'ID de remitente no coincide con el usuario autenticado.' 
            });
        }

        // ✅ Guardar contenido cifrado + texto plano para el remitente
        const messageData = {
            senderId,
            receiverId,
            content: content, // Cifrado para el destinatario
            plainTextForSender: plainTextForSender || null, // ✅ Texto plano para el remitente
            isRead: false,
            isE2EE: isE2EE || false,
            timestamp: FieldValue.serverTimestamp(), 
        };

        // Guardar el mensaje 
        const messageRef = db.collection('chats').doc(chatId).collection('messages');
        await messageRef.add(messageData);

        // Crear notificación 
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

                const notificationBody = isE2EE 
                    ? `${senderName} te envió un mensaje cifrado` 
                    : `${senderName}: ${plainTextForSender?.substring(0, 50) || content.substring(0, 50)}`;

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
                        messagePreview: isE2EE ? '[Mensaje cifrado]' : plainTextForSender?.substring(0, 100) || content.substring(0, 100),
                        timestamp: new Date().toISOString()
                    }
                });

            } catch (notificationError) {
                console.error('❌ Error creando notificación:', notificationError);
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

// ==================== MARCAR COMO LEÍDO ====================
router.post('/:chatId/mark-read', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const { userId } = req.body;
        
        if (req.firebaseUser.uid !== userId) {
            return res.status(403).json({ error: 'No autorizado' });
        }

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
        
        console.log(`✅ ${unreadMessages.size} mensajes marcados como leídos en chat ${chatId}`);
        
        res.status(200).json({ 
            message: 'Mensajes marcados como leídos',
            count: unreadMessages.size 
        });

    } catch (error) {
        console.error('❌ Error marking messages as read:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ==================== OBTENER MENSAJES ====================
// ✅ CORRECCIÓN CRÍTICA: NO DESCIFRAR EN BACKEND + Retornar plainTextForSender
router.get('/:chatId/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const userId = req.firebaseUser.uid;

        console.log(`🔥 Cargando mensajes para chat: ${chatId}, usuario: ${userId}`);

        // Verificar que el usuario tiene acceso a este chat
        const chatParts = chatId.split('_');
        if (!chatParts.includes(userId)) {
            console.warn(`⚠️ Usuario ${userId} intentó acceder a chat ${chatId} sin permiso`);
            return res.status(403).json({ error: 'Acceso denegado a este chat.' });
        }

        const messagesRef = db.collection('chats').doc(chatId).collection('messages');
        const querySnapshot = await messagesRef.orderBy('timestamp', 'asc').get();

        console.log(`✅ ${querySnapshot.size} mensajes encontrados en chat ${chatId}`);

        // ✅ NO DESCIFRAR - Retornar contenido RAW con plainTextForSender
        const messages = querySnapshot.docs.map(doc => {
            const data = doc.data();
            
            return {
                id: doc.id,
                content: data.content, // ← Cifrado
                plainTextForSender: data.plainTextForSender || null, // ✅ Texto plano
                senderId: data.senderId,
                receiverId: data.receiverId,
                isRead: data.isRead || false, 
                isE2EE: data.isE2EE || false,
                timestamp: data.timestamp?.toDate() || new Date(),
            };
        });

        console.log(`📦 Enviando ${messages.length} mensajes al cliente`);
        
        res.status(200).json(messages);
    } catch (error) {
        console.error('❌ Error fetching chat messages:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ==================== LIMPIAR CHATS (OPCIONAL) ====================
router.delete('/:chatId/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const userId = req.firebaseUser.uid;

        // Verificar acceso
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
        console.error('❌ Error deleting messages:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

export default router;