// backend/routes/chatRoutes.js
// ✅ VERSIÓN CORREGIDA - RECÍPROCA Y DOCUMENTO PRINCIPAL ACTUALIZADO

import express from 'express'; 
import { db } from '../firebase-admin.js'; 
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { FieldValue } from 'firebase-admin/firestore';

const router = express.Router();

// ==================== ENVIAR MENSAJE (CORREGIDO) ====================
router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId, senderId, receiverId, content, senderContent, isE2EE, plainTextForSender } = req.body;
        
        if (req.firebaseUser.uid !== senderId) {
            return res.status(403).json({ 
                error: 'ID de remitente no coincide con el usuario autenticado.' 
            });
        }

        // ✅ Log para debug
        console.log('📥 Mensaje recibido en backend:');
        console.log('   - chatId:', chatId);
        console.log('   - senderId:', senderId);
        console.log('   - receiverId:', receiverId);
        console.log('   - plainTextForSender:', plainTextForSender); // ✅ Debe aparecer aquí
        console.log('   - isE2EE:', isE2EE);

        if (isE2EE) {
            try {
                const receiverPayload = JSON.parse(content);
                const senderPayload = JSON.parse(senderContent);
                
                if (!receiverPayload.encryptedMessage || !senderPayload.encryptedMessage) {
                    console.error('❌ Contenido no cifrado correctamente');
                    return res.status(400).json({ 
                        error: 'Los mensajes E2EE deben estar cifrados' 
                    });
                }
                
                console.log('✅ Mensajes validados como E2EE');
                
            } catch (parseError) {
                console.error('❌ Error validando cifrado:', parseError);
                return res.status(400).json({ 
                    error: 'Formato de cifrado inválido' 
                });
            }
        }

        const chatDocRef = db.collection('chats').doc(chatId);
        const messageRef = chatDocRef.collection('messages');

        const messageData = {
            senderId,
            receiverId,
            content: content,
            senderContent: senderContent,
            isRead: false,
            isE2EE: isE2EE || false,
            timestamp: FieldValue.serverTimestamp(), 
        };

        await messageRef.add(messageData);
        
        console.log('✅ Mensaje guardado en subcolección');

        // ✅ CRÍTICO: Actualizar documento principal con texto plano
        const chatUpdateData = {
            participants: [senderId, receiverId].sort(),
            lastMessage: plainTextForSender || '[Sin contenido]', // ✅ Texto plano
            lastTimestamp: FieldValue.serverTimestamp(),
            lastSenderId: senderId,
            isE2EE: isE2EE || false,
        };
        
        console.log('📝 Actualizando documento principal con lastMessage:', plainTextForSender);
        
        const chatDocSnapshot = await chatDocRef.get();
        if (!chatDocSnapshot.exists) {
            chatUpdateData.patientId = senderId;
            chatUpdateData.psychologistId = receiverId;
        }

        await chatDocRef.set(chatUpdateData, { merge: true }); 
        
        console.log('✅ Documento principal actualizado correctamente');

        res.status(201).json({ 
            message: 'Mensaje E2EE enviado correctamente', 
            chatId: chatId,
        });

    } catch (error) {
        console.error('❌ Error sending message:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});


// ==================== OBTENER MENSAJES ====================
// El resto de tus rutas (obtener, limpiar) no necesitan modificación.
router.get('/:chatId/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const userId = req.firebaseUser.uid;

        const chatParts = chatId.split('_');
        if (!chatParts.includes(userId)) {
            return res.status(403).json({ error: 'Acceso denegado.' });
        }

        const messagesRef = db.collection('chats').doc(chatId).collection('messages');
        const snapshot = await messagesRef.orderBy('timestamp', 'desc').limit(50).get();

        const messages = snapshot.docs.map(doc => {
            const data = doc.data();
            
            return {
                id: doc.id,
                senderId: data.senderId,
                receiverId: data.receiverId,
                content: data.content, // Cifrado para receiverId
                senderContent: data.senderContent, // Para senderId
                isRead: data.isRead || false, 
                isE2EE: data.isE2EE || false,
                timestamp: data.timestamp?.toDate() || new Date(),
            };
        });

        res.status(200).json(messages.reverse());
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
router.post('/:chatId/mark-read', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const { userId } = req.body; 

        // 1. Verificación de seguridad: Asegura que el usuario sea el dueño de la petición
        if (req.firebaseUser.uid !== userId) {
            return res.status(403).json({ 
                error: 'ID de usuario no coincide con el token autenticado.' 
            });
        }

        // 2. Referencia a la subcolección de mensajes
        const messagesRef = db.collection('chats').doc(chatId).collection('messages');

        // 3. Obtener mensajes no leídos dirigidos a este usuario
        const messagesSnapshot = await messagesRef
            .where('receiverId', '==', userId)
            .where('isRead', '==', false)
            .get();

        if (messagesSnapshot.empty) {
            // No hay mensajes, pero la llamada fue exitosa (200)
            return res.status(200).json({ message: 'No hay mensajes no leídos para marcar.' });
        }

        // 4. Actualizar todos los mensajes a leídos usando un batch
        const batch = db.batch();
        messagesSnapshot.docs.forEach(doc => {
            batch.update(doc.ref, { 'isRead': true });
        });
        
        await batch.commit();

        res.status(200).json({ 
            message: `Marcados ${messagesSnapshot.size} mensajes como leídos.`,
            count: messagesSnapshot.size
        });

    } catch (error) {
        console.error('❌ Error marcando mensajes como leídos:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

export default router;