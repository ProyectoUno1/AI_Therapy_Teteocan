import express from 'express';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { db } from '../firebase-admin.js';
import { FieldValue } from 'firebase-admin/firestore';
import { genericUploadHandler } from '../middlewares/upload_handler.js'; 

const router = express.Router();

// Registro inicial
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
            terms_accepted,
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

        const psychologistData = {
            firebaseUid: uid,
            username: username,
            email: email,
            phoneNumber: phoneNumber,
            professionalLicense: professionalLicense, 
            dateOfBirth: dateOfBirth,
            terms_accepted: false, 
            createdAt: FieldValue.serverTimestamp(), 
            updatedAt: FieldValue.serverTimestamp(),
            fcmToken: null, 
            fullName: null,
            professionalTitle: null,
            yearsExperience: null,
            description: null,
            education: [],         
            certifications: [],    
            specialty: null,
            subSpecialties: [],    
            schedule: {},          
            profilePictureUrl: profilePictureUrl || null,
            isAvailable: true,
            price: null,
            isProfileComplete: false,
            status: 'pending', 

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

// Obtener perfil completo - MEJORADO CON LOGS
router.get('/:uid', verifyFirebaseToken, async (req, res) => {
    try {
        const { uid } = req.params;
        
        console.log('🔍 [GET /:uid] Solicitud recibida');
        console.log('📋 UID solicitado:', uid);
        console.log('👤 UID del token:', req.firebaseUser?.uid);
        console.log('📧 Email del token:', req.firebaseUser?.email);

        // Verificar que el usuario autenticado coincida con el UID solicitado
        if (req.firebaseUser.uid !== uid) {
            console.log('❌ UIDs no coinciden');
            console.log('   - Solicitado:', uid);
            console.log('   - Token:', req.firebaseUser.uid);
            return res.status(403).json({ error: 'Acceso no autorizado.' });
        }

        console.log('✅ Autenticación correcta, consultando Firestore...');

        const psychologistRef = db.collection('psychologists').doc(uid);
        const doc = await psychologistRef.get();

        if (!doc.exists) {
            console.log('⚠️ Documento no existe en Firestore');
            console.log('📁 Colección: psychologists');
            console.log('📄 Documento ID:', uid);
            return res.status(404).json({ error: 'Psicólogo no encontrado' });
        }

        const data = doc.data();
        console.log('✅ Psicólogo encontrado');
        console.log('👤 Nombre:', data.fullName || data.username);
        console.log('📧 Email:', data.email);
        console.log('🎓 Título:', data.professionalTitle);
        console.log('📄 Cédula:', data.professionalLicense);

        const response = { 
            psychologist: { 
                uid: doc.id, // ✅ Agregar uid explícitamente
                ...data 
            } 
        };

        console.log('📤 Enviando respuesta...');
        res.status(200).json(response);

    } catch (error) {
        console.error('❌ Error al obtener perfil del psicólogo:', error);
        console.error('Stack trace:', error.stack);
        res.status(500).json({ 
            error: 'Error interno del servidor',
            details: error.message 
        });
    }
});

// backend/routes/psychologistRoutes.js

router.patch('/:uid/professional-info', verifyFirebaseToken, async (req, res) => {
  try {
    const { uid } = req.params;
    
    if (req.firebaseUser.uid !== uid) {
      return res.status(403).json({ error: 'No autorizado' });
    }

    const {
      fullName,
      professionalLicense,
      professionalTitle,
      yearsExperience,
      description,
      education,
      certifications,
      specialty,
      subSpecialties,
      schedule,
      profilePictureUrl,
      isAvailable,
      price,
    } = req.body;

    console.log('📝 Actualizando psicólogo:', uid);

    const updateData = {};
    if (fullName !== undefined) updateData.fullName = fullName;
    if (professionalLicense !== undefined) updateData.professionalLicense = professionalLicense;
    if (professionalTitle !== undefined) updateData.professionalTitle = professionalTitle;
    if (yearsExperience !== undefined) updateData.yearsExperience = yearsExperience;
    if (description !== undefined) updateData.description = description;
    if (education !== undefined) updateData.education = education;
    if (certifications !== undefined) updateData.certifications = certifications;
    if (specialty !== undefined) updateData.specialty = specialty;
    if (subSpecialties !== undefined) updateData.subSpecialties = subSpecialties;
    if (schedule !== undefined) updateData.schedule = schedule;
    if (profilePictureUrl !== undefined) updateData.profilePictureUrl = profilePictureUrl;
    if (isAvailable !== undefined) updateData.isAvailable = isAvailable;
    if (price !== undefined) updateData.price = price;
    
    updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    await db.collection('psychologists').doc(uid).update(updateData);

    res.status(200).json({ 
      message: 'Información profesional actualizada exitosamente',
      uid: uid 
    });

  } catch (error) {
    console.error('❌ Error:', error);
    res.status(500).json({ error: 'Error al actualizar información profesional' });
  }
});


// Actualizar infromacion basica
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
//Actualizar informacion profesional
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
            price,
            profilePictureUrl,
        } = req.body;

        const updateData = { updatedAt: FieldValue.serverTimestamp() };

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
        if (typeof price === 'number' && price > 0) {
            updateData.price = price;
        }
        
        if (typeof profilePictureUrl === 'string') {
            updateData.profilePictureUrl = profilePictureUrl;
        }

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

