// psychologistRoutes.js

import express from 'express';
import { db } from '../firebase-admin.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { FieldValue } from 'firebase-admin/firestore'; 

const router = express.Router();

// Ruta para actualizar la información profesional del psicólogo
router.patch('/:uid/professional', verifyFirebaseToken, async (req, res) => {
    try {
        const uid = req.firebaseUser.uid;

        if (uid !== req.params.uid) {
            return res.status(403).json({ error: 'Acceso no autorizado' });
        }

        const {
            fullName,
            professionalTitle,
            professionalLicense,
            yearsExperience,
            description,
            education,
            certifications,
            specialty,
            subSpecialties,
            schedule,
            isAvailable,
        } = req.body;

        const updateData = { updatedAt: FieldValue.serverTimestamp() };

        // Validación y asignación de datos
        if (typeof fullName === 'string') updateData.fullName = fullName;
        if (typeof professionalTitle === 'string') updateData.professionalTitle = professionalTitle;
        if (typeof professionalLicense === 'string') updateData.professionalLicense = professionalLicense;
        if (typeof yearsExperience === 'number') updateData.yearsExperience = yearsExperience;
        if (typeof description === 'string') updateData.description = description;
        if (Array.isArray(education)) updateData.education = education;
        if (Array.isArray(certifications)) updateData.certifications = certifications;
        if (typeof specialty === 'string') updateData.specialty = specialty;
        if (Array.isArray(subSpecialties)) updateData.subSpecialties = subSpecialties;
        if (typeof schedule === 'object' && schedule !== null) updateData.schedule = schedule;
        if (typeof isAvailable === 'boolean') updateData.isAvailable = isAvailable;

        // Guardar la información en la colección CORRECTA
        await db.collection('psychologist_professional_info').doc(uid).set(updateData, { merge: true });

        res.status(200).json({ message: 'Información profesional actualizada' });
    } catch (error) {
        console.error('Error al actualizar información profesional del psicólogo:', error);
        res.status(500).json({ error: 'Error interno del servidor', details: error.message });
    }
});

// Ruta para obtener la información profesional del psicólogo
router.get('/:uid/professional', verifyFirebaseToken, async (req, res) => {
    try {
        const uid = req.firebaseUser.uid;

        if (uid !== req.params.uid) {
            return res.status(403).json({ error: 'Acceso no autorizado' });
        }

        const psychologistRef = db.collection('psychologist_professional_info').doc(uid);
        const doc = await psychologistRef.get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'Perfil de psicólogo no encontrado' });
        }

        res.status(200).json(doc.data());
    } catch (error) {
        console.error('Error al obtener la información profesional del psicólogo:', error);
        res.status(500).json({ error: 'Error interno del servidor', details: error.message });
    }
});

export default router;