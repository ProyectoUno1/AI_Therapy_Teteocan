import express from 'express';
import { db } from '../firebase-admin.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { FieldValue } from 'firebase-admin/firestore';
import { createNotification } from './notifications.js';
import {
    cleanupOldAppointments,
    getCleanupStats,
    cleanupAppointmentsOlderThan
} from './services/appointmentsCleanup.js';

const router = express.Router();

router.use(verifyFirebaseToken);

const getChatId = (userId1, userId2) => {
    const sortedIds = [userId1, userId2].sort();
    return sortedIds.join('_');
};

// ⭐ 2. Función para enviar un mensaje directo de sistema
const sendSystemChatMessage = async (chatId, senderId, receiverId, content) => {
    const chatDocRef = db.collection('chats').doc(chatId);
    const messageRef = chatDocRef.collection('messages');
    
    const messageData = {
        senderId: senderId, 
        receiverId: receiverId,
        content: content, 
        timestamp: FieldValue.serverTimestamp(),
        isRead: false,
        type: 'SESSION_START', // Tipo especial para el frontend
    };
    
    await messageRef.add(messageData);
    
    // Actualizar el documento del chat
    await chatDocRef.set({
        participants: [senderId, receiverId],
        lastMessage: content,
        lastMessageTime: FieldValue.serverTimestamp(),
        lastMessageSenderId: senderId,
    }, { merge: true });
};


// Crear nueva cita 

