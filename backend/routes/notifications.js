// backend/routes/notifications.js

import express from 'express';
import { db } from '../firebase-admin.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import admin from 'firebase-admin';

const router = express.Router();
router.use(verifyFirebaseToken);


//  Obtener notificaciones para el usuario autenticado

router.get('/', async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;

        const notificationsRef = db.collection('notifications');
        const querySnapshot = await notificationsRef
            .where('userId', '==', userId)
            .orderBy('timestamp', 'desc')
            .get();

        const notifications = querySnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                ...data,
                timestamp: data.timestamp.toDate().toISOString(),
            };
        });

        res.status(200).json(notifications);

    } catch (error) {
        console.error('Error al obtener notificaciones:', error);
        res.status(500).json({ 
            error: 'Error al obtener notificaciones', 
            details: error.message 
        });
    }
});


// Marcar una notificación como leída

router.patch('/:notificationId/read', async (req, res) => {
    try {
        const { notificationId } = req.params;
        const userId = req.firebaseUser.uid;

        // Verificar que la notificación existe
        const notificationRef = db.collection('notifications').doc(notificationId);
        const notificationDoc = await notificationRef.get();

        if (!notificationDoc.exists) {
            return res.status(404).json({ 
                error: 'Notificación no encontrada' 
            });
        }

        // Verificar que la notificación pertenece al usuario
        const notificationData = notificationDoc.data();
        if (notificationData.userId !== userId) {
            return res.status(403).json({ 
                error: 'No tienes permiso para modificar esta notificación' 
            });
        }

        // Actualizar el campo isRead
        await notificationRef.update({
            isRead: true,
            readAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Obtener el documento actualizado
        const updatedDoc = await notificationRef.get();
        const updatedData = updatedDoc.data();

        res.status(200).json({
            success: true,
            message: 'Notificación marcada como leída',
            notification: {
                id: updatedDoc.id,
                ...updatedData,
                timestamp: updatedData.timestamp.toDate().toISOString(),
                readAt: updatedData.readAt ? updatedData.readAt.toDate().toISOString() : null
            }
        });

    } catch (error) {
        console.error('Error al marcar notificación como leída:', error);
        res.status(500).json({ 
            error: 'Error al marcar la notificación como leída', 
            details: error.message 
        });
    }
});

//  Crear una nueva notificación (para uso interno/admin)

router.post('/', async (req, res) => {
    try {
        const { 
            userId, 
            title, 
            body, 
            type = 'general',
            data = {} 
        } = req.body;

        // Validaciones
        if (!userId || !title || !body) {
            return res.status(400).json({ 
                error: 'Faltan campos requeridos: userId, title, body' 
            });
        }

        // Crear la notificación
        const notification = {
            userId,
            title,
            body,
            type,
            data,
            isRead: false,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        };

        const docRef = await db.collection('notifications').add(notification);
        
        // Obtener el documento creado
        const createdDoc = await docRef.get();
        const createdData = createdDoc.data();

        res.status(201).json({
            success: true,
            message: 'Notificación creada correctamente',
            notification: {
                id: createdDoc.id,
                ...createdData,
                timestamp: createdData.timestamp.toDate().toISOString(),
                createdAt: createdData.createdAt.toDate().toISOString()
            }
        });

    } catch (error) {
        console.error('Error al crear notificación:', error);
        res.status(500).json({ 
            error: 'Error al crear la notificación', 
            details: error.message 
        });
    }
});


//  Marcar todas las notificaciones como leídas

router.patch('/read-all', async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;

        // Obtener todas las notificaciones no leídas del usuario
        const notificationsRef = db.collection('notifications');
        const querySnapshot = await notificationsRef
            .where('userId', '==', userId)
            .where('isRead', '==', false)
            .get();

        // Usar batch para actualizar múltiples documentos
        const batch = db.batch();
        let updateCount = 0;

        querySnapshot.docs.forEach(doc => {
            batch.update(doc.ref, {
                isRead: true,
                readAt: admin.firestore.FieldValue.serverTimestamp()
            });
            updateCount++;
        });

        // Ejecutar el batch
        if (updateCount > 0) {
            await batch.commit();
        }

        res.status(200).json({
            success: true,
            message: `${updateCount} notificaciones marcadas como leídas`,
            updatedCount: updateCount
        });

    } catch (error) {
        console.error('Error al marcar todas las notificaciones como leídas:', error);
        res.status(500).json({ 
            error: 'Error al marcar todas las notificaciones como leídas', 
            details: error.message 
        });
    }
});


