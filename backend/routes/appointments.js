import express from 'express';
import { db } from '../firebase-admin.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { FieldValue } from 'firebase-admin/firestore';

const router = express.Router();

router.use(verifyFirebaseToken);


// Crear nueva cita 

router.post('/', verifyFirebaseToken, async (req, res) => {
    try {
        // Obtener el ID del usuario autenticado
        const authenticatedUserId = req.firebaseUser.uid;
        
        const {
            psychologistId,
            patientId, 
            scheduledDateTime,
            type,
            notes
        } = req.body;

        if (!psychologistId || !patientId || !scheduledDateTime || !type) {
            return res.status(400).json({
                error: 'psychologistId, patientId, scheduledDateTime y type son requeridos'
            });
        }

        let finalPatientId;
        let isSchedulingForOtherPatient = false;
      
        if (patientId !== authenticatedUserId) {
            
            if (psychologistId !== authenticatedUserId) {
                return res.status(403).json({
                    error: 'Solo el psicólogo puede agendar citas para sus pacientes'
                });
            }
            finalPatientId = patientId;
            isSchedulingForOtherPatient = true;
        } else {
            
            finalPatientId = authenticatedUserId;
        }

        let appointmentId;

        await db.runTransaction(async (transaction) => {
            const appointmentDate = new Date(scheduledDateTime);
            appointmentDate.setMinutes(appointmentDate.getMinutes() - appointmentDate.getTimezoneOffset());

            const startOfHour = new Date(appointmentDate);
            startOfHour.setMinutes(0, 0, 0);

            const endOfHour = new Date(appointmentDate);
            endOfHour.setMinutes(59, 59, 999);

            // Verificar disponibilidad del horario
            const existingAppointmentsRef = db.collection('appointments')
                .where('psychologistId', '==', psychologistId)
                .where('scheduledDateTime', '>=', startOfHour)
                .where('scheduledDateTime', '<=', endOfHour)
                .where('status', 'in', ['pending', 'confirmed']);

            const existingAppointmentsSnapshot = await transaction.get(existingAppointmentsRef);

            if (!existingAppointmentsSnapshot.empty) {
                throw new Error('El horario seleccionado no está disponible');
            }

            // Obtener datos del paciente y psicólogo
            const patientRef = db.collection('patients').doc(finalPatientId);
            const psychologistRef = db.collection('psychologists').doc(psychologistId);
            const psychologistProfRef = db.collection('psychologist_professional_info').doc(psychologistId);

            const [patientDoc, psychologistDoc, psychologistProfDoc] = await Promise.all([
                transaction.get(patientRef),
                transaction.get(psychologistRef),
                transaction.get(psychologistProfRef),
            ]);

            if (!patientDoc.exists) throw new Error('Paciente no encontrado');
            if (!psychologistDoc.exists) throw new Error('Psicólogo no encontrado');

            const patientData = patientDoc.data();
            const psychologistData = psychologistDoc.data();
            const psychologistProfData = psychologistProfDoc.exists ? psychologistProfDoc.data() : {};

            const appointmentData = {
                patientId: finalPatientId,
                patientName: patientData.username || 'Usuario desconocido',
                patientEmail: patientData.email,
                patientProfileUrl: patientData.profilePictureUrl || null,
                psychologistId,
                psychologistName: psychologistProfData.fullName || 'Psicólogo desconocido',
                psychologistSpecialty: psychologistProfData.specialty || 'Psicología General',
                psychologistProfileUrl: psychologistData.profilePictureUrl || null,
                scheduledDateTime: appointmentDate,
                durationMinutes: 60,
                type,
                status: isSchedulingForOtherPatient ? 'confirmed' : 'pending',
                price: psychologistProfData.hourlyRate || 80.0,
                patientNotes: notes || null,
                scheduledBy: authenticatedUserId,
                createdAt: FieldValue.serverTimestamp(),
                updatedAt: FieldValue.serverTimestamp()
            };

            const appointmentRef = db.collection('appointments').doc();
            appointmentId = appointmentRef.id;
            transaction.set(appointmentRef, appointmentData);
        });

        if (!appointmentId) {
            throw new Error('No se pudo obtener el ID de la cita creada');
        }

        const appointmentDoc = await db.collection('appointments').doc(appointmentId).get();

        if (!appointmentDoc.exists) {
            throw new Error('La cita no se creó correctamente');
        }

        const appointmentData = appointmentDoc.data();
        const responseData = {
            id: appointmentDoc.id,
            ...appointmentData,
            scheduledDateTime: appointmentData.scheduledDateTime.toDate().toISOString(),
            createdAt: appointmentData.createdAt.toDate().toISOString(),
            updatedAt: appointmentData.updatedAt.toDate().toISOString(),
            confirmedAt: appointmentData.confirmedAt ? appointmentData.confirmedAt.toDate().toISOString() : null,
            cancelledAt: appointmentData.cancelledAt ? appointmentData.cancelledAt.toDate().toISOString() : null,
            completedAt: appointmentData.completedAt ? appointmentData.completedAt.toDate().toISOString() : null,
        };

        console.log('Cita creada exitosamente:', responseData);

        res.status(201).json({
            message: 'Cita creada exitosamente',
            appointment: responseData
        });

    } catch (error) {
        console.error('Error al crear cita:', error);
        const statusCode = error.message.includes('disponible') ||
            error.message.includes('encontrado') ||
            error.message.includes('No se pudo obtener') ? 409 : 500;
        res.status(statusCode).json({
            error: 'Error al agendar la cita',
            details: error.message
        });
    }
});

