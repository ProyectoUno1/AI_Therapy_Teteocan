// backend/routes/patient_management.js
import express from 'express';
import { db } from '../firebase-admin.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { FieldValue } from 'firebase-admin/firestore';

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

        let status = 'pending'; 
        
        if (patientData.status) {
          status = patientData.status;
        } else {
          const hasPending = appointments.some(apt => apt.status === 'pending');
          const hasConfirmed = appointments.some(apt =>
            apt.status === 'confirmed' && new Date(apt.scheduledDateTime) > new Date());
          const hasInProgress = appointments.some(apt => apt.status === 'in_progress');

          if (completedSessions > 0) {
            const lastAptDate = lastAppointment ? new Date(lastAppointment.scheduledDateTime) : null;
            
            if (lastAptDate && (new Date() - lastAptDate) / (1000 * 60 * 60 * 24) > 30) {
              status = 'completed';
            } else {
              status = 'inTreatment';
            }
          } else if (hasConfirmed || hasInProgress) {
            status = 'inTreatment';
          } else if (hasPending) {
            status = 'pending';
          }
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
          totalSessions: patientData.totalSessions || completedSessions, 
          isActive: status !== 'completed' && status !== 'cancelled',
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

// Guardar o actualizar emoción del paciente
router.post('/emotions', verifyFirebaseToken, async (req, res) => {
  try {
    const { uid, patientId, feeling, note, date, intensity, metadata } = req.body;

    // Validar campos requeridos
    if (!patientId || !feeling || !date) {
      return res.status(400).json({
        error: 'Campos requeridos: patientId, feeling, date'
      });
    }

    // Convertir fecha recibida
    const emotionDate = new Date(date);
    const startOfDay = new Date(emotionDate);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(emotionDate);
    endOfDay.setHours(23, 59, 59, 999);

    // Verificar si ya existe una emoción para este día
    const existingEmotion = await db.collection('emotions')
      .where('patientId', '==', patientId)
      .where('date', '>=', startOfDay)
      .where('date', '<=', endOfDay)
      .get();

    let emotionId;
    let action = 'updated';

    if (!existingEmotion.empty) {
      // Actualizar emoción existente
      emotionId = existingEmotion.docs[0].id;
      await db.collection('emotions').doc(emotionId).update({
        feeling,
        note: note || null,
        intensity: intensity || 5,
        metadata: metadata || {},
        updatedAt: new Date()
      });
      action = 'updated';
    } else {
      // Crear nueva emoción
      const emotionRef = db.collection('emotions').doc();
      emotionId = emotionRef.id;

      const emotionData = {
        id: emotionId,
        patientId,
        feeling,
        note: note || null,
        intensity: intensity || 5,
        metadata: metadata || {},
        date: emotionDate,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      await emotionRef.set(emotionData);
      action = 'created';
    }

    res.json({
      success: true,
      emotionId,
      action,
      message: `Emoción ${action} correctamente`
    });
  } catch (error) {
    console.error('Error en saveEmotion:', error);
    res.status(500).json({
      error: 'Error al guardar la emoción',
      details: error.message
    });
  }
});

// Obtener emociones del paciente
router.get('/patients/:patientId/emotions', verifyFirebaseToken, async (req, res) => {
  try {
    const { patientId } = req.params;
    const { start, end } = req.query;


    let query = db.collection('emotions')
      .where('patientId', '==', patientId)
      .orderBy('date', 'desc');

    if (start && end) {
      const startDate = new Date(start);
      const endDate = new Date(end);

      query = query.where('date', '>=', startDate)
        .where('date', '<=', endDate);
    }

    const snapshot = await query.get();
    const emotions = snapshot.docs.map(doc => {
      const data = doc.data();
      const emotion = {
        id: data.id,
        patientId: data.patientId,
        feeling: data.feeling,
        note: data.note,
        intensity: data.intensity,
        metadata: data.metadata,
        date: data.date.toDate ? data.date.toDate().toISOString() : new Date(data.date).toISOString(),
        createdAt: data.createdAt.toDate ? data.createdAt.toDate().toISOString() : new Date(data.createdAt).toISOString(),
        updatedAt: data.updatedAt.toDate ? data.updatedAt.toDate().toISOString() : new Date(data.updatedAt).toISOString()
      };
      return emotion;
    });


    res.json(emotions);
  } catch (error) {
    console.error('Error en getPatientEmotions:', error);
    res.status(500).json({
      error: 'Error al obtener las emociones',
      details: error.message
    });
  }
});

// Obtener emoción del día actual 
router.get('/patients/:patientId/emotions/today', verifyFirebaseToken, async (req, res) => {
  try {
    const { patientId } = req.params;

    const today = new Date();
    const startOfDay = new Date(today);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(today);
    endOfDay.setHours(23, 59, 59, 999);

    const snapshot = await db.collection('emotions')
      .where('patientId', '==', patientId)
      .where('date', '>=', startOfDay)
      .where('date', '<=', endOfDay)
      .get();

    if (snapshot.empty) {
      return res.json(null);
    }

    const emotionDoc = snapshot.docs[0];
    const emotionData = emotionDoc.data();

    const emotion = {
      id: emotionData.id,
      patientId: emotionData.patientId,
      feeling: emotionData.feeling,
      note: emotionData.note,
      intensity: emotionData.intensity,
      metadata: emotionData.metadata,
      date: emotionData.date.toDate ? emotionData.date.toDate().toISOString() : new Date(emotionData.date).toISOString(),
      createdAt: emotionData.createdAt.toDate ? emotionData.createdAt.toDate().toISOString() : new Date(emotionData.createdAt).toISOString(),
      updatedAt: emotionData.updatedAt.toDate ? emotionData.updatedAt.toDate().toISOString() : new Date(emotionData.updatedAt).toISOString()
    };

    res.json(emotion);
  } catch (error) {
    console.error('Error en getTodayEmotion:', error);
    res.status(500).json({
      error: 'Error al obtener la emoción del día',
      details: error.message
    });
  }
});
// Guardar sentimientos y notas de ejercicios
router.post('/exercise-feelings', verifyFirebaseToken, async (req, res) => {
  try {
    const {
      patientId,
      exerciseTitle,
      exerciseDuration,
      exerciseDifficulty,
      feeling,
      intensity,
      notes,
      completedAt,
      metadata
    } = req.body;

    if (!patientId || !exerciseTitle || !feeling) {
      return res.status(400).json({
        error: 'Campos requeridos: patientId, exerciseTitle, feeling'
      });
    }

    const exerciseFeelingRef = db.collection('exercise_feelings').doc();
    const exerciseFeelingId = exerciseFeelingRef.id;

    const exerciseFeelingData = {
      id: exerciseFeelingId,
      patientId,
      exerciseTitle,
      exerciseDuration: exerciseDuration || 0,
      exerciseDifficulty: exerciseDifficulty || 'No especificado',
      feeling,
      intensity: intensity || 5,
      notes: notes || '',
      completedAt: completedAt ? new Date(completedAt) : new Date(),
      metadata: metadata || {},
      createdAt: new Date(),
      updatedAt: new Date()
    };

    await exerciseFeelingRef.set(exerciseFeelingData);

    const activityRef = db.collection('patient_activities').doc();
    const activityData = {
      id: activityRef.id,
      patientId,
      activityType: 'exercise_completed',
      activityTitle: `Ejercicio completado: ${exerciseTitle}`,
      data: {
        exerciseTitle,
        exerciseDuration,
        exerciseDifficulty,
        feeling,
        intensity,
        hasNotes: !!notes
      },
      timestamp: new Date(),
      createdAt: new Date()
    };

    await activityRef.set(activityData);

    res.status(201).json({
      success: true,
      exerciseFeelingId,
      message: 'Sentimientos del ejercicio guardados correctamente'
    });
  } catch (error) {
    console.error('Error al guardar sentimientos del ejercicio:', error);
    res.status(500).json({
      error: 'Error al guardar los sentimientos del ejercicio',
      details: error.message
    });
  }
});

// Obtener historial de ejercicios completados por un paciente
router.get('/patients/:patientId/exercise-history', verifyFirebaseToken, async (req, res) => {
  try {
    const { patientId } = req.params;
    const { limit = 50, startAfter } = req.query;

    let query = db.collection('exercise_feelings')
      .where('patientId', '==', patientId)
      .orderBy('completedAt', 'desc')
      .limit(parseInt(limit));

    if (startAfter) {
      const startAfterDoc = await db.collection('exercise_feelings').doc(startAfter).get();
      if (startAfterDoc.exists) {
        query = query.startAfter(startAfterDoc);
      }
    }

    const snapshot = await query.get();
    const exerciseHistory = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: data.id,
        patientId: data.patientId,
        exerciseTitle: data.exerciseTitle,
        exerciseDuration: data.exerciseDuration,
        exerciseDifficulty: data.exerciseDifficulty,
        feeling: data.feeling,
        intensity: data.intensity,
        notes: data.notes,
        completedAt: data.completedAt.toDate ? data.completedAt.toDate().toISOString() : new Date(data.completedAt).toISOString(),
        metadata: data.metadata,
        createdAt: data.createdAt.toDate ? data.createdAt.toDate().toISOString() : new Date(data.createdAt).toISOString(),
        updatedAt: data.updatedAt.toDate ? data.updatedAt.toDate().toISOString() : new Date(data.updatedAt).toISOString()
      };
    });

    res.json({
      exerciseHistory,
      hasMore: snapshot.docs.length === parseInt(limit)
    });
  } catch (error) {
    console.error('Error al obtener historial de ejercicios:', error);
    res.status(500).json({
      error: 'Error al obtener el historial de ejercicios',
      details: error.message
    });
  }
});

