// backend/routes/psychologists.js 

import express from 'express';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { db } from '../firebase-admin.js';
import { FieldValue } from 'firebase-admin/firestore';

const router = express.Router();

// ============================================================================
// REGISTRO INICIAL 
// ============================================================================
router.post('/register', verifyFirebaseToken, async (req, res) => {
    try {
        const {
            uid,
            username,
            email,
            phoneNumber,
            professionalLicense,
            dateOfBirth,
            profilePictureUrl,
        } = req.body;

        const firebaseUser = req.firebaseUser;

        if (!firebaseUser || firebaseUser.uid !== uid) {
            return res.status(403).json({ error: 'UID mismatch o usuario no autenticado' });
        }

        const psychologistRef = db.collection('psychologists').doc(uid);
        const doc = await psychologistRef.get();

        if (doc.exists) {
            return res.status(400).json({ error: 'Psicólogo ya registrado' });
        }

        // Solo datos básicos en el registro inicial
        const psychologistData = {
            firebaseUid: uid,
            username,
            email,
            phoneNumber,
            professionalLicense,
            dateOfBirth,
            profilePictureUrl: profilePictureUrl || null,
            // Campos profesionales inicializados como null/vacío
            fullName: null,
            professionalTitle: null,
            yearsExperience: 0,
            description: null,
            education: [],
            certifications: [],
            specialty: null,
            subSpecialties: [],
            schedule: {},
            isAvailable: false,
            status: 'PENDING',
            // Campos de control
            profileCompleted: false,
            professionalInfoCompleted: false,
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
        };

        await psychologistRef.set(psychologistData);

        res.status(201).json({
            message: 'Psicólogo registrado exitosamente',
            psychologist: { id: uid, ...psychologistData },
        });
    } catch (error) {
        console.error('Error al registrar psicólogo:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ============================================================================
// OBTENER PERFIL COMPLETO
// ============================================================================
router.get('/:uid', verifyFirebaseToken, async (req, res) => {
    try {
        const { uid } = req.params;

        if (req.firebaseUser.uid !== uid) {
            return res.status(403).json({ error: 'Acceso no autorizado.' });
        }

        const psychologistRef = db.collection('psychologists').doc(uid);
        const doc = await psychologistRef.get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'Psicólogo no encontrado' });
        }

        res.json({ 
            psychologist: { 
                id: doc.id, 
                ...doc.data() 
            } 
        });
    } catch (error) {
        console.error('Error al obtener perfil del psicólogo:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ============================================================================
// ACTUALIZAR INFORMACIÓN BÁSICA (perfil personal)
// ============================================================================
router.patch('/:uid/basic', verifyFirebaseToken, async (req, res) => {
    try {
        const { uid } = req.params;

        if (req.firebaseUser.uid !== uid) {
            return res.status(403).json({ error: 'Acceso no autorizado.' });
        }

        const {
            username,
            email,
            phoneNumber,
            profilePictureUrl,
            dateOfBirth
        } = req.body;

        const updateData = { updatedAt: FieldValue.serverTimestamp() };

        // Validación y asignación solo de campos básicos
        if (typeof username === 'string') updateData.username = username;
        if (typeof email === 'string') updateData.email = email;
        if (typeof phoneNumber === 'string') updateData.phoneNumber = phoneNumber;
        if (typeof profilePictureUrl === 'string') updateData.profilePictureUrl = profilePictureUrl;
        if (dateOfBirth) updateData.dateOfBirth = dateOfBirth;

        await db.collection('psychologists').doc(uid).set(updateData, { merge: true });

        res.json({ message: 'Información básica actualizada exitosamente' });
    } catch (error) {
        console.error('Error al actualizar información básica:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ============================================================================
// ACTUALIZAR INFORMACIÓN PROFESIONAL
// ============================================================================
router.patch('/:uid/professional', verifyFirebaseToken, async (req, res) => {
    try {
        const { uid } = req.params;

        if (req.firebaseUser.uid !== uid) {
            return res.status(403).json({ error: 'Acceso no autorizado.' });
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

        // Validación y asignación de datos profesionales
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

        // Marcar como información profesional completada si se proporcionan datos clave
        if (fullName && professionalTitle && specialty) {
            updateData.professionalInfoCompleted = true;
        }

        await db.collection('psychologists').doc(uid).set(updateData, { merge: true });

        res.json({ message: 'Información profesional actualizada exitosamente' });
    } catch (error) {
        console.error('Error al actualizar información profesional:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ============================================================================
// ACTUALIZAR DISPONIBILIDAD (ruta específica para toggle rápido)
// ============================================================================
router.patch('/:uid/availability', verifyFirebaseToken, async (req, res) => {
    try {
        const { uid } = req.params;

        if (req.firebaseUser.uid !== uid) {
            return res.status(403).json({ error: 'Acceso no autorizado.' });
        }

        const { isAvailable } = req.body;

        if (typeof isAvailable !== 'boolean') {
            return res.status(400).json({ error: 'isAvailable debe ser un valor booleano' });
        }

        const updateData = {
            isAvailable,
            updatedAt: FieldValue.serverTimestamp()
        };

        await db.collection('psychologists').doc(uid).set(updateData, { merge: true });

        res.json({ 
            message: `Disponibilidad ${isAvailable ? 'activada' : 'desactivada'} exitosamente`,
            isAvailable 
        });
    } catch (error) {
        console.error('Error al actualizar disponibilidad:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ============================================================================
// OBTENER SOLO INFORMACIÓN PROFESIONAL (para casos específicos)
// ============================================================================
router.get('/:uid/professional', verifyFirebaseToken, async (req, res) => {
    try {
        const { uid } = req.params;

        if (req.firebaseUser.uid !== uid) {
            return res.status(403).json({ error: 'Acceso no autorizado.' });
        }

        const psychologistRef = db.collection('psychologists').doc(uid);
        const doc = await psychologistRef.get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'Psicólogo no encontrado' });
        }

        const data = doc.data();
        
        // Extraer solo los campos profesionales
        const professionalData = {
            fullName: data.fullName,
            professionalTitle: data.professionalTitle,
            professionalLicense: data.professionalLicense,
            yearsExperience: data.yearsExperience,
            description: data.description,
            education: data.education,
            certifications: data.certifications,
            specialty: data.specialty,
            subSpecialties: data.subSpecialties,
            schedule: data.schedule,
            isAvailable: data.isAvailable,
            status: data.status || 'PENDING', // Incluir el estado
            professionalInfoCompleted: data.professionalInfoCompleted,
            updatedAt: data.updatedAt
        };

        res.json(professionalData);
    } catch (error) {
        console.error('Error al obtener información profesional:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ============================================================================
// ELIMINAR PSICÓLOGO (marcar como inactivo)
// ============================================================================
router.delete('/:uid', verifyFirebaseToken, async (req, res) => {
    try {
        const { uid } = req.params;

        if (req.firebaseUser.uid !== uid) {
            return res.status(403).json({ error: 'Acceso no autorizado.' });
        }

        // No eliminar realmente, solo marcar como inactivo
        const updateData = {
            isActive: false,
            isAvailable: false,
            deactivatedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp()
        };

        await db.collection('psychologists').doc(uid).set(updateData, { merge: true });

        res.json({ message: 'Cuenta desactivada exitosamente' });
    } catch (error) {
        console.error('Error al desactivar cuenta:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

export default router;