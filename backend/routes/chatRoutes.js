// backend/routes/chatRoutes.js
// ✅ VERSIÓN CORREGIDA FINAL: Guarda texto plano en 'lastMessage'

import express from 'express'; 
import { db } from '../firebase-admin.js'; 
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { FieldValue } from 'firebase-admin/firestore';
import { encrypt, decrypt } from '../utils/encryptionUtils.js';

const router = express.Router();

// ==================== ENVIAR MENSAJE (CORREGIDO: LISTA DE CHATS) ====================
router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        // 'content' viene como texto plano desde el cliente
        const { chatId, senderId, receiverId, content, isEncrypted } = req.body;
        
        if (req.firebaseUser.uid !== senderId) {
            return res.status(403).json({ 
                error: 'ID de remitente no coincide con el usuario autenticado.' 
            });
        }

        console.log('📥 Mensaje recibido en backend:');
        console.log('   - chatId:', chatId);
        console.log('   - senderId:', senderId);
        console.log('   - content:', content.substring(0, 30) + '...');
        
        // 1. Cifrar el contenido para el historial
        const encryptedContent = encrypt(content); 

        const chatDocRef = db.collection('chats').doc(chatId);
        const messageRef = chatDocRef.collection('messages');

        // 2. Guardar el mensaje CIFRADO en la subcolección (historial seguro)
        const messageData = {
            senderId,
            receiverId,
            content: encryptedContent, // <-- CIFRADO
            timestamp: FieldValue.serverTimestamp(),
            isRead: false,
        };
        await messageRef.add(messageData);

        // 3. ACTUALIZAR el documento principal con la versión PLANA para la lista de chats
        await chatDocRef.set({
            lastMessage: content, // ✅ CORRECCIÓN: Guardar la versión PLANA para el listado
            lastMessageTime: FieldValue.serverTimestamp(),
            lastSenderId: senderId,
            unreadCount: FieldValue.increment(1),
        }, { merge: true });

        res.status(200).json({ message: 'Mensaje enviado correctamente' });

    } catch (error) {
        console.error('❌ Error enviando mensaje:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ==================== OBTENER MENSAJES ====================
router.get('/:chatId/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;

        const messagesRef = db.collection('chats').doc(chatId).collection('messages');
        const snapshot = await messagesRef.orderBy('timestamp', 'asc').get();

        const messages = snapshot.docs.map(doc => {
            const data = doc.data();
            
            let decryptedContent = data.content;
            
            // Desencriptar solo si no es un mensaje de sistema
            if (data.senderId !== 'system') {
                decryptedContent = decrypt(data.content);
            }

            return {
                id: doc.id,
                senderId: data.senderId,
                receiverId: data.receiverId,
                content: decryptedContent, // Devuelve contenido plano al cliente
                timestamp: data.timestamp ? data.timestamp.toDate() : new Date(),
                isRead: data.isRead || false,
                isE2EE: data.isE2EE || false,
            };
        });

        res.status(200).json(messages);

    } catch (error) {
        console.error('❌ Error cargando mensajes:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ==================== MARCAR COMO LEÍDO ====================
router.post('/:chatId/mark-read', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const { userId } = req.body; 

        if (req.firebaseUser.uid !== userId) {
             return res.status(403).json({ error: 'Acceso denegado.' });
        }

        const chatDocRef = db.collection('chats').doc(chatId);
        const messagesRef = chatDocRef.collection('messages');

        // Marcar mensajes no leídos dirigidos a este usuario
        const messagesSnapshot = await messagesRef
            .where('receiverId', '==', userId)
            .where('isRead', '==', false)
            .get();

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