// Obtener estadísticas de ejercicios de un paciente
router.get('/patients/:patientId/exercise-stats', verifyFirebaseToken, async (req, res) => {
  try {
    const { patientId } = req.params;
    const { period = '30' } = req.query; // días

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(period));

    const snapshot = await db.collection('exercise_feelings')
      .where('patientId', '==', patientId)
      .where('completedAt', '>=', startDate)
      .get();

    const exercises = snapshot.docs.map(doc => doc.data());

    // Calcular estadísticas
    const totalExercises = exercises.length;
    const exerciseTypes = {};
    const feelingsCount = {};
    let totalDuration = 0;
    let totalIntensity = 0;

    exercises.forEach(exercise => {
      // Contar tipos de ejercicios
      exerciseTypes[exercise.exerciseTitle] = (exerciseTypes[exercise.exerciseTitle] || 0) + 1;

      // Contar sentimientos
      feelingsCount[exercise.feeling] = (feelingsCount[exercise.feeling] || 0) + 1;

      // Sumar duración e intensidad
      totalDuration += exercise.exerciseDuration || 0;
      totalIntensity += exercise.intensity || 0;
    });

    const averageIntensity = totalExercises > 0 ? (totalIntensity / totalExercises).toFixed(1) : 0;
    const mostCommonFeeling = Object.keys(feelingsCount).reduce((a, b) =>
      feelingsCount[a] > feelingsCount[b] ? a : b, Object.keys(feelingsCount)[0] || 'No registrado'
    );

    const stats = {
      period: parseInt(period),
      totalExercises,
      totalDuration,
      averageIntensity: parseFloat(averageIntensity),
      mostCommonFeeling,
      exerciseTypes,
      feelingsDistribution: feelingsCount,
      exercisesPerDay: (totalExercises / parseInt(period)).toFixed(1)
    };

    res.json(stats);
  } catch (error) {
    console.error('Error al obtener estadísticas de ejercicios:', error);
    res.status(500).json({
      error: 'Error al obtener estadísticas de ejercicios',
      details: error.message
    });
  }
});

