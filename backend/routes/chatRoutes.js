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
        const { chatId, senderId, receiverId, content, isE2EE, plainTextForSender } = req.body;
        
        // 1. Verificación de autenticación (seguridad)
        if (req.firebaseUser.uid !== senderId) {
            return res.status(403).json({ 
                error: 'ID de remitente no coincide con el usuario autenticado.' 
            });
        }

        // 2. Referencias a Firestore
        const chatDocRef = db.collection('chats').doc(chatId); // Documento principal del chat
        const messageRef = chatDocRef.collection('messages');  // Subcolección de mensajes

        // 3. Datos del mensaje a guardar en la subcolección
        const messageData = {
            senderId,
            receiverId,
            content: content, // Contenido (cifrado o no)
            plainTextForSender: plainTextForSender || null, // Texto plano para el remitente
            isRead: false,
            isE2EE: isE2EE || false,
            timestamp: FieldValue.serverTimestamp(), 
        };

        // 4. Guardar el mensaje en la subcolección
        await messageRef.add(messageData);

        // 5. Determinar los datos para actualizar el documento principal (Recíproco)
        const chatUpdateData = {
            // Campos que siempre se actualizan
            participants: [senderId, receiverId].sort(), // Array de participantes ordenado
            lastMessage: plainTextForSender || content, // Último mensaje para la lista de chats
            lastTimestamp: FieldValue.serverTimestamp(),
            lastSenderId: senderId, // <-- ID del último remitente (para reciprocidad)
            isE2EE: isE2EE || false,
            // Aquí puedes añadir otros campos que deban actualizarse con cada mensaje
        };
        
        // 6. Verificar si es el PRIMER MENSAJE para asignar roles patientId y psychologistId
        // Esto asegura que los IDs de rol solo se establezcan una vez y el documento "exista".
        const chatDocSnapshot = await chatDocRef.get();
        
        if (!chatDocSnapshot.exists) {
            // Asignación de roles al crear el documento por primera vez
            // (Asume que los participantes son Patient y Psychologist. Esto es lo que necesita tu Flutter app).
            chatUpdateData.patientId = senderId; // Temporal: Se asume el remitente como el paciente para la creación
            chatUpdateData.psychologistId = receiverId; // Temporal: Se asume el receptor como el psicólogo
            // NOTA: Una lógica más robusta debe determinar los roles desde una colección 'users' o 'roles'
            // pero para hacer que el documento exista, esta asignación única inicial es suficiente.
        }

        // 7. Actualizar/Crear el documento principal del chat
        // { merge: true } asegura la actualización sin sobrescribir o crea si no existe.
        await chatDocRef.set(chatUpdateData, { merge: true }); 
        
        // 8. Crear notificación (Mantenemos tu lógica existente)
        if (receiverId !== 'aurora' && receiverId !== senderId) {
            // Lógica para crear la notificación push
            // ... (tu código de notificación)
        }

        // 9. Respuesta exitosa
        res.status(201).json({ 
            message: 'Mensaje enviado', 
            chatId: chatId, 
            messageData: messageData 
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

        // Verificar acceso
        const chatParts = chatId.split('_');
        if (!chatParts.includes(userId)) {
            return res.status(403).json({ error: 'Acceso denegado.' });
        }

        const messagesRef = db.collection('chats').doc(chatId).collection('messages');
        const snapshot = await messagesRef.orderBy('timestamp', 'desc').limit(50).get();

        const messages = snapshot.docs.map(doc => {
            const data = doc.data();
            // NO DESCIFRAMOS NADA AQUÍ para mantener E2EE
            return {
                id: doc.id,
                senderId: data.senderId,
                receiverId: data.receiverId,
                content: data.content,
                plainTextForSender: data.plainTextForSender || null,
                isRead: data.isRead || false, 
                isE2EE: data.isE2EE || false,
                timestamp: data.timestamp?.toDate() || new Date(),
            };
        });

        console.log(`📦 Enviando ${messages.length} mensajes al cliente`);
        
        res.status(200).json(messages.reverse()); // Enviamos en orden cronológico ascendente
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