router.post('/', verifyFirebaseToken, async (req, res) => {
    try {
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

            // Verificar que la fecha es válida
            if (isNaN(appointmentDate.getTime())) {
                throw new Error('Fecha y hora inválidas');
            }

            console.log('Fecha recibida del cliente:', scheduledDateTime);
            console.log('Fecha parseada:', appointmentDate.toISOString());
            console.log('Fecha local:', appointmentDate.toLocaleString());

            // Crear rango de hora para verificar disponibilidad
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

            const [patientDoc, psychologistDoc] = await Promise.all([
                transaction.get(patientRef),
                transaction.get(psychologistRef),
            ]);

            if (!patientDoc.exists) throw new Error('Paciente no encontrado');
            if (!psychologistDoc.exists) throw new Error('Psicólogo no encontrado');

            const patientData = patientDoc.data();
            const psychologistData = psychologistDoc.data();

            const isPremiumUser = patientData.isPremium === true;

                  const appointmentData = {
                patientId: finalPatientId,
                patientName: patientData.username || 'Usuario desconocido',
                patientEmail: patientData.email,
                profile_picture_url: patientData.profile_picture_url,
                psychologistId: psychologistId,
                psychologistName: psychologistData.fullName || 'Psicólogo desconocido',
                psychologistSpecialty: psychologistData.specialty || 'Psicología General',
                psychologistProfileUrl: psychologistData.profilePictureUrl || null,
                scheduledDateTime: appointmentDate,
                durationMinutes: 60,
                type,
                status: isSchedulingForOtherPatient ? 'confirmed' : 'pending',
                price: psychologistData.price || 100.0,
                amount: psychologistData.price || 100.0, 
                patientNotes: notes || null,
                isPaid: isPremiumUser,
                paymentType: isPremiumUser ? 'subscription' : 'pending',
                stripeSessionId: null,
                scheduledBy: authenticatedUserId,
                paidToPsychologist: false,
                psychologistPaymentId: null,
                psychologistPaidAt: null,
                createdAt: FieldValue.serverTimestamp(),
                updatedAt: FieldValue.serverTimestamp()
            };

            const appointmentRef = db.collection('appointments').doc();
            appointmentId = appointmentRef.id;
            transaction.set(appointmentRef, appointmentData);

            // Crear notificaciones
            const patientNotificationRef = db.collection('notifications').doc();
            transaction.set(patientNotificationRef, {
                userId: finalPatientId,
                title: '¡Cita Agendada!',
                body: `Tienes una nueva cita con el psicólogo ${psychologistData.fullName}.`,
                type: 'appointment_created',
                isRead: false,
                timestamp: FieldValue.serverTimestamp(),
                data: {
                    appointmentId: appointmentId,
                    psychologistId: psychologistId,
                    psychologistName: psychologistData.fullName,
                    status: appointmentData.status
                }
            });

            const psychologistNotificationRef = db.collection('notifications').doc();
            let psychologistNotificationBody;
            if (isSchedulingForOtherPatient) {
                psychologistNotificationBody = `Has agendado una cita con el paciente ${patientData.username}.`;
            } else {
                psychologistNotificationBody = `Un paciente ha agendado una cita contigo.`;
            }

            transaction.set(psychologistNotificationRef, {
                userId: psychologistId,
                title: 'Nueva Cita',
                body: psychologistNotificationBody,
                type: 'appointment_created',
                isRead: false,
                timestamp: FieldValue.serverTimestamp(),
                data: {
                    appointmentId: appointmentId,
                    patientId: finalPatientId,
                    patientName: patientData.username,
                    status: appointmentData.status
                }
            });
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

        res.status(201).json({
            message: 'Cita creada exitosamente',
            appointment: responseData
        });

    } catch (error) {
        console.error(' Error al crear cita:', error);
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


router.get('/available-slots/:psychologistId', verifyFirebaseToken, async (req, res) => {
    try {
        const { psychologistId } = req.params;
        const { startDate, endDate } = req.query;

        if (!startDate || !endDate) {
            return res.status(400).json({ error: 'startDate y endDate son requeridos (YYYY-MM-DD)' });
        }

        const start = new Date(startDate + 'T00:00:00Z');
        const end = new Date(endDate + 'T23:59:59Z');
        const now = new Date();

        if (isNaN(start) || isNaN(end) || start > end) {
            return res.status(400).json({ error: 'Rango de fechas inválido' });
        }

        const adjustedStart = start < now ? now : start;
        if (end < now) {
            return res.status(200).json({ availableSlots: [] });
        }

        // Obtener datos del psicólogo
        const psychologistDoc = await db.collection('psychologists').doc(psychologistId).get();
        if (!psychologistDoc.exists) {
            return res.status(404).json({ error: 'Psicólogo no encontrado' });
        }

        const psychologistData = psychologistDoc.data();
        const schedule = psychologistData.schedule || {};
        const appointmentsSnapshot = await db.collection('appointments')
            .where('psychologistId', '==', psychologistId)
            .where('status', 'in', ['pending', 'confirmed', 'in_progress'])
            .get();
        const occupiedSlots = new Set();
        const startTimestamp = adjustedStart.getTime();
        const endTimestamp = end.getTime();

        appointmentsSnapshot.forEach(doc => {
            const data = doc.data();
            const appointmentTime = data.scheduledDateTime.toDate();

            // Filtrar solo las citas dentro del rango solicitado
            const appointmentTimestamp = appointmentTime.getTime();
            if (appointmentTimestamp < startTimestamp || appointmentTimestamp > endTimestamp) {
                return; // Skip esta cita
            }
            const year = appointmentTime.getFullYear();
            const month = String(appointmentTime.getMonth() + 1).padStart(2, '0');
            const day = String(appointmentTime.getDate()).padStart(2, '0');
            const hour = String(appointmentTime.getHours()).padStart(2, '0');

            const slotKey = `${year}-${month}-${day}-${hour}`;
            occupiedSlots.add(slotKey);
        });

        const availableSlots = [];

        const dayMap = {
            'Sunday': 'Domingo',
            'Monday': 'Lunes',
            'Tuesday': 'Martes',
            'Wednesday': 'Miércoles',
            'Thursday': 'Jueves',
            'Friday': 'Viernes',
            'Saturday': 'Sábado'
        };
        const daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

        for (let d = new Date(adjustedStart); d <= end; d.setUTCDate(d.getUTCDate() + 1)) {
            const currentDate = new Date(d);
            const dayName = daysOfWeek[currentDate.getUTCDay()];
            const dayNameInSpanish = dayMap[dayName];
            const daySchedule = schedule[dayNameInSpanish];

            if (!daySchedule || !daySchedule.startTime || !daySchedule.endTime) {
                console.log(`No hay horario definido o está incompleto para ${dayNameInSpanish}. Saltando.`);
                continue; 
            }
 
            const [startH, startM] = daySchedule.startTime.split(':').map(Number);
            const [endH, endM] = daySchedule.endTime.split(':').map(Number);
            const scheduleStartInMins = startH * 60 + startM;
            const scheduleEndInMins = endH * 60 + endM;

            // Iterar por cada hora del día
            for (let hour = 0; hour < 24; hour++) {
                const slotDateTime = new Date(
                    currentDate.getUTCFullYear(),
                    currentDate.getUTCMonth(),
                    currentDate.getUTCDate(),
                    hour, 0, 0
                );

                const slotStartInMins = hour * 60;
                const slotEndInMins = (hour + 1) * 60;
                
                // Verificar si está dentro del horario del psicólogo
                const isRegisteredAvailable =
                    slotStartInMins >= scheduleStartInMins &&
                    slotEndInMins <= scheduleEndInMins;

                if (!isRegisteredAvailable) {
                    continue;
                }

                const year = slotDateTime.getFullYear();
                const month = String(slotDateTime.getMonth() + 1).padStart(2, '0');
                const day = String(slotDateTime.getDate()).padStart(2, '0');
                const slotHour = String(slotDateTime.getHours()).padStart(2, '0');
                const slotKey = `${year}-${month}-${day}-${slotHour}`;
                
                const isOccupied = occupiedSlots.has(slotKey);
                
                // Verificar si es hora pasada
                const isPast = slotDateTime <= now;
                
                // El slot está disponible si no está ocupado Y no es pasado
                const isAvailable = !isOccupied && !isPast;

                if (isAvailable) {
                    const slotDateTimeUTC = new Date(Date.UTC(
                        currentDate.getUTCFullYear(),
                        currentDate.getUTCMonth(),
                        currentDate.getUTCDate(),
                        hour, 0, 0
                    ));
                    
                    availableSlots.push({
                        time: `${hour.toString().padStart(2, '0')}:00`,
                        dateTime: slotDateTimeUTC.toISOString(),
                        isAvailable: true,
                        reason: null
                    });
                } else {
                    const reason = isPast ? 'Hora pasada' : 'Ocupado';
                    console.log(`Slot NO disponible: ${slotKey} - Razón: ${reason}`);
                }
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

//Confirmar una cita
router.patch('/:id/confirm', verifyFirebaseToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { psychologistNotes, meetingLink } = req.body;
        const authenticatedUserId = req.firebaseUser.uid;

        const appointmentRef = db.collection('appointments').doc(id);
        const appointmentDoc = await appointmentRef.get();
        if (!appointmentDoc.exists) {
            return res.status(404).json({ error: 'Cita no encontrada' });
        }

        const appointmentData = appointmentDoc.data();
        if (appointmentData.psychologistId !== authenticatedUserId) {
            return res.status(403).json({ error: 'Acceso denegado' });
        }

        if (appointmentData.status !== 'pending') {
            return res.status(400).json({ error: 'Solo se pueden confirmar citas pendientes' });
        }

        await appointmentRef.update({
            status: 'confirmed',
            confirmedAt: FieldValue.serverTimestamp(),
            psychologistNotes: psychologistNotes || null,
            meetingLink: meetingLink || null,
            updatedAt: FieldValue.serverTimestamp(),
        });

        // Notificación para el paciente 
        await createNotification({
            userId: appointmentData.patientId,
            title: '¡Cita Confirmada!',
            body: `Tu cita con el psicólogo ${appointmentData.psychologistName} ha sido confirmada.`,
            type: 'appointment_confirmed',
            data: {
                appointmentId: id,
                psychologistId: appointmentData.psychologistId,
                status: 'confirmed'
            }
        });


        res.status(200).json({ message: 'Cita confirmada exitosamente' });

    } catch (error) {
        console.error('Error al confirmar cita:', error);
        res.status(500).json({ error: 'Error al confirmar la cita', details: error.message });
    }
});

// Cancelar una cita
router.patch('/:id/cancel', verifyFirebaseToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;
        const authenticatedUserId = req.firebaseUser.uid;
        const appointmentRef = db.collection('appointments').doc(id);
        const appointmentDoc = await appointmentRef.get();

        if (!appointmentDoc.exists) {
            return res.status(404).json({ error: 'Cita no encontrada' });
        }

        const appointmentData = appointmentDoc.data();

        if (!appointmentData.patientId || !appointmentData.psychologistId) {
            console.error(' ERROR: La cita no tiene patientId o psychologistId');
            return res.status(500).json({
                error: 'Datos de la cita incompletos. No se puede determinar el destinatario.'
            });
        }

        // Verificar permisos
        if (appointmentData.patientId !== authenticatedUserId &&
            appointmentData.psychologistId !== authenticatedUserId) {
            return res.status(403).json({ error: 'Acceso denegado' });
        }

        // Verificar estado
        if (['cancelled', 'completed', 'rated'].includes(appointmentData.status)) {
            console.error('Estado inválido para cancelación:', appointmentData.status);
            return res.status(400).json({
                error: 'La cita ya ha sido cancelada, completada o calificada'
            });
        }

        // Actualizar cita
        await appointmentRef.update({
            status: 'cancelled',
            cancellationReason: reason || 'Sin motivo especificado',
            cancelledBy: authenticatedUserId, 
            cancelledAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
        });


        let recipientId;
        let recipientName;
        let notificationTitle = 'Cita Cancelada';
        let notificationBody = '';

        if (authenticatedUserId === appointmentData.patientId) {
            // El paciente canceló, notificar al psicólogo
            recipientId = appointmentData.psychologistId;
            recipientName = appointmentData.psychologistName || 'el psicólogo';

            const formattedDate = appointmentData.scheduledDateTime?.toDate
                ? new Date(appointmentData.scheduledDateTime.toDate()).toLocaleDateString('es-MX', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                })
                : 'fecha desconocida';

            notificationBody = `El paciente ${appointmentData.patientName || 'un paciente'} ha cancelado la cita del ${formattedDate}.`;


        } else {
            // El psicólogo canceló, notificar al paciente
            recipientId = appointmentData.patientId;
            recipientName = appointmentData.patientName || 'el paciente';

            const formattedDate = appointmentData.scheduledDateTime?.toDate
                ? new Date(appointmentData.scheduledDateTime.toDate()).toLocaleDateString('es-MX', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                })
                : 'fecha desconocida';

            notificationBody = `El psicólogo ${appointmentData.psychologistName || 'el psicólogo'} ha cancelado tu cita del ${formattedDate}.`;
        }

        if (!recipientId || recipientId === 'undefined' || recipientId === '') {
            console.error(' ERROR CRÍTICO: recipientId es inválido:', recipientId);
            console.error('Datos completos de la cita:', JSON.stringify(appointmentData, null, 2));

            // Aún así, marcamos la cita como cancelada, pero sin notificación
            return res.status(200).json({
                message: 'Cita cancelada exitosamente (sin notificación por datos faltantes)',
                appointmentId: id,
                status: 'cancelled',
                warning: 'No se pudo enviar la notificación por datos incompletos'
            });
        }

        // Crear notificación
        try {

            await createNotification({
                userId: recipientId,
                title: notificationTitle,
                body: notificationBody,
                type: 'appointment_cancelled',
                data: {
                    appointmentId: id,
                    psychologistId: appointmentData.psychologistId || '',
                    patientId: appointmentData.patientId || '',
                    status: 'cancelled',
                    reason: reason || 'Sin motivo especificado',
                    cancelledBy: authenticatedUserId
                }
            });


        } catch (notifError) {
            console.error(' Error al crear notificación (no crítico):', notifError.message);
            // No retornamos error aquí, la cita ya fue cancelada exitosamente
        }

        res.status(200).json({
            message: 'Cita cancelada exitosamente',
            appointmentId: id,
            status: 'cancelled'
        });

    } catch (error) {
        console.error('Error al cancelar cita:', error);
        res.status(500).json({
            error: 'Error al cancelar la cita',
            details: error.message
        });
    }
});

// Iniciar una sesión
router.patch('/:id/start-session', verifyFirebaseToken, async (req, res) => {
    try {
        const { id } = req.params;
        const psychologistId = req.firebaseUser.uid; 

        const appointmentRef = db.collection('appointments').doc(id);
        const doc = await appointmentRef.get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'Cita no encontrada.' });
        }

        const appointmentData = doc.data();

        if (appointmentData.psychologistId !== psychologistId) {
            return res.status(403).json({ error: 'Solo el psicólogo asignado puede iniciar la sesión.' });
        }

        if (appointmentData.status !== 'confirmed') {
            return res.status(400).json({ error: 'La sesión solo se puede iniciar si está en estado "confirmed".' });
        }
        const patientId = appointmentData.patientId;
        const sessionLink = appointmentData.meetingLink || appointmentData.sessionLink || 'No se proporcionó un enlace.';
        await appointmentRef.update({
            status: 'in_progress',
            sessionStartTime: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
        });
        const chatId = getChatId(psychologistId, patientId);
        const chatContent = `¡Tu sesión de terapia ha comenzado! Únete ahora a través del enlace: ${sessionLink}`;

        await sendSystemChatMessage(
            chatId, 
            psychologistId, 
            patientId, 
            chatContent
        );

        await createNotification({
            userId: patientId,
            title: '¡Sesión Iniciada!',
            body: `Tu sesión ha comenzado. Revisa tu chat con el psicólogo para el enlace.`,
            type: 'session_started',
            data: {
                appointmentId: id,
                sessionLink: sessionLink,
                status: 'in_progress'
            }
        });


        res.status(200).json({ message: 'Sesión iniciada exitosamente.' }); 

    } catch (error) {
        console.error('Error al iniciar la sesión:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            details: error.message
        });
    }
});