// Obtener ejercicios completados hoy
router.get('/patients/:patientId/exercise-feelings/today', verifyFirebaseToken, async (req, res) => {
  try {
    const { patientId } = req.params;

    const today = new Date();
    const startOfDay = new Date(today);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(today);
    endOfDay.setHours(23, 59, 59, 999);

    const snapshot = await db.collection('exercise_feelings')
      .where('patientId', '==', patientId)
      .where('completedAt', '>=', startOfDay)
      .where('completedAt', '<=', endOfDay)
      .orderBy('completedAt', 'desc')
      .get();

    const todayExercises = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: data.id,
        patientId: data.patientId,
        exerciseTitle: data.exerciseTitle,
        exerciseDuration: data.exerciseDuration,
        exerciseDifficulty: data.exerciseDifficulty,
        feeling: data.feeling,
        intensity: data.intensity,
        notes: data.notes,
        completedAt: data.completedAt.toDate ? data.completedAt.toDate().toISOString() : new Date(data.completedAt).toISOString(),
        metadata: data.metadata,
        createdAt: data.createdAt.toDate ? data.createdAt.toDate().toISOString() : new Date(data.createdAt).toISOString()
      };
    });

    res.json(todayExercises);
  } catch (error) {
    console.error('Error al obtener ejercicios de hoy:', error);
    res.status(500).json({
      error: 'Error al obtener los ejercicios de hoy',
      details: error.message
    });
  }
});