// Obtener citas del usuario (paciente o psicólogo)
router.get('/', verifyFirebaseToken, async (req, res) => {
    try {
        const userId = req.firebaseUser.uid;
        const { status, role } = req.query;

        let userRole = 'unknown';

        if (role === 'psychologist' || role === 'patient') {
            userRole = role;
        } else {
            const userAsPatientDoc = await db.collection('patients').doc(userId).get();
            const userAsPsychologistDoc = await db.collection('psychologists').doc(userId).get();

            if (userAsPatientDoc.exists) {
                userRole = 'patient';
            } else if (userAsPsychologistDoc.exists) {
                userRole = 'psychologist';
            }
        }

        let query = db.collection('appointments');

        if (userRole === 'psychologist') {
            query = query.where('psychologistId', '==', userId);
        } else if (userRole === 'patient') {
            query = query.where('patientId', '==', userId);
        } else {
            return res.status(200).json({ appointments: [] });
        }

        if (status) {
            query = query.where('status', '==', status);
        }

        query = query.orderBy('scheduledDateTime', 'desc');

        const appointmentsSnapshot = await query.get();
        const appointments = [];

        appointmentsSnapshot.forEach(doc => {
            const appointmentData = doc.data();
            const patientName = appointmentData.patientName ?? 'Nombre no disponible';
            const psychologistName = appointmentData.psychologistName ?? 'Nombre no disponible';
            const patientEmail = appointmentData.patientEmail ?? 'Email no disponible';
            const psychologistSpecialty = appointmentData.psychologistSpecialty ?? 'Especialidad no disponible';

            appointments.push({
                id: doc.id,
                ...appointmentData,
                patientName: patientName,
                patientEmail: patientEmail,
                psychologistName: psychologistName,
                psychologistSpecialty: psychologistSpecialty,
                scheduledDateTime: appointmentData.scheduledDateTime?.toDate()?.toISOString() ?? null,
                createdAt: appointmentData.createdAt?.toDate()?.toISOString() ?? null,
                updatedAt: appointmentData.updatedAt?.toDate()?.toISOString() ?? null,
                confirmedAt: appointmentData.confirmedAt?.toDate()?.toISOString() ?? null,
                cancelledAt: appointmentData.cancelledAt?.toDate()?.toISOString() ?? null,
                completedAt: appointmentData.completedAt?.toDate()?.toISOString() ?? null,
                ratedAt: appointmentData.ratedAt?.toDate()?.toISOString() ?? null,
            });
        });

        res.status(200).json({ appointments });

    } catch (error) {
        console.error('Error al obtener citas:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            details: error.message
        });
    }
});