// Completar una sesión (por psicólogo)
router.patch('/:id/complete-session', verifyFirebaseToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { notes } = req.body;
        const authenticatedUserId = req.firebaseUser.uid;

        const appointmentRef = db.collection('appointments').doc(id);
        const appointmentDoc = await appointmentRef.get();
        if (!appointmentDoc.exists) {
            return res.status(404).json({ error: 'Cita no encontrada' });
        }

        const appointmentData = appointmentDoc.data();
        if (appointmentData.psychologistId !== authenticatedUserId) {
            return res.status(403).json({ error: 'Acceso denegado' });
        }

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

        // --- Notificación para el paciente---
        await createNotification({
            userId: appointmentData.patientId,
            title: 'Sesión Completada',
            body: `Tu sesión con el psicólogo ${appointmentData.psychologistName} ha finalizado. ¡Comparte tu experiencia!`,
            type: 'session_completed',
            data: {
                appointmentId: id,
                psychologistId: appointmentData.psychologistId,
                status: 'completed'
            }
        });


        res.status(200).json({ message: 'Sesión completada exitosamente' });

    } catch (error) {
        console.error('Error al completar sesión:', error);
        res.status(500).json({ error: 'Error al completar la sesión', details: error.message });
    }
});

//  Calificar una cita
router.patch('/:id/rate', verifyFirebaseToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { rating, comment } = req.body;
        const authenticatedUserId = req.firebaseUser.uid;

        const appointmentRef = db.collection('appointments').doc(id);
        const appointmentDoc = await appointmentRef.get();
        if (!appointmentDoc.exists) {
            return res.status(404).json({ error: 'Cita no encontrada' });
        }

        const appointmentData = appointmentDoc.data();
        // Verificar que el usuario es el paciente
        if (appointmentData.patientId !== authenticatedUserId) {
            return res.status(403).json({ error: 'Acceso denegado' });
        }
        // Verificar que la cita está completada y no calificada
        if (appointmentData.status !== 'completed') {
            return res.status(400).json({ error: 'Solo se pueden calificar citas completadas' });
        }
        if (appointmentData.rating !== undefined) {
            return res.status(400).json({ error: 'Esta cita ya ha sido calificada' });
        }

        const updateData = {
            status: 'rated',
            rating: rating,
            ratingComment: comment || null,
            ratedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
        };

        await appointmentRef.update(updateData);

        // --- Notificación para el psicólogo---
        await createNotification({
            userId: appointmentData.psychologistId,
            title: 'Nueva Calificación',
            body: `¡El paciente ${appointmentData.patientName} ha calificado su sesión!`,
            type: 'session_rated',
            data: {
                appointmentId: id,
                patientId: appointmentData.patientId,
                patientName: appointmentData.patientName,

            }
        });


        res.status(200).json({ message: 'Cita calificada exitosamente' });

    } catch (error) {
        console.error('Error al calificar cita:', error);
        res.status(500).json({ error: 'Error al calificar la cita', details: error.message });
    }
});