router.post('/notes', verifyFirebaseToken, async (req, res) => {
  try {
    const { patientId, title, content } = req.body;
    const psychologistId = req.firebaseUser.uid;

    // Validación
    if (!patientId || !title || !content) {
      return res.status(400).json({
        error: 'patientId, title y content son requeridos'
      });
    }

    const newNoteRef = db.collection('patient_notes').doc();
    const newNoteData = {
      id: newNoteRef.id,
      patientId: patientId,
      psychologistId: psychologistId,
      title: title,
      content: content,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    // Guardar en Firestore
    await newNoteRef.set(newNoteData);

    // Responder con éxito
    res.status(201).json({
      message: 'Nota guardada con éxito',
      noteId: newNoteRef.id,
      note: {
        id: newNoteRef.id,
        patientId: patientId,
        psychologistId: psychologistId,
        title: title,
        content: content,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      }
    });

  } catch (error) {
    console.error('Error al guardar la nota:', error);
    res.status(500).json({
      error: 'Error interno del servidor al guardar la nota',
      details: error.message
    });
  }
});

//Obtener notas del paciente
router.get('/patients/:patientId/notes', verifyFirebaseToken, async (req, res) => {
  try {
    const { patientId } = req.params;

    const notesSnapshot = await db.collection('patient_notes')
      .where('patientId', '==', patientId)
      .orderBy('createdAt', 'desc')
      .get();

    const notes = notesSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: data.id,
        patientId: data.patientId,
        psychologistId: data.psychologistId,
        title: data.title,
        content: data.content,
        createdAt: data.createdAt.toDate ? data.createdAt.toDate().toISOString() : new Date(data.createdAt).toISOString(),
        updatedAt: data.updatedAt.toDate ? data.updatedAt.toDate().toISOString() : new Date(data.updatedAt).toISOString(),
      };
    });

    res.json(notes);
  } catch (error) {
    console.error('Error al obtener notas:', error);
    res.status(500).json({
      error: 'Error al obtener las notas',
      details: error.message
    });
  }
});

