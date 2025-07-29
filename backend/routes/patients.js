// backend/routes/patients.js
const express = require('express');
const router = express.Router();
const verifyFirebaseToken = require('../middlewares/auth_middleware');
const admin = require('../firebase-admin');
const db = admin.firestore(); // Obtén la instancia de Firestore

router.post('/register', verifyFirebaseToken, async (req, res) => {
    try {
        console.log('Datos recibidos para registro de paciente:', req.body);
        const { uid, username, email, phoneNumber, dateOfBirth, profilePictureUrl } = req.body;
        const firebaseUser = req.firebaseUser;

        if (firebaseUser.uid !== uid) {
            return res.status(403).json({ error: 'UID mismatch' });
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
            profile_picture_url: profilePictureUrl || null, // Asegúrate de manejar si es nulo
            created_at: admin.firestore.FieldValue.serverTimestamp(),
        };

        await patientRef.set(patientData);

        res.status(201).json({
            message: 'Paciente registrado exitosamente',
            patient: { id: uid, ...patientData }, // Asegúrate que el formato coincide con tu PatientModel
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

        res.json({ patient: { id: doc.id, ...doc.data() } }); // Asegúrate que el formato coincide con tu PatientModel
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
            profile_picture_url: profilePictureUrl || null, // Asegúrate de manejar si es nulo
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
        };

        await patientRef.update(updateData);

        const updatedDoc = await patientRef.get(); // Obtener el documento actualizado para la respuesta

        res.json({ message: 'Perfil actualizado', patient: { id: updatedDoc.id, ...updatedDoc.data() } });
    } catch (error) {
        console.error('Error al actualizar perfil paciente en Firestore:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

module.exports = router;