// Obtener rating promedio de un psicólogo
router.get('/psychologist-rating/:psychologistId', async (req, res) => {
    try {
        const { psychologistId } = req.params;

        // Obtener todas las citas calificadas del psicólogo
        const ratedAppointmentsSnapshot = await db.collection('appointments')
            .where('psychologistId', '==', psychologistId)
            .where('status', '==', 'rated')
            .where('rating', '>', 0)
            .get();

        if (ratedAppointmentsSnapshot.empty) {
            return res.status(200).json({
                psychologistId,
                averageRating: 0,
                totalRatings: 0,
                ratingDistribution: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 }
            });
        }

        let totalRating = 0;
        let totalRatings = 0;
        const ratingDistribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };

        ratedAppointmentsSnapshot.forEach(doc => {
            const appointmentData = doc.data();
            const rating = appointmentData.rating;

            if (rating && rating >= 1 && rating <= 5) {
                totalRating += rating;
                totalRatings++;
                ratingDistribution[rating]++;
            }
        });

        const averageRating = totalRatings > 0 ? (totalRating / totalRatings) : 0;

        res.status(200).json({
            psychologistId,
            averageRating: Math.round(averageRating * 10) / 10,
            totalRatings,
            ratingDistribution
        });

    } catch (error) {
        console.error('Error al obtener rating del psicólogo:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            details: error.message
        });
    }
});