// Actualizar una nota existente
router.put('/notes/:noteId', verifyFirebaseToken, async (req, res) => {
  try {
    const { noteId } = req.params;
    const { title, content } = req.body;
    const psychologistId = req.firebaseUser.uid;

    if (!title || !content) {
      return res.status(400).json({
        error: 'title y content son requeridos'
      });
    }

    const noteRef = db.collection('patient_notes').doc(noteId);
    const noteDoc = await noteRef.get();

    if (!noteDoc.exists) {
      return res.status(404).json({ error: 'Nota no encontrada' });
    }

    const noteData = noteDoc.data();
    if (noteData.psychologistId !== psychologistId) {
      return res.status(403).json({ error: 'No autorizado para editar esta nota' });
    }

    // Actualizar la nota
    await noteRef.update({
      title: title,
      content: content,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Obtener la nota actualizada
    const updatedDoc = await noteRef.get();
    const updatedData = updatedDoc.data();

    res.json({
      message: 'Nota actualizada con éxito',
      note: {
        id: updatedData.id,
        patientId: updatedData.patientId,
        psychologistId: updatedData.psychologistId,
        title: updatedData.title,
        content: updatedData.content,
        createdAt: updatedData.createdAt.toDate().toISOString(),
        updatedAt: updatedData.updatedAt.toDate().toISOString(),
      }
    });
  } catch (error) {
    console.error('Error al actualizar nota:', error);
    res.status(500).json({
      error: 'Error al actualizar la nota',
      details: error.message
    });
  }
});

// Eliminar una nota
router.delete('/notes/:noteId', verifyFirebaseToken, async (req, res) => {
  try {
    const { noteId } = req.params;
    const psychologistId = req.firebaseUser.uid;

    // Verificar que la nota existe y pertenece al psicólogo
    const noteRef = db.collection('patient_notes').doc(noteId);
    const noteDoc = await noteRef.get();

    if (!noteDoc.exists) {
      return res.status(404).json({ error: 'Nota no encontrada' });
    }

    const noteData = noteDoc.data();
    if (noteData.psychologistId !== psychologistId) {
      return res.status(403).json({ error: 'No autorizado para eliminar esta nota' });
    }

    // Eliminar la nota
    await noteRef.delete();

    res.json({
      message: 'Nota eliminada con éxito',
      noteId: noteId
    });
  } catch (error) {
    console.error('Error al eliminar nota:', error);
    res.status(500).json({
      error: 'Error al eliminar la nota',
      details: error.message
    });
  }
});

// Marcar paciente como completado
router.patch('/patients/:patientId/complete', verifyFirebaseToken, async (req, res) => {
  try {
    const { patientId } = req.params;
    const { finalNotes } = req.body;
    const psychologistId = req.firebaseUser.uid;
    const patientRef = db.collection('patients').doc(patientId);
    const patientDoc = await patientRef.get();

    if (!patientDoc.exists) {
      return res.status(404).json({ error: 'Paciente no encontrado' });
    }

    const appointmentsSnapshot = await db.collection('appointments')
      .where('patientId', '==', patientId)
      .where('psychologistId', '==', psychologistId)
      .where('status', 'in', ['completed', 'rated'])
      .get();

    if (appointmentsSnapshot.empty) {
      return res.status(403).json({ 
        error: 'No tienes autorización para completar este paciente' 
      });
    }

    // Actualizar el estado del paciente
    const updateData = {
      status: 'completed',
      completedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (finalNotes && finalNotes.trim() !== '') {
      updateData.finalNotes = finalNotes;
    }

    await patientRef.update(updateData);

    // Crear notificación para el paciente
    const notificationRef = db.collection('notifications').doc();
    await notificationRef.set({
      userId: patientId,
      title: '¡Tratamiento Completado!',
      body: 'Has completado exitosamente tu tratamiento. ¡Felicidades por tu progreso!',
      type: 'treatment_completed',
      isRead: false,
      timestamp: FieldValue.serverTimestamp(),
      data: {
        psychologistId: psychologistId,
        totalSessions: appointmentsSnapshot.size,
      }
    });

    res.status(200).json({
      message: 'Paciente marcado como completado exitosamente',
      patientId: patientId,
      totalSessions: appointmentsSnapshot.size,
    });

  } catch (error) {
    console.error('Error al completar paciente:', error);
    res.status(500).json({
      error: 'Error al completar el paciente',
      details: error.message
    });
  }
});


export default router;