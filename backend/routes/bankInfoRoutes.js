// backend/routes/bankInfoRoutes.js

import express from 'express';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';
import { db } from '../firebase-admin.js';
import admin from 'firebase-admin';

const router = express.Router();

/**
 * GET /api/bank-info/:psychologistId
 * Obtiene la información bancaria de un psicólogo
 */
router.get('/bank-info/:psychologistId', verifyFirebaseToken, async (req, res) => {
    try {
        const { psychologistId } = req.params;

        // Verificar que el usuario autenticado sea el mismo psicólogo o un admin
        if (req.userId !== psychologistId && !req.isAdmin) {
            return res.status(403).json({ 
                error: 'No tienes permisos para acceder a esta información' 
            });
        }

        // Buscar información bancaria
        const bankInfoDoc = await db.collection('bank_info')
            .doc(psychologistId)
            .get();

        if (!bankInfoDoc.exists) {
            return res.status(404).json({ 
                error: 'No se encontró información bancaria',
                bankInfo: null 
            });
        }

        res.json({ 
            success: true,
            bankInfo: {
                id: bankInfoDoc.id,
                ...bankInfoDoc.data()
            }
        });

    } catch (error) {
        console.error('Error obteniendo información bancaria:', error);
        res.status(500).json({ 
            error: 'Error interno del servidor',
            details: error.message 
        });
    }
});

//Guarda nueva información bancaria
router.post('/bank-info', verifyFirebaseToken, async (req, res) => {
    try {
        const {
            psychologistId,
            accountHolderName,
            bankName,
            accountType,
            accountNumber,
            clabe,
            isInternational,
            swiftCode
        } = req.body;

        // Validar que el usuario sea el mismo psicólogo
        if (req.userId !== psychologistId && !req.isAdmin) {
            return res.status(403).json({ 
                error: 'No tienes permisos para realizar esta acción' 
            });
        }

        // Validaciones
        if (!accountHolderName || !bankName || !accountNumber || !clabe) {
            return res.status(400).json({ 
                error: 'Faltan campos requeridos' 
            });
        }

        if (clabe.length !== 18) {
            return res.status(400).json({ 
                error: 'La CLABE debe tener exactamente 18 dígitos' 
            });
        }

        if (isInternational && !swiftCode) {
            return res.status(400).json({ 
                error: 'El código SWIFT es requerido para cuentas internacionales' 
            });
        }

        // Verificar si ya existe información bancaria
        const existingDoc = await db.collection('bank_info')
            .doc(psychologistId)
            .get();

        if (existingDoc.exists) {
            return res.status(409).json({ 
                error: 'Ya existe información bancaria. Usa PUT para actualizar.' 
            });
        }

        // Crear información bancaria
        const bankInfoData = {
            psychologistId,
            accountHolderName: accountHolderName.trim(),
            bankName: bankName.trim(),
            accountType,
            accountNumber: accountNumber.trim(),
            clabe: clabe.trim(),
            isInternational: isInternational || false,
            swiftCode: isInternational ? swiftCode?.trim() : null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        await db.collection('bank_info')
            .doc(psychologistId)
            .set(bankInfoData);

        res.status(201).json({
            success: true,
            message: 'Información bancaria guardada correctamente',
            bankInfo: {
                id: psychologistId,
                ...bankInfoData
            }
        });

    } catch (error) {
        console.error('Error guardando información bancaria:', error);
        res.status(500).json({ 
            error: 'Error interno del servidor',
            details: error.message 
        });
    }
});

/**
 * PUT /api/bank-info/:psychologistId
 * Actualiza información bancaria existente
 */
router.put('/bank-info/:psychologistId', verifyFirebaseToken, async (req, res) => {
    try {
        const { psychologistId } = req.params;
        const {
            accountHolderName,
            bankName,
            accountType,
            accountNumber,
            clabe,
            isInternational,
            swiftCode
        } = req.body;

        // Validar permisos
        if (req.userId !== psychologistId && !req.isAdmin) {
            return res.status(403).json({ 
                error: 'No tienes permisos para realizar esta acción' 
            });
        }

        // Validaciones
        if (clabe && clabe.length !== 18) {
            return res.status(400).json({ 
                error: 'La CLABE debe tener exactamente 18 dígitos' 
            });
        }

        // Verificar que existe
        const bankInfoRef = db.collection('bank_info').doc(psychologistId);
        const bankInfoDoc = await bankInfoRef.get();

        if (!bankInfoDoc.exists) {
            return res.status(404).json({ 
                error: 'No se encontró información bancaria. Usa POST para crear.' 
            });
        }

        // Actualizar
        const updateData = {
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        if (accountHolderName) updateData.accountHolderName = accountHolderName.trim();
        if (bankName) updateData.bankName = bankName.trim();
        if (accountType) updateData.accountType = accountType;
        if (accountNumber) updateData.accountNumber = accountNumber.trim();
        if (clabe) updateData.clabe = clabe.trim();
        if (isInternational !== undefined) updateData.isInternational = isInternational;
        if (swiftCode) updateData.swiftCode = swiftCode.trim();

        await bankInfoRef.update(updateData);

        const updatedDoc = await bankInfoRef.get();

        res.json({
            success: true,
            message: 'Información bancaria actualizada correctamente',
            bankInfo: {
                id: psychologistId,
                ...updatedDoc.data()
            }
        });

    } catch (error) {
        console.error('Error actualizando información bancaria:', error);
        res.status(500).json({ 
            error: 'Error interno del servidor',
            details: error.message 
        });
    }
});

/**
 * GET /api/payments/:psychologistId
 * Obtiene el historial de pagos de un psicólogo
 */
router.get('/payments/:psychologistId', verifyFirebaseToken, async (req, res) => {
    try {
        const { psychologistId } = req.params;
        const { status } = req.query;

        // Validar permisos
        if (req.userId !== psychologistId && !req.isAdmin) {
            return res.status(403).json({ 
                error: 'No tienes permisos para acceder a esta información' 
            });
        }

        // Construir query
        let query = db.collection('payments')
            .where('psychologistId', '==', psychologistId);

        if (status && status !== 'all') {
            query = query.where('status', '==', status);
        }

        const paymentsSnapshot = await query
            .orderBy('date', 'desc')
            .get();

        const payments = paymentsSnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data(),
            date: doc.data().date?.toDate?.()?.toISOString() || new Date().toISOString()
        }));

        // Calcular totales
        let totalEarned = 0;
        let pendingAmount = 0;

        payments.forEach(payment => {
            if (payment.status === 'completed') {
                totalEarned += payment.amount || 0;
            } else if (payment.status === 'pending') {
                pendingAmount += payment.amount || 0;
            }
        });

        res.json({
            success: true,
            payments,
            summary: {
                totalEarned,
                pendingAmount,
                totalPayments: payments.length
            }
        });

    } catch (error) {
        console.error('Error obteniendo historial de pagos:', error);
        res.status(500).json({ 
            error: 'Error interno del servidor',
            details: error.message 
        });
    }
});

/**
 * DELETE /api/bank-info/:psychologistId
 * Elimina información bancaria (solo admin o el mismo psicólogo)
 */
router.delete('/bank-info/:psychologistId', verifyFirebaseToken, async (req, res) => {
    try {
        const { psychologistId } = req.params;

        // Validar permisos
        if (req.userId !== psychologistId && !req.isAdmin) {
            return res.status(403).json({ 
                error: 'No tienes permisos para realizar esta acción' 
            });
        }

        await db.collection('bank_info').doc(psychologistId).delete();

        res.json({
            success: true,
            message: 'Información bancaria eliminada correctamente'
        });

    } catch (error) {
        console.error('Error eliminando información bancaria:', error);
        res.status(500).json({ 
            error: 'Error interno del servidor',
            details: error.message 
        });
    }
});

export default router;