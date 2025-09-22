// backend/routes/fcm.js
import express from 'express';
import admin from 'firebase-admin';
import { db } from '../firebase-admin.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';

const router = express.Router();

router.use(verifyFirebaseToken);

// Endpoint para actualizar el token FCM del usuario
router.patch('/fcm-token', async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;
        const { fcmToken } = req.body;

        if (!fcmToken) {
            return res.status(400).json({ error: 'Faltan campos requeridos: fcmToken' });
        }

        // Determinar el tipo de usuario (paciente o psicólogo) y actualizar el token
        const userRef = db.collection('patients').doc(userId);
        const userDoc = await userRef.get();

        if (userDoc.exists) {
            await userRef.update({ fcmToken });
            return res.status(200).json({ success: true, message: 'Token FCM de paciente actualizado correctamente' });
        }

        const psychologistRef = db.collection('psychologists').doc(userId);
        const psychologistDoc = await psychologistRef.get();

        if (psychologistDoc.exists) {
            await psychologistRef.update({ fcmToken });
            return res.status(200).json({ success: true, message: 'Token FCM de psicólogo actualizado correctamente' });
        }

        return res.status(404).json({ error: 'Usuario no encontrado' });

    } catch (error) {
        console.error('Error al actualizar el token FCM:', error);
        res.status(500).json({
            error: 'Error al actualizar el token FCM',
            details: error.message
        });
    }
});

export default router;