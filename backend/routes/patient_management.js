// backend/routes/patient_management.js
import express from 'express';
import { db } from '../firebase-admin.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';

const router = express.Router();

// Obtener pacientes de un psicólogo
router.get('/psychologist/:psychologistId', verifyFirebaseToken, async (req, res) => {
  try {
    const { psychologistId } = req.params;
    
    // Verificar que el usuario autenticado es el psicólogo
    if (req.firebaseUser.uid !== psychologistId) {
      return res.status(403).json({ error: 'Acceso no autorizado' });
    }

    // Obtener todas las citas del psicólogo
    const appointmentsSnapshot = await db.collection('appointments')
      .where('psychologistId', '==', psychologistId)
      .orderBy('scheduledDateTime', 'desc')
      .get();

    if (appointmentsSnapshot.empty) {
      return res.status(200).json({ patients: [] });
    }

    // Agrupar citas por paciente
    const patientAppointments = {};
    appointmentsSnapshot.forEach(doc => {
      const appointment = doc.data();
      const patientId = appointment.patientId;
      
      if (!patientAppointments[patientId]) {
        patientAppointments[patientId] = [];
      }
      
      patientAppointments[patientId].push({
        id: doc.id,
        ...appointment,
        scheduledDateTime: appointment.scheduledDateTime.toDate().toISOString(),
        createdAt: appointment.createdAt.toDate().toISOString(),
        updatedAt: appointment.updatedAt.toDate().toISOString(),
        confirmedAt: appointment.confirmedAt ? appointment.confirmedAt.toDate().toISOString() : null,
        cancelledAt: appointment.cancelledAt ? appointment.cancelledAt.toDate().toISOString() : null,
        completedAt: appointment.completedAt ? appointment.completedAt.toDate().toISOString() : null,
        ratedAt: appointment.ratedAt ? appointment.ratedAt.toDate().toISOString() : null,
        sessionStartedAt: appointment.sessionStartedAt ? appointment.sessionStartedAt.toDate().toISOString() : null,
      });
    });

    // Obtener información adicional de cada paciente
    const patients = [];
    for (const patientId in patientAppointments) {
      try {
        const patientDoc = await db.collection('patients').doc(patientId).get();
        let patientData = {};
        
        if (patientDoc.exists) {
          patientData = patientDoc.data();
        }
        
        const appointments = patientAppointments[patientId];
        
        // Calcular estadísticas del paciente
        const completedSessions = appointments.filter(apt => 
          apt.status === 'completed' || apt.status === 'rated').length;
        
        const nextAppointment = appointments.find(apt => 
          apt.status === 'confirmed' && 
          new Date(apt.scheduledDateTime) > new Date());
        
        const lastAppointment = appointments.find(apt => 
          apt.status === 'completed' || apt.status === 'rated');
        
        // Determinar estado del paciente
        let status = 'pending';
        const hasPending = appointments.some(apt => apt.status === 'pending');
        const hasConfirmed = appointments.some(apt => 
          apt.status === 'confirmed' && new Date(apt.scheduledDateTime) > new Date());
        const hasInProgress = appointments.some(apt => apt.status === 'in_progress');
        
        if (hasInProgress || hasConfirmed) {
          status = 'in_treatment';
        } else if (completedSessions > 0) {
          const lastAptDate = lastAppointment ? new Date(lastAppointment.scheduledDateTime) : null;
          if (lastAptDate && (new Date() - lastAptDate) / (1000 * 60 * 60 * 24) > 30) {
            status = 'completed';
          } else {
            status = 'in_treatment';
          }
        } else if (hasPending) {
          status = 'pending';
        }
        
        patients.push({
          id: patientId,
          name: patientData.username || appointments[0].patientName,
          email: patientData.email || appointments[0].patientEmail,
          phoneNumber: patientData.phone_number || null,
          dateOfBirth: patientData.date_of_birth || null,
          profilePictureUrl: patientData.profile_picture_url || appointments[0].patientProfileUrl || null,
          createdAt: patientData.created_at ? patientData.created_at.toDate().toISOString() : appointments[0].createdAt,
          updatedAt: patientData.updated_at ? patientData.updated_at.toDate().toISOString() : appointments[0].updatedAt,
          status,
          notes: `Historial: ${completedSessions} sesiones completadas`,
          lastAppointment: lastAppointment ? lastAppointment.scheduledDateTime : null,
          nextAppointment: nextAppointment ? nextAppointment.scheduledDateTime : null,
          totalSessions: completedSessions,
          isActive: hasPending || hasConfirmed || hasInProgress,
          contactMethod: 'appointment'
        });
      } catch (error) {
        console.error(`Error procesando paciente ${patientId}:`, error);
      }
    }

    res.status(200).json({ patients });
  } catch (error) {
    console.error('Error al obtener pacientes:', error);
    res.status(500).json({ 
      error: 'Error interno del servidor', 
      details: error.message 
    });
  }
});

export default router;