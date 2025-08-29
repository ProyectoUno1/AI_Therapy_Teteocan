// routes/admin/psychologistValidation.js
import express from 'express';
import { db } from '../../firebase-admin.js';
import { verifyFirebaseToken, isAdmin } from '../middlewares/auth_middleware.js';
import { FieldValue } from 'firebase-admin/firestore';

const router = express.Router();

// Validar/Rechazar psicólogo por admin
router.patch('/:psychologistId/validate', verifyFirebaseToken, isAdmin, async (req, res) => {
  try {
    const { psychologistId } = req.params;
    const { status, adminNotes } = req.body;
    const adminId = req.firebaseUser.uid;

    // Validar estados permitidos
    const allowedStatuses = ['Activo', 'Rechazado', 'Inactivo'];
    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({ error: 'Estado no válido' });
    }

    const updateData = {
      status,
      adminNotes: adminNotes || '',
      validatedAt: FieldValue.serverTimestamp(),
      validatedBy: adminId,
      updatedAt: FieldValue.serverTimestamp()
    };

    await db.collection('psychologists').doc(psychologistId).update(updateData);

    res.status(200).json({ 
      message: `Psicólogo ${status.toLowerCase()} exitosamente`,
      psychologistId 
    });
  } catch (error) {
    console.error('Error en validación administrativa:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Obtener todos los psicólogos para admin
router.get('/', verifyFirebaseToken, isAdmin, async (req, res) => {
  try {
    const { status } = req.query;
    
    let query = db.collection('psychologists');
    if (status) {
      query = query.where('status', '==', status);
    }

    const snapshot = await query.orderBy('createdAt', 'desc').get();
    const psychologists = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.status(200).json(psychologists);
  } catch (error) {
    console.error('Error obteniendo psicólogos:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

export default router;