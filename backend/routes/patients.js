// backend/routes/patients.js

import express from 'express';
const router = express.Router();
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { db } from '../firebase-admin.js';
import { FieldValue } from 'firebase-admin/firestore'; 
import multer from 'multer'; 
import { v2 as cloudinary } from 'cloudinary'; 
import { genericUploadHandler } from '../middlewares/upload_handler.js';
import streamifier from 'streamifier'; 

// Configuracion de cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME, 
  api_key: process.env.CLOUDINARY_API_KEY, 
  api_secret: process.env.CLOUDINARY_API_SECRET, 
});

const upload = multer({ storage: multer.memoryStorage() });


router.post('/register', verifyFirebaseToken, async (req, res) => {
    try {
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
            terms_accepted: false,
            created_at: FieldValue.serverTimestamp(), 
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

        updateData.updated_at = FieldValue.serverTimestamp(); 

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


router.post('/upload-profile-picture', verifyFirebaseToken, async (req, res, next) => {
    const uid = req.firebaseUser.uid;
    genericUploadHandler('patients_profile_pictures', uid)[0](req, res, (err) => {
        if (err) return next(err); 

        genericUploadHandler('patients_profile_pictures', uid)[1](req, res, async (err) => {
            if (err) return next(err); 

            try {
                const profilePictureUrl = req.uploadedFile.url;
                const patientRef = db.collection('patients').doc(uid);
                await patientRef.update({
                    profile_picture_url: profilePictureUrl,
                    updated_at: FieldValue.serverTimestamp(), 
                });

                res.json({ 
                    message: 'Foto de perfil subida y URL actualizada', 
                    profilePictureUrl: profilePictureUrl 
                });
            } catch (dbError) {
                console.error('Error al actualizar Firestore:', dbError);
                res.status(500).json({ error: 'Error al actualizar la base de datos.' });
            }
        });
    });
});

router.patch('/accept-terms', verifyFirebaseToken, async (req, res) => {
    try {
        const uid = req.firebaseUser.uid;
        const patientRef = db.collection('patients').doc(uid);
        
        const doc = await patientRef.get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Paciente no encontrado' });
        }

        await patientRef.update({
            terms_accepted: true,
            terms_accepted_at: FieldValue.serverTimestamp(),
            updated_at: FieldValue.serverTimestamp(),
        });

        res.json({ 
            message: 'Términos aceptados exitosamente',
            terms_accepted: true 
        });
    } catch (error) {
        console.error('Error al actualizar términos:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

export default router;