// Obtener ratings de múltiples psicólogos
router.post('/psychologists-ratings', async (req, res) => {
    try {
        const { psychologistIds } = req.body;

        if (!Array.isArray(psychologistIds) || psychologistIds.length === 0) {
            return res.status(400).json({ error: 'Se requiere un array de IDs de psicólogos' });
        }

        const ratingsPromises = psychologistIds.map(async (psychologistId) => {
            try {
                const ratedAppointmentsSnapshot = await db.collection('appointments')
                    .where('psychologistId', '==', psychologistId)
                    .where('status', '==', 'rated')
                    .where('rating', '>', 0)
                    .get();

                if (ratedAppointmentsSnapshot.empty) {
                    return {
                        psychologistId,
                        averageRating: 0,
                        totalRatings: 0
                    };
                }

                let totalRating = 0;
                let totalRatings = 0;

                ratedAppointmentsSnapshot.forEach(doc => {
                    const appointmentData = doc.data();
                    const rating = appointmentData.rating;

                    if (rating && rating >= 1 && rating <= 5) {
                        totalRating += rating;
                        totalRatings++;
                    }
                });

                const averageRating = totalRatings > 0 ? (totalRating / totalRatings) : 0;

                return {
                    psychologistId,
                    averageRating: Math.round(averageRating * 10) / 10,
                    totalRatings
                };
            } catch (error) {
                console.error(`Error al obtener rating para psicólogo ${psychologistId}:`, error);
                return {
                    psychologistId,
                    averageRating: 0,
                    totalRatings: 0,
                    error: error.message
                };
            }
        });

        const ratings = await Promise.all(ratingsPromises);

        res.status(200).json({ ratings });

    } catch (error) {
        console.error('Error al obtener ratings de psicólogos:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            details: error.message
        });
    }
});

