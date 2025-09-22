// backend/routes/admins.js

import express from 'express';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { db } from '../firebase-admin.js';
import { FieldValue } from 'firebase-admin/firestore';

const router = express.Router();

// Middleware adicional para verificar permisos de admin
const verifyAdminPermissions = async (req, res, next) => {
    try {
        const uid = req.firebaseUser.uid;
        const adminRef = db.collection('admins').doc(uid);
        const doc = await adminRef.get();

        if (!doc.exists) {
            return res.status(403).json({ error: 'Acceso denegado: no es administrador' });
        }

        const adminData = doc.data();
        if (!adminData.is_active) {
            return res.status(403).json({ error: 'Cuenta de administrador inactiva' });
        }

        req.adminData = adminData;
        next();
    } catch (error) {
        console.error('Error verificando permisos de admin:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};

// Registrar nuevo administrador (solo super admins pueden hacer esto)
router.post('/register', verifyFirebaseToken, verifyAdminPermissions, async (req, res) => {
    try {
        const { 
            uid, 
            username, 
            email, 
            phoneNumber, 
            dateOfBirth, 
            profilePictureUrl,
            fullName,
            department,
            permissions,
            accessLevel,
            employeeId
        } = req.body;

        // Verificar que el admin actual tiene permisos para crear otros admins
        if (req.adminData.access_level < 3) {
            return res.status(403).json({ error: 'Solo super administradores pueden registrar nuevos admins' });
        }

        const firebaseUser = req.firebaseUser;
        if (!firebaseUser || firebaseUser.uid !== uid) {
            return res.status(403).json({ error: 'UID mismatch o usuario no autenticado' });
        }

        const adminRef = db.collection('admins').doc(uid);
        const doc = await adminRef.get();

        if (doc.exists) {
            return res.status(400).json({ error: 'Administrador ya registrado' });
        }

        const adminData = {
            firebase_uid: uid,
            username: username,
            email: email,
            phone_number: phoneNumber,
            date_of_birth: dateOfBirth,
            profile_picture_url: profilePictureUrl || null,
            role: 'admin',
            full_name: fullName,
            department: department || 'General',
            permissions: permissions || ['read', 'write'],
            access_level: Math.min(accessLevel || 1, req.adminData.access_level - 1), // No puede crear admin con nivel igual o superior
            is_active: true,
            employee_id: employeeId,
            created_at: FieldValue.serverTimestamp(),
            updated_at: FieldValue.serverTimestamp(),
        };

        await adminRef.set(adminData);

        res.status(201).json({
            message: 'Administrador registrado exitosamente',
            admin: { id: uid, ...adminData },
        });
    } catch (error) {
        console.error('Error al registrar administrador en Firestore:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// Obtener perfil de administrador
router.get('/profile', verifyFirebaseToken, verifyAdminPermissions, async (req, res) => {
    try {
        const uid = req.firebaseUser.uid;
        const adminRef = db.collection('admins').doc(uid);
        const doc = await adminRef.get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'Administrador no encontrado' });
        }

        // Actualizar último login
        await adminRef.update({
            last_login: FieldValue.serverTimestamp(),
            updated_at: FieldValue.serverTimestamp()
        });

        res.json({ admin: { id: doc.id, ...doc.data() } });
    } catch (error) {
        console.error('Error al obtener perfil administrador de Firestore:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// Actualizar perfil básico del administrador
router.patch('/profile', verifyFirebaseToken, verifyAdminPermissions, async (req, res) => {
    try {
        const uid = req.firebaseUser.uid;
        const { 
            username, 
            email, 
            phoneNumber, 
            profilePictureUrl,
            fullName,
            department
        } = req.body;

        const adminRef = db.collection('admins').doc(uid);
        const doc = await adminRef.get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'Administrador no encontrado' });
        }

        const updateData = { updated_at: FieldValue.serverTimestamp() };
        if (username !== undefined) updateData.username = username;
        if (email !== undefined) updateData.email = email;
        if (phoneNumber !== undefined) updateData.phone_number = phoneNumber;
        if (profilePictureUrl !== undefined) updateData.profile_picture_url = profilePictureUrl;
        if (fullName !== undefined) updateData.full_name = fullName;
        if (department !== undefined) updateData.department = department;

        if (Object.keys(updateData).length > 1) {
            await adminRef.update(updateData);
        }

        const updatedDoc = await adminRef.get();
        res.json({ 
            message: 'Perfil actualizado', 
            admin: { id: updatedDoc.id, ...updatedDoc.data() } 
        });
    } catch (error) {
        console.error('Error al actualizar perfil administrador en Firestore:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// Obtener lista de todos los usuarios (solo admins con permisos)
router.get('/users', verifyFirebaseToken, verifyAdminPermissions, async (req, res) => {
    try {
        if (!req.adminData.permissions.includes('read_users') && req.adminData.access_level < 2) {
            return res.status(403).json({ error: 'Sin permisos para ver usuarios' });
        }

        const { type, limit = 50, startAfter } = req.query;
        const users = [];

        // Obtener pacientes
        if (!type || type === 'patients') {
            const patientsQuery = db.collection('patients')
                .limit(parseInt(limit));
            
            const patientsSnapshot = await patientsQuery.get();
            patientsSnapshot.forEach(doc => {
                users.push({ id: doc.id, type: 'patient', ...doc.data() });
            });
        }

        // Obtener psicólogos
        if (!type || type === 'psychologists') {
            const psychologistsQuery = db.collection('psychologists')
                .limit(parseInt(limit));
            
            const psychologistsSnapshot = await psychologistsQuery.get();
            psychologistsSnapshot.forEach(doc => {
                users.push({ id: doc.id, type: 'psychologist', ...doc.data() });
            });
        }

        // Obtener otros admins (solo super admins)
        if ((!type || type === 'admins') && req.adminData.access_level >= 3) {
            const adminsQuery = db.collection('admins')
                .limit(parseInt(limit));
            
            const adminsSnapshot = await adminsQuery.get();
            adminsSnapshot.forEach(doc => {
                users.push({ id: doc.id, type: 'admin', ...doc.data() });
            });
        }

        res.json({ users, total: users.length });
    } catch (error) {
        console.error('Error al obtener usuarios:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// Activar/desactivar usuario
router.patch('/users/:userId/status', verifyFirebaseToken, verifyAdminPermissions, async (req, res) => {
    try {
        if (!req.adminData.permissions.includes('manage_users') && req.adminData.access_level < 2) {
            return res.status(403).json({ error: 'Sin permisos para gestionar usuarios' });
        }

        const { userId } = req.params;
        const { isActive, userType } = req.body;

        if (!['patients', 'psychologists', 'admins'].includes(userType)) {
            return res.status(400).json({ error: 'Tipo de usuario inválido' });
        }

        // No permitir que admins de nivel bajo modifiquen otros admins
        if (userType === 'admins' && req.adminData.access_level < 3) {
            return res.status(403).json({ error: 'Sin permisos para modificar administradores' });
        }

        const userRef = db.collection(userType).doc(userId);
        const doc = await userRef.get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        await userRef.update({
            is_active: isActive,
            updated_at: FieldValue.serverTimestamp()
        });

        res.json({ message: `Usuario ${isActive ? 'activado' : 'desactivado'} exitosamente` });
    } catch (error) {
        console.error('Error al cambiar estado del usuario:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// Obtener estadísticas del sistema
router.get('/stats', verifyFirebaseToken, verifyAdminPermissions, async (req, res) => {
    try {
        if (!req.adminData.permissions.includes('view_stats') && req.adminData.access_level < 1) {
            return res.status(403).json({ error: 'Sin permisos para ver estadísticas' });
        }

        const [patientsSnapshot, psychologistsSnapshot, adminsSnapshot] = await Promise.all([
            db.collection('patients').get(),
            db.collection('psychologists').get(),
            db.collection('admins').get()
        ]);

        const stats = {
            patients: {
                total: patientsSnapshot.size,
                active: patientsSnapshot.docs.filter(doc => doc.data().is_active !== false).length,
                premium: patientsSnapshot.docs.filter(doc => doc.data().is_premium === true).length
            },
            psychologists: {
                total: psychologistsSnapshot.size,
                active: psychologistsSnapshot.docs.filter(doc => doc.data().is_active !== false).length,
                available: psychologistsSnapshot.docs.filter(doc => doc.data().isAvailable === true).length
            },
            admins: {
                total: adminsSnapshot.size,
                active: adminsSnapshot.docs.filter(doc => doc.data().is_active === true).length
            },
            timestamp: new Date().toISOString()
        };

        res.json({ stats });
    } catch (error) {
        console.error('Error al obtener estadísticas:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

export default router;