// backend/routes/chatRoutes.js
// ✅ CÓDIGO CORREGIDO: Incluye campo participants

import express from 'express'; 
import { db } from '../firebase-admin.js'; 
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { FieldValue } from 'firebase-admin/firestore';

const router = express.Router();

// ==================== ENVIAR MENSAJE ====================
router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId, senderId, receiverId, content } = req.body;
        
        console.log('📨 Enviando mensaje:', { 
            chatId, 
            senderId, 
            receiverId, 
            contentLength: content?.length 
        });
        
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

        // 1. Guardar el mensaje en la subcolección
        const messageData = {
            senderId,
            receiverId,
            content: content, // ✅ TEXTO PLANO
            timestamp: FieldValue.serverTimestamp(),
            isRead: false,
        };
        
        const newMessageDoc = await messageRef.add(messageData);
        console.log('✅ Mensaje guardado en subcolección:', newMessageDoc.id);

        // 2. ✅ CRÍTICO: Actualizar documento principal con participants
        await chatDocRef.set({
            lastMessage: content,
            lastMessageTime: FieldValue.serverTimestamp(),
            lastMessageSenderId: senderId,
            participants: [senderId, receiverId], // ✅ CAMPO CRÍTICO
            updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        
        console.log('✅ Documento principal actualizado con participants');

        res.status(200).json({ 
            message: 'Mensaje enviado exitosamente', 
            content: content,
            messageId: newMessageDoc.id
        });

    } catch (error) {
        console.error('❌ Error enviando mensaje:', error);
        res.status(500).json({ 
            error: 'Error interno del servidor', 
            details: error.message 
        });
    }
});

// ==================== OBTENER MENSAJES DE UN CHAT ====================
router.get('/:chatId/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const userId = req.firebaseUser.uid;

        console.log('📥 Cargando mensajes del chat:', chatId);

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
                content: data.content, // ✅ Texto plano
                timestamp: data.timestamp ? data.timestamp.toDate().toISOString() : null,
                isRead: data.isRead || false,
            };
        });

        console.log(`✅ ${messages.length} mensajes cargados`);
        res.status(200).json(messages);

    } catch (error) {
        console.error('❌ Error cargando mensajes:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ==================== MARCAR MENSAJES COMO LEÍDOS ====================
router.post('/:chatId/mark-read', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const { userId } = req.body;

        console.log('📖 Marcando mensajes como leídos:', { chatId, userId });

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

        console.log(`✅ ${messagesSnapshot.size} mensajes marcados como leídos`);

        res.status(200).json({ 
            message: `Marcados ${messagesSnapshot.size} mensajes como leídos.`,
            count: messagesSnapshot.size
        });

    } catch (error) {
        console.error('❌ Error marcando mensajes como leídos:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ==================== LIMPIAR CHATS ====================
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
        
        console.log(`✅ ${snapshot.size} mensajes eliminados del chat ${chatId}`);
        
        res.status(200).json({ 
            message: 'Mensajes eliminados',
            count: snapshot.size 
        });

    } catch (error) {
        console.error('❌ Error eliminando mensajes:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

export default router;