// Obtener horarios disponibles
router.get('/available-slots/:psychologistId', verifyFirebaseToken, async (req, res) => {
    try {
        const { psychologistId } = req.params;
        const { startDate, endDate } = req.query;


        if (!startDate || !endDate) {
            return res.status(400).json({ error: 'startDate y endDate son requeridos (YYYY-MM-DD)' });
        }
        const start = new Date(startDate + 'T00:00:00Z'); // UTC
        const end = new Date(endDate + 'T23:59:59Z');     // UTC


        if (isNaN(start) || isNaN(end) || start > end) {
            return res.status(400).json({ error: 'Rango de fechas inválido' });
        }

        const appointmentsSnapshot = await db.collection('appointments')
            .where('psychologistId', '==', psychologistId)
            .where('scheduledDateTime', '>=', start)
            .where('scheduledDateTime', '<=', end)
            .where('status', 'in', ['pending', 'confirmed'])
            .get();

        const existingAppointments = [];
        appointmentsSnapshot.forEach(doc => {
            const data = doc.data();
            existingAppointments.push(data);
        });

        const occupiedSlots = new Set();
        existingAppointments.forEach(data => {
            const appointmentTime = data.scheduledDateTime.toDate();
            const hour = appointmentTime.getUTCHours();
            const date = appointmentTime.toISOString().split('T')[0];
            occupiedSlots.add(`${date}-${hour}`);
            console.log('🔍 Horario ocupado:', `${date}-${hour}`);
        });

        const availableSlots = [];
        const now = new Date();
        const nowUTC = new Date(now.toISOString());

        for (let d = new Date(start); d <= end; d.setUTCDate(d.getUTCDate() + 1)) {
            const currentDate = new Date(d);
            const dateStr = currentDate.toISOString().split('T')[0];

            for (let hour = 9; hour < 18; hour++) {
                const slotDateTime = new Date(Date.UTC(
                    currentDate.getUTCFullYear(),
                    currentDate.getUTCMonth(),
                    currentDate.getUTCDate(),
                    hour, 0, 0
                ));

                const isOccupied = occupiedSlots.has(`${dateStr}-${hour}`);
                const isPast = slotDateTime <= nowUTC;
                const isAvailable = !isOccupied && !isPast;

                availableSlots.push({
                    time: `${hour.toString().padStart(2, '0')}:00`,
                    dateTime: slotDateTime.toISOString(),
                    isAvailable,
                    reason: isOccupied ? 'Ocupado' : isPast ? 'Pasado' : null
                });
            }
        }

        res.status(200).json({ availableSlots });

    } catch (error) {
        console.error('Error al obtener horarios disponibles:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            details: error.message
        });
    }
});

// Confirmar cita (psicólogos)
router.patch('/:id/confirm', verifyFirebaseToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { psychologistNotes, meetingLink } = req.body;

        const appointmentRef = db.collection('appointments').doc(id);
        const appointmentDoc = await appointmentRef.get();

        if (!appointmentDoc.exists) {
            return res.status(404).json({ error: 'Cita no encontrada' });
        }

        const appointmentData = appointmentDoc.data();

        if (appointmentData.psychologistId !== req.firebaseUser.uid) {
            return res.status(403).json({ error: 'Acceso denegado' });
        }

        if (appointmentData.status !== 'pending') {
            return res.status(400).json({ error: 'La cita no está pendiente de confirmación' });
        }

        const updateData = {
            status: 'confirmed',
            confirmedAt: FieldValue.serverTimestamp(),
            psychologistNotes: psychologistNotes || null,
            meetingLink: meetingLink || null,
            updatedAt: FieldValue.serverTimestamp(),
        };

        await appointmentRef.update(updateData);

        res.status(200).json({ message: 'Cita confirmada exitosamente' });

    } catch (error) {
        console.error('Error al confirmar cita:', error);
        res.status(500).json({ error: 'Error interno del servidor', details: error.message });
    }
});

// Cancelar cita (pacientes y psicólogos)
router.patch('/:id/cancel', verifyFirebaseToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;

        const appointmentRef = db.collection('appointments').doc(id);
        const appointmentDoc = await appointmentRef.get();

        if (!appointmentDoc.exists) {
            return res.status(404).json({ error: 'Cita no encontrada' });
        }

        const appointmentData = appointmentDoc.data();
        const userId = req.firebaseUser.uid;

        if (appointmentData.patientId !== userId && appointmentData.psychologistId !== userId) {
            return res.status(403).json({ error: 'Acceso denegado' });
        }

        const updateData = {
            status: 'cancelled',
            cancellationReason: reason,
            cancelledAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
        };

        await appointmentRef.update(updateData);

        res.status(200).json({ message: 'Cita cancelada exitosamente' });

    } catch (error) {
        console.error('Error al cancelar cita:', error);
        res.status(500).json({ error: 'Error interno del servidor', details: error.message });
    }
});