router.patch('/:appointmentId/complete-session', async (req, res) => {
    try {
        const { appointmentId } = req.params;
        const { notes } = req.body;
        const authenticatedUserId = req.firebaseUser.uid;

        // 1. Obtener datos de la cita
        const appointmentRef = db.collection('appointments').doc(appointmentId);
        const appointmentDoc = await appointmentRef.get();

        if (!appointmentDoc.exists) {
            return res.status(404).json({ error: 'Cita no encontrada' });
        }

        const appointmentData = appointmentDoc.data();
        if (appointmentData.psychologistId !== authenticatedUserId) {
            return res.status(403).json({ error: 'Acceso no autorizado para completar la sesión' });
        }

        const patientId = appointmentData.patientId;
        const patientRef = db.collection('patients').doc(patientId);
        const patientDoc = await patientRef.get();

        // 2. Actualizar la cita
        await appointmentRef.update({
            status: 'completed',
            sessionNotes: notes,
            completedAt: FieldValue.serverTimestamp(),
        });

        if (patientDoc.exists) {
            const patientData = patientDoc.data();
            const updates = {

                totalSessions: FieldValue.increment(1),

                lastAppointment: appointmentData.scheduledDateTime.toDate ? appointmentData.scheduledDateTime.toDate() : new Date(appointmentData.scheduledDateTime),
                updatedAt: FieldValue.serverTimestamp(),
            };

            const currentStatus = patientData.status;
            const preTreatmentStatuses = ['pending', 'accepted'];
            if (!currentStatus || preTreatmentStatuses.includes(currentStatus)) {
                updates.status = 'inTreatment';
            }

            await patientRef.update(updates);

        } else {
            console.warn(`Paciente ${patientId} no encontrado en la colección 'patients'. No se pudo actualizar el estado.`);
        }

        res.status(200).json({
            message: 'Sesión completada y estado del paciente actualizado con éxito.'
        });

    } catch (error) {
        console.error('Error al completar la sesión:', error);
        res.status(500).json({
            error: 'Error interno del servidor al completar la sesión',
            details: error.message
        });
    }
});

