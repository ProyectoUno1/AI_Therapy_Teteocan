// backend/routes/chatRoutes.js
// ✅ CÓDIGO CORREGIDO: SIN ENCRIPTACIÓN

import express from 'express'; 
import { db } from '../firebase-admin.js'; 
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { FieldValue } from 'firebase-admin/firestore';
// ❌ ELIMINADA LÍNEA: import { encrypt, decrypt } from '../utils/encryptionUtils.js';

const router = express.Router();

// ==================== ENVIAR MENSAJE ====================
router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId, senderId, receiverId, content } = req.body;
        
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
            // 🔴 CORRECCIÓN: Guardar el contenido en texto plano
            content: content, 
            timestamp: FieldValue.serverTimestamp(),
            isRead: false,
        };
        
        await messageRef.add(messageData);

        await chatDocRef.set({
            lastMessage: content,
            lastMessageTime: FieldValue.serverTimestamp(),
            lastMessageSenderId: senderId,
        }, { merge: true });

        res.status(200).json({ message: 'Mensaje enviado', content: content });

    } catch (error) {
        console.error('❌ Error enviando mensaje:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ==================== MARCAR MENSAJES COMO LEÍDOS ====================
router.put('/:chatId/read/:readerId', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId, readerId } = req.params;

        if (req.firebaseUser.uid !== readerId) {
            return res.status(403).json({ error: 'Acceso denegado.' });
        }

        const batch = db.batch();
        const messagesSnapshot = await db.collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('receiverId', '==', readerId)
            .where('isRead', '==', false)
            .get();
        
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