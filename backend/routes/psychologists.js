// backend/routes/psychologists.js

import express from 'express'; 
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { db } from '../firebase-admin.js';
import { FieldValue } from 'firebase-admin/firestore'; 

const router = express.Router();

router.post('/register', verifyFirebaseToken, async (req, res) => {
    try {
        const { uid, username, email, phoneNumber, professionalLicense, dateOfBirth, profilePictureUrl } = req.body;
        const firebaseUser = req.firebaseUser; 

        if (!firebaseUser || firebaseUser.uid !== uid) { 
            return res.status(403).json({ error: 'UID mismatch o usuario no autenticado' });
        }

        const psychologistRef = db.collection('psychologists').doc(uid);
        const doc = await psychologistRef.get();

        if (doc.exists) {
            return res.status(400).json({ error: 'Psicólogo ya registrado' });
        }

        const psychologistData = {
            firebaseUid: uid, 
            username,
            email,
            phoneNumber, 
            professionalLicense, 
            dateOfBirth,
            profilePictureUrl: profilePictureUrl || null, 
            createdAt: FieldValue.serverTimestamp(),
        };

        await psychologistRef.set(psychologistData);

        res.status(201).json({
            message: 'Psicólogo registrado exitosamente',
            psychologist: { id: uid, ...psychologistData },
        });
    } catch (error) {
        console.error('Error al registrar psicólogo en Firestore:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

router.get('/profile', verifyFirebaseToken, async (req, res) => {
    try {
        const uid = req.firebaseUser.uid; 
        const psychologistRef = db.collection('psychologists').doc(uid);
        const doc = await psychologistRef.get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'Psicólogo no encontrado' });
        }

        res.json({ psychologist: { id: doc.id, ...doc.data() } });
    } catch (error) {
        console.error('Error al obtener perfil psicólogo de Firestore:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});


router.patch('/:uid/basic', verifyFirebaseToken, async (req, res) => {
    try {
        const { uid } = req.params;

        if (req.firebaseUser.uid !== uid) {
            return res.status(403).json({ error: 'Acceso no autorizado.' });
        }

        const { username, email, phoneNumber, profilePictureUrl } = req.body;

        const updateData = { updatedAt: FieldValue.serverTimestamp() };
        if (username) updateData.username = username;
        if (email) updateData.email = email;
        if (phoneNumber) updateData.phoneNumber = phoneNumber;
        if (profilePictureUrl) updateData.profilePictureUrl = profilePictureUrl;

        await db.collection('psychologists').doc(uid).set(updateData, { merge: true });

        res.json({ message: 'Información básica actualizada' });
    } catch (error) {
        console.error('Error al actualizar información básica del psicólogo:', error);
        res.status(500).json({ error: 'Error interno del servidor', details: error.message });
    }
});

export default router;