/**
 * Middleware para verificar admin (puedes adaptarlo según tu sistema de roles)
 */
async function verifyAdmin(req, res, next) {
    try {
        const userId = req.firebaseUser.uid;

        // Opción 1: Verificar custom claims
        const userRecord = await auth.getUser(userId);
        if (userRecord.customClaims?.admin === true) {
            return next();
        }

        // Opción 2: Verificar en colección de usuarios
        const psychologistDoc = await db.collection('psychologists').doc(userId).get();
        if (psychologistDoc.exists && psychologistDoc.data().role === 'admin') {
            return next();
        }

        return res.status(403).json({
            error: 'Acceso denegado. Solo administradores pueden ejecutar esta acción.'
        });

    } catch (error) {
        console.error('Error verificando admin:', error);
        res.status(500).json({ error: 'Error de autenticación' });
    }
}

//Obtener estadísticas de citas que serían eliminadas

router.get('/cleanup/stats', verifyFirebaseToken, verifyAdmin, async (req, res) => {
    try {
        const stats = await getCleanupStats();

        res.status(200).json({
            message: 'Estadísticas de limpieza obtenidas exitosamente',
            ...stats
        });

    } catch (error) {
        console.error('Error obteniendo estadísticas:', error);
        res.status(500).json({
            error: 'Error al obtener estadísticas',
            details: error.message
        });
    }
});

