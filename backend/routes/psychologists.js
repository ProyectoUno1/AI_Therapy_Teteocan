// backend/routes/psychologists.js

import express from 'express'; 
const router = express.Router();
import verifyFirebaseToken from '../middlewares/auth_middleware.js'; 



router.post('/register', verifyFirebaseToken, async (req, res) => {
    try {
        const { uid, username, email, phoneNumber, professional_license, dateOfBirth, profilePictureUrl } = req.body;
        const firebaseUser = req.firebaseUser; 

        if (!firebaseUser || firebaseUser.uid !== uid) { 
            return res.status(403).json({ error: 'UID mismatch or no authenticated user' });
        }

        const psychologistRef = db.collection('psychologists').doc(uid);
        const doc = await psychologistRef.get();

        if (doc.exists) {
            return res.status(400).json({ error: 'Psicólogo ya registrado' });
        }

        const psychologistData = {
            firebase_uid: uid,
            username: username,
            email: email,
            phone_number: phoneNumber,
            professional_license: professional_license,
            date_of_birth: dateOfBirth,
            profile_picture_url: profilePictureUrl || null,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
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

router.put('/profile', verifyFirebaseToken, async (req, res) => {
    try {
        const uid = req.firebaseUser.uid; 
        const { username, email, phoneNumber, professional_license, profilePictureUrl } = req.body;

        const psychologistRef = db.collection('psychologists').doc(uid);
        const doc = await psychologistRef.get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'Psicólogo no encontrado' });
        }

        const updateData = {
            username: username,
            email: email,
            phone_number: phoneNumber,
            professional_license: professional_license,
            profile_picture_url: profilePictureUrl || null,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
        };

        await psychologistRef.update(updateData);

        const updatedDoc = await psychologistRef.get(); // Obtener el documento actualizado para la respuesta

        res.json({ message: 'Perfil actualizado', psychologist: { id: updatedDoc.id, ...updatedDoc.data() } });
    } catch (error) {
        console.error('Error al actualizar perfil psicólogo en Firestore:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

export default router;