// Obtener el conteo de notificaciones no leídas

router.get('/unread-count', async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;

        const notificationsRef = db.collection('notifications');
        const querySnapshot = await notificationsRef
            .where('userId', '==', userId)
            .where('isRead', '==', false)
            .get();

        const unreadCount = querySnapshot.size;

        res.status(200).json({
            success: true,
            unreadCount
        });

    } catch (error) {
        console.error('Error al obtener conteo de notificaciones no leídas:', error);
        res.status(500).json({ 
            error: 'Error al obtener el conteo', 
            details: error.message 
        });
    }
});

//  Eliminar todas las notificaciones leídas (limpieza)

router.delete('/clear-read', async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;

        // Obtener todas las notificaciones leídas del usuario
        const notificationsRef = db.collection('notifications');
        const querySnapshot = await notificationsRef
            .where('userId', '==', userId)
            .where('isRead', '==', true)
            .get();

        // Usar batch para eliminar múltiples documentos
        const batch = db.batch();
        let deleteCount = 0;

        querySnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
            deleteCount++;
        });

        // Ejecutar el batch
        if (deleteCount > 0) {
            await batch.commit();
        }

        res.status(200).json({
            success: true,
            message: `${deleteCount} notificaciones eliminadas`,
            deletedCount: deleteCount
        });

    } catch (error) {
        console.error('Error al eliminar notificaciones leídas:', error);
        res.status(500).json({ 
            error: 'Error al eliminar notificaciones', 
            details: error.message 
        });
    }
});


export const createNotification = async (notificationData) => {
    try {
        // 1. Crear en Firestore
        const notification = {
            userId: notificationData.userId,
            title: notificationData.title,
            body: notificationData.body,
            type: notificationData.type || 'general',
            data: notificationData.data || {},
            isRead: false,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        };

        const docRef = await db.collection('notifications').add(notification);

        // 2. Enviar push notification
        await sendPushNotification(notificationData, docRef.id);
        
        return { success: true, id: docRef.id };
    } catch (error) {
        console.error('Error al crear notificación:', error);
        return { success: false, error: error.message };
    }
};

async function sendPushNotification(notificationData, notificationId) {
    try {
        // Obtener token FCM del usuario
        const userDoc = await db.collection('patients').doc(notificationData.userId).get();
        const fcmToken = userDoc.data()?.fcmToken;

        if (!fcmToken) {
            console.log('Usuario sin token FCM:', notificationData.userId);
            return;
        }

        const message = {
            token: fcmToken,
            notification: {
                title: notificationData.title,
                body: notificationData.body,
            },
            data: {
                notificationId: notificationId,
                type: notificationData.type,
                ...Object.fromEntries(
                    Object.entries(notificationData.data || {}).map(([k, v]) => [k, String(v)])
                )
            },
            android: {
                notification: {
                    channelId: getChannelForType(notificationData.type),
                    priority: 'high',
                    defaultSound: true,
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                    }
                }
            }
        };

        await admin.messaging().send(message);
        console.log('Push notification enviada:', notificationId);
    } catch (error) {
        console.error('Error enviando push notification:', error);
    }
}

function getChannelForType(type) {
    switch (type) {
        case 'appointment_created':
        case 'appointment_confirmed':
        case 'appointment_cancelled':
            return 'appointment_notifications';
        case 'subscription_activated':
        case 'payment_succeeded':
            return 'subscription_notifications';
        case 'session_started':
        case 'session_completed':
            return 'session_notifications';
        default:
            return 'general_notifications';
    }
}

export default router;