// Ejecutar limpieza manual (solo admin)

router.post('/cleanup/execute', verifyFirebaseToken, verifyAdmin, async (req, res) => {
    try {
        const result = await cleanupOldAppointments();

        if (result.success) {
            res.status(200).json({
                message: 'Limpieza ejecutada exitosamente',
                deletedCount: result.deletedCount,
                timestamp: result.timestamp
            });
        } else {
            res.status(500).json({
                error: 'Error durante la limpieza',
                details: result.error
            });
        }

    } catch (error) {
        console.error('Error ejecutando limpieza manual:', error);
        res.status(500).json({
            error: 'Error al ejecutar limpieza',
            details: error.message
        });
    }
});


router.post('/cleanup/custom', verifyFirebaseToken, verifyAdmin, async (req, res) => {
    try {
        const { days } = req.body;

        if (!days || days < 1) {
            return res.status(400).json({
                error: 'Se requiere el parámetro "days" con un valor mayor a 0'
            });
        }

        const result = await cleanupAppointmentsOlderThan(days);

        res.status(200).json({
            message: `Limpieza ejecutada exitosamente para citas mayores a ${days} días`,
            deletedCount: result.deletedCount,
            days: result.days
        });

    } catch (error) {
        console.error('Error ejecutando limpieza personalizada:', error);
        res.status(500).json({
            error: 'Error al ejecutar limpieza personalizada',
            details: error.message
        });
    }
});


// Obtener todas las reseñas de un psicólogo con detalles
router.get('/psychologist-reviews/:psychologistId', async (req, res) => {
    try {
        const { psychologistId } = req.params;
        const ratedAppointmentsSnapshot = await db.collection('appointments')
            .where('psychologistId', '==', psychologistId)
            .where('status', '==', 'rated')
            .where('rating', '>', 0)
            .orderBy('rating', 'desc')
            .orderBy('ratedAt', 'desc')
            .get();

        if (ratedAppointmentsSnapshot.empty) {
            return res.status(200).json({
                psychologistId,
                reviews: [],
                totalReviews: 0
            });
        }

        const reviewsPromises = ratedAppointmentsSnapshot.docs.map(async (doc) => {
            const appointmentData = doc.data();
            const patientId = appointmentData.patientId;
            let profile_picture_url = appointmentData.profile_picture_url || null;
            let patientName = appointmentData.patientName || 'Usuario';

            try {
                const patientDoc = await db.collection('patients')
                    .doc(patientId)
                    .get();

                if (patientDoc.exists) {
                    const patientData = patientDoc.data();

                    profile_picture_url = patientData.profile_picture_url ||
                        patientData.profileImageUrl ||
                        patientData.photoURL ||
                        null;

                    if (patientData.username) {
                        patientName = patientData.username;
                    }
                } else {
                    console.log(`Documento del paciente no encontrado: ${patientId}`);
                }
            } catch (error) {
                console.log(`Error obteniendo info del paciente ${patientId}:`, error.message);
            }

            return {
                id: doc.id,
                patientId: patientId,
                patientName: patientName,
                profile_picture_url: profile_picture_url,
                rating: appointmentData.rating,
                ratingComment: appointmentData.ratingComment || null,
                ratedAt: appointmentData.ratedAt?.toDate()?.toISOString() || null,
                scheduledDateTime: appointmentData.scheduledDateTime?.toDate()?.toISOString() || null,
            };
        });

        const reviews = await Promise.all(reviewsPromises);

        res.status(200).json({
            psychologistId,
            reviews,
            totalReviews: reviews.length
        });

    } catch (error) {
        res.status(500).json({
            error: 'Error interno del servidor',
            details: error.message
        });
    }
});

export default router;