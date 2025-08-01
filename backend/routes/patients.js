// backend/routes/patients.js

import express from 'express'; 
const router = express.Router();
import verifyFirebaseToken from '../middlewares/auth_middleware.js';




router.post('/register', verifyFirebaseToken, async (req, res) => {
    try {
        console.log('Datos recibidos para registro de paciente:', req.body);
        const { uid, username, email, phoneNumber, dateOfBirth, profilePictureUrl } = req.body;
        const firebaseUser = req.firebaseUser; 

        if (!firebaseUser || firebaseUser.uid !== uid) { 
            return res.status(403).json({ error: 'UID mismatch or no authenticated user' });
        }

        const patientRef = db.collection('patients').doc(uid);
        const doc = await patientRef.get();

        if (doc.exists) {
            return res.status(400).json({ error: 'Paciente ya registrado' });
        }

        const patientData = {
            firebase_uid: uid,
            username: username,
            email: email,
            phone_number: phoneNumber,
            date_of_birth: dateOfBirth,
            profile_picture_url: profilePictureUrl || null,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
        };

        await patientRef.set(patientData);

        res.status(201).json({
            message: 'Paciente registrado exitosamente',
            patient: { id: uid, ...patientData },
        });
    } catch (error) {
        console.error('Error al registrar paciente en Firestore:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

router.get('/profile', verifyFirebaseToken, async (req, res) => {
    try {
        const uid = req.firebaseUser.uid; 
        const patientRef = db.collection('patients').doc(uid);
        const doc = await patientRef.get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'Paciente no encontrado' });
        }

        res.json({ patient: { id: doc.id, ...doc.data() } });
    } catch (error) {
        console.error('Error al obtener perfil paciente de Firestore:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

router.put('/profile', verifyFirebaseToken, async (req, res) => {
    try {
        const uid = req.firebaseUser.uid; 
        const { username, email, phoneNumber, profilePictureUrl } = req.body;

        const patientRef = db.collection('patients').doc(uid);
        const doc = await patientRef.get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'Paciente no encontrado' });
        }

        const updateData = {
            username: username,
            email: email,
            phone_number: phoneNumber,
            profile_picture_url: profilePictureUrl || null,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
        };

        await patientRef.update(updateData);

        const updatedDoc = await patientRef.get();

        res.json({ message: 'Perfil actualizado', patient: { id: updatedDoc.id, ...updatedDoc.data() } });
    } catch (error) {
        console.error('Error al actualizar perfil paciente en Firestore:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

router.put('/profile', verifyFirebaseToken, async (req, res) => {
    try {
        const uid = req.firebaseUser.uid;
        const { username, email, phoneNumber, dateOfBirth, profilePictureUrl } = req.body;

        const patientRef = db.collection('patients').doc(uid);
        const doc = await patientRef.get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'Paciente no encontrado' });
        }

        const updateData = {};
        if (username !== undefined) updateData.username = username;
        if (email !== undefined) updateData.email = email;
        if (phoneNumber !== undefined) updateData.phone_number = phoneNumber;
        if (dateOfBirth !== undefined) updateData.date_of_birth = dateOfBirth;
        if (profilePictureUrl !== undefined) updateData.profile_picture_url = profilePictureUrl;

        updateData.updated_at = admin.firestore.FieldValue.serverTimestamp();

        
        if (Object.keys(updateData).length > 1) { 
            await patientRef.update(updateData);
        }

        const updatedDoc = await patientRef.get();
        res.json({ message: 'Perfil actualizado', patient: { id: updatedDoc.id, ...updatedDoc.data() } });
    } catch (error) {
        console.error('Error al actualizar perfil paciente en Firestore:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

export default router;