// backend/routes/chatRoutes.js
// ✅ VERSIÓN SIMPLIFICADA - SIN E2EE, SOLO ENCRIPTACIÓN BÁSICA

import express from 'express'; 
import { db } from '../firebase-admin.js'; 
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { FieldValue } from 'firebase-admin/firestore';
import { encrypt, decrypt } from '../utils/encryptionUtils.js';

const router = express.Router();

// ==================== ENVIAR MENSAJE (SIMPLIFICADO) ====================
router.post('/messages', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId, senderId, receiverId, content, isEncrypted } = req.body;
        
        if (req.firebaseUser.uid !== senderId) {
            return res.status(403).json({ 
                error: 'ID de remitente no coincide con el usuario autenticado.' 
            });
        }

        console.log('📥 Mensaje recibido en backend:');
        console.log('   - chatId:', chatId);
        console.log('   - senderId:', senderId);
        console.log('   - receiverId:', receiverId);
        console.log('   - isEncrypted:', isEncrypted);
        console.log('   - content:', content.substring(0, 50) + '...');

        const chatDocRef = db.collection('chats').doc(chatId);
        const messageRef = chatDocRef.collection('messages');

        const messageData = {
            senderId,
            receiverId,
            content: content, // ✅ DEJAR EL CONTENIDO COMO VIENE (ya debería estar cifrado del frontend)
            isRead: false,
            isEncrypted: isEncrypted || false,
            timestamp: FieldValue.serverTimestamp(), 
        };

        await messageRef.add(messageData);
        
        console.log('✅ Mensaje guardado en subcolección');

        // ✅ Actualizar documento principal con preview (texto plano para vista rápida)
        const chatUpdateData = {
            participants: [senderId, receiverId].sort(),
            lastMessage: lastMessage, // ✅ Preview genérico para mensajes cifrados
            lastTimestamp: FieldValue.serverTimestamp(),
            lastSenderId: senderId,
            isEncrypted: isEncrypted || false,
        };
        
        const chatDocSnapshot = await chatDocRef.get();
        if (!chatDocSnapshot.exists) {
            chatUpdateData.patientId = senderId;
            chatUpdateData.psychologistId = receiverId;
        }

        await chatDocRef.set(chatUpdateData, { merge: true }); 
        
        console.log('✅ Documento principal actualizado');

        res.status(201).json({ 
            message: 'Mensaje enviado correctamente', 
            chatId: chatId,
        });

    } catch (error) {
        console.error('❌ Error sending message:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ==================== OBTENER MENSAJES (SIMPLIFICADO) ====================
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
            
            // ✅ DEVOLVER EL CONTENIDO TAL CUAL - EL FRONTEND LO DESCIFRARÁ
            return {
                id: doc.id,
                senderId: data.senderId,
                receiverId: data.receiverId,
                content: data.content, // ✅ Contenido tal cual (cifrado)
                isRead: data.isRead || false, 
                isEncrypted: data.isEncrypted || false,
                timestamp: data.timestamp?.toDate() || new Date(),
            };
        });

        res.status(200).json(messages.reverse());
    } catch (error) {
        console.error('❌ Error fetching chat messages:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ==================== MARCAR MENSAJES COMO LEÍDOS ====================
router.post('/:chatId/mark-read', verifyFirebaseToken, async (req, res) => {
    try {
        const { chatId } = req.params;
        const { userId } = req.body; 

        if (req.firebaseUser.uid !== userId) {
            return res.status(403).json({ 
                error: 'ID de usuario no coincide con el token autenticado.' 
            });
        }

        const messagesRef = db.collection('chats').doc(chatId).collection('messages');

        const messagesSnapshot = await messagesRef
            .where('receiverId', '==', userId)
            .where('isRead', '==', false)
            .get();

        if (messagesSnapshot.empty) {
            return res.status(200).json({ message: 'No hay mensajes no leídos para marcar.' });
        }

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
        console.error('Error deleting messages:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

export default router;