// backend/routes/psychologists.js

import express from 'express'; 
const router = express.Router();
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { admin, db } from '../firebase-admin.js';

router.post('/register', verifyFirebaseToken, async (req, res) => {
    try {
        const { uid, username, email, phoneNumber, professionalLicense, dateOfBirth, profilePictureUrl } = req.body;
        const firebaseUser = req.firebaseUser; 

        if (!firebaseUser || firebaseUser.uid !== uid) { 
            return res.status(403).json({ error: 'UID mismatch or no authenticated user' });
        }

        const psychologistRef = db.collection('psychologists').doc(uid);
        const doc = await psychologistRef.get();

        if (doc.exists) {
            return res.status(400).json({ error: 'Psicólogo ya registrado' });
        }

        // Se corrigieron los nombres de los campos para usar camelCase,
        // lo que coincide con el modelo de Flutter
        const psychologistData = {
            firebaseUid: uid, // Corrección: de firebase_uid a firebaseUid
            username: username,
            email: email,
            phoneNumber: phoneNumber, // Corrección: de phone_number a phoneNumber
            professionalLicense: professionalLicense, // Corrección: de professional_license a professionalLicense
            dateOfBirth: dateOfBirth, // Corrección: de date_of_birth a dateOfBirth
            profilePictureUrl: profilePictureUrl || null, // Corrección: de profile_picture_url a profilePictureUrl
            createdAt: admin.firestore.FieldValue.serverTimestamp(), // Corrección: de created_at a createdAt
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
        console.log('ID del usuario autenticado (del token):', req.firebaseUser.uid);
        console.log('ID recibido en la URL (del frontend):', uid);
        console.log('¿Coinciden los IDs?', req.firebaseUser.uid === uid);
        // Validación para asegurar que el usuario autenticado solo pueda actualizar su propio perfil
        if (req.firebaseUser.uid !== uid) {
            return res.status(403).json({ error: 'Acceso no autorizado.' });
        }

        const { username, email, phoneNumber, profilePictureUrl } = req.body;

        const updateData = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
        if (username) updateData.username = username;
        if (email) updateData.email = email;
        if (phoneNumber) updateData.phoneNumber = phoneNumber;
        if (profilePictureUrl) updateData.profilePictureUrl = profilePictureUrl;

        await db.collection('psychologists').doc(uid).update(updateData);

        res.json({ message: 'Información básica actualizada' });
    } catch (error) {
        console.error('Error al actualizar información básica del psicólogo:', error);
        res.status(500).json({ error: 'Error interno del servidor', details: error.message });
    }
});

export default router;