// Completar cita (psicólogos)
router.patch('/:id/complete', verifyFirebaseToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { notes } = req.body;

        const appointmentRef = db.collection('appointments').doc(id);
        const appointmentDoc = await appointmentRef.get();

        if (!appointmentDoc.exists) {
            return res.status(404).json({ error: 'Cita no encontrada' });
        }

        const appointmentData = appointmentDoc.data();

        if (appointmentData.psychologistId !== req.firebaseUser.uid) {
            return res.status(403).json({ error: 'Acceso denegado' });
        }

        const updateData = {
            status: 'completed',
            psychologistNotes: notes || null,
            completedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
        };

        await appointmentRef.update(updateData);

        res.status(200).json({ message: 'Cita completada exitosamente' });

    } catch (error) {
        console.error('Error al completar cita:', error);
        res.status(500).json({ error: 'Error interno del servidor', details: error.message });
    }
});

// Calificar cita
router.patch('/:id/rate', verifyFirebaseToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { rating, comment } = req.body;

        const appointmentRef = db.collection('appointments').doc(id);
        const appointmentDoc = await appointmentRef.get();

        if (!appointmentDoc.exists) {
            return res.status(404).json({ error: 'Cita no encontrada' });
        }

        const appointmentData = appointmentDoc.data();
        // Verificar que el usuario es el paciente
        if (appointmentData.patientId !== req.firebaseUser.uid) {
            return res.status(403).json({ error: 'Acceso denegado' });
        }
        // Verificar que la cita está completada
        if (appointmentData.status !== 'completed') {
            return res.status(400).json({ error: 'Solo se pueden calificar citas completadas' });
        }

        const updateData = {
            status: 'rated',
            rating: rating,
            ratingComment: comment || null,
            ratedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
        };

        await appointmentRef.update(updateData);

        res.status(200).json({ message: 'Cita calificada exitosamente' });

    } catch (error) {
        console.error('Error al calificar cita:', error);
        res.status(500).json({ error: 'Error interno del servidor', details: error.message });
    }
});

router.patch('/:id/start-session', verifyFirebaseToken, async (req, res) => {
    try {
        const { id } = req.params;

        const appointmentRef = db.collection('appointments').doc(id);
        const appointmentDoc = await appointmentRef.get();

        if (!appointmentDoc.exists) {
            return res.status(404).json({ error: 'Cita no encontrada' });
        }

        const appointmentData = appointmentDoc.data();

        // Verificar que el usuario es el psicólogo
        if (appointmentData.psychologistId !== req.firebaseUser.uid) {
            return res.status(403).json({ error: 'Acceso denegado' });
        }

        // Verificar que la cita está confirmada
        if (appointmentData.status !== 'confirmed') {
            return res.status(400).json({ error: 'Solo se pueden iniciar sesiones de citas confirmadas' });
        }
        const updateData = {
            status: 'in_progress',
            sessionStartedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
        };
        await appointmentRef.update(updateData);
        res.status(200).json({ message: 'Sesión iniciada exitosamente' });

    } catch (error) {
        console.error('Error al iniciar sesión:', error);
        res.status(500).json({ error: 'Error interno del servidor', details: error.message });
    }
});

// Para completar sesión
router.patch('/:id/complete-session', verifyFirebaseToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { notes } = req.body;

        const appointmentRef = db.collection('appointments').doc(id);
        const appointmentDoc = await appointmentRef.get();
        if (!appointmentDoc.exists) {
            return res.status(404).json({ error: 'Cita no encontrada' });
        }

        const appointmentData = appointmentDoc.data();
        // Verificar que el usuario es el psicólogo
        if (appointmentData.psychologistId !== req.firebaseUser.uid) {
            return res.status(403).json({ error: 'Acceso denegado' });
        }

        // Verificar que la cita está en progreso
        if (appointmentData.status !== 'in_progress') {
            return res.status(400).json({ error: 'Solo se pueden completar sesiones en progreso' });
        }

        const updateData = {
            status: 'completed',
            psychologistNotes: notes || null,
            completedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
        };

        await appointmentRef.update(updateData);

        res.status(200).json({ message: 'Sesión completada exitosamente' });

    } catch (error) {
        console.error('Error al completar sesión:', error);
        res.status(500).json({ error: 'Error interno del servidor', details: error.message });
    }
});

export default router;