// Actualizar disponibilidad
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

// Obtener informacion profesional
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
            price: data.price, 
            status: data.status || 'PENDING',
            professionalInfoCompleted: data.professionalInfoCompleted,
            updatedAt: data.updatedAt
        };

        res.json(professionalData);
    } catch (error) {
        console.error('Error al obtener información profesional:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// Eliminar psicologo.
router.delete('/:uid', verifyFirebaseToken, async (req, res) => {
    try {
        const { uid } = req.params;

        if (req.firebaseUser.uid !== uid) {
            return res.status(403).json({ error: 'Acceso no autorizado.' });
        }

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


router.post('/upload-profile-picture', verifyFirebaseToken, async (req, res) => {
    const uid = req.firebaseUser.uid;
    const [uploadMiddleware, processMiddleware] = genericUploadHandler('psychologists_profile_pictures', uid);
    
    uploadMiddleware(req, res, (err) => {
        if (err) {
            console.error('Error en multer middleware:', err);
            return res.status(400).json({ error: 'Error al procesar el archivo.' });
        }
        
        // Ejecutar el middleware de Cloudinary
        processMiddleware(req, res, async (err) => {
            if (err) {
                console.error('Error en Cloudinary middleware:', err);
                return res.status(500).json({ error: 'Error al subir la imagen a Cloudinary.' });
            }

            try {
                const profilePictureUrl = req.uploadedFile.url;
                const psychRef = db.collection('psychologists').doc(uid);
                
                await psychRef.update({
                    profilePictureUrl: profilePictureUrl, 
                    updatedAt: FieldValue.serverTimestamp(), 
                });

                res.json({ 
                    message: 'Foto de perfil subida y URL actualizada', 
                    profilePictureUrl: profilePictureUrl 
                });
            } catch (dbError) {
                console.error('Error al actualizar Firestore para psicólogo:', dbError);
                res.status(500).json({ error: 'Error al actualizar la base de datos.' });
            }
        });
    });
});

router.patch('/accept-terms', verifyFirebaseToken, async (req, res) => {
    try {
        const uid = req.firebaseUser.uid; 
        const psychologistRef = db.collection('psychologists').doc(uid);
        
        const doc = await psychologistRef.get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Psicólogo no encontrado' });
        }

        await psychologistRef.update({
            termsAccepted: true,
            termsAcceptedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
        });

        res.json({ 
            message: 'Términos aceptados exitosamente',
            termsAccepted: true 
        });
    } catch (error) {
        console.error('Error al actualizar términos:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

router.get('/stream', verifyFirebaseToken, async (req, res) => {
    try {
  
        res.setHeader('Content-Type', 'text/event-stream');
        res.setHeader('Cache-Control', 'no-cache');
        res.setHeader('Connection', 'keep-alive');

        const unsubscribe = db.collection('psychologists')
            .onSnapshot((snapshot) => {
                const psychologists = snapshot.docs.map(doc => ({
                    id: doc.id,
                    ...doc.data()
                }));
                
                res.write(`data: ${JSON.stringify(psychologists)}\n\n`);
            }, (error) => {
                console.error('Error en stream:', error);
                res.write(`event: error\ndata: ${JSON.stringify({ error: error.message })}\n\n`);
            });

        req.on('close', () => {
            unsubscribe();
            res.end();
        });
    } catch (error) {
        console.error('Error al iniciar stream:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});


export default router;