// services/appointmentsCleanup.js

import cron from 'node-cron';
import { db } from '../../firebase-admin.js';
import { FieldValue } from 'firebase-admin/firestore';

export async function cleanupOldAppointments() {
  try {
    // Calcular fecha límite (30 días)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const deletableStatuses = ['completed', 'cancelled', 'rated', 'refunded'];
    
    let totalDeleted = 0;
    const batchSize = 500; 

    for (const status of deletableStatuses) {

      const snapshot = await db.collection('appointments')
        .where('status', '==', status)
        .where('updatedAt', '<', thirtyDaysAgo)
        .limit(batchSize)
        .get();

      const batch = db.batch();
      
      snapshot.docs.forEach((doc) => {
        const data = doc.data();
        const scheduledDate = data.scheduledDateTime?.toDate 
          ? data.scheduledDateTime.toDate() 
          : new Date(data.scheduledDateTime);

        batch.delete(doc.ref);
      });

      // Ejecutar eliminación
      await batch.commit();
      totalDeleted += snapshot.size;
    }
    return {
      success: true,
      deletedCount: totalDeleted,
      timestamp: new Date().toISOString()
    };

  } catch (error) {
    return {
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    };
  }
}

// Obtener estadísticas de limpieza sin ejecutar la eliminación
export async function getCleanupStats() {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const deletableStatuses = ['completed', 'cancelled', 'rated', 'refunded'];
    const stats = {};

    for (const status of deletableStatuses) {
      const snapshot = await db.collection('appointments')
        .where('status', '==', status)
        .where('updatedAt', '<', thirtyDaysAgo)
        .get();

      stats[status] = snapshot.size;
    }

    const total = Object.values(stats).reduce((sum, count) => sum + count, 0);

    return {
      cutoffDate: thirtyDaysAgo.toISOString(),
      statusBreakdown: stats,
      totalToDelete: total
    };

  } catch (error) {
    console.error('Error obteniendo estadísticas de limpieza:', error);
    throw error;
  }
}

// Programar tarea de limpieza diaria a las 2:00 AM
export function scheduleCleanupTask() {
  // Formato cron: segundo minuto hora día mes día-semana
  // '0 2 * * *' = Todos los días a las 2:00 AM
  cron.schedule('0 2 * * *', async () => {
    const result = await cleanupOldAppointments();
  }, {
    timezone: "America/Mexico_City"
  });
}


export async function cleanupAppointmentsOlderThan(days) {
  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);
    
    const deletableStatuses = ['completed', 'cancelled', 'rated', 'refunded'];
    let totalDeleted = 0;

    for (const status of deletableStatuses) {
      const snapshot = await db.collection('appointments')
        .where('status', '==', status)
        .where('updatedAt', '<', cutoffDate)
        .limit(500)
        .get();

      if (!snapshot.empty) {
        const batch = db.batch();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
        await batch.commit();
        totalDeleted += snapshot.size;
      }
    }

    return {
      success: true,
      deletedCount: totalDeleted,
      days: days
    };

  } catch (error) {
    console.error('Error en limpieza por edad:', error);
    throw error;
  }
}
 