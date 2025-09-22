import dotenv from "dotenv";
import express from "express";
import { FieldValue } from 'firebase-admin/firestore';
import stripe from "stripe";
import { db } from '../firebase-admin.js';
import { createNotification } from './notifications.js'; 

dotenv.config();

const stripeClient = stripe(process.env.STRIPE_SECRET_KEY);
const stripeRouter = express.Router();

stripeRouter.use('/stripe-webhook', express.raw({ type: 'application/json' }));

// Endpoint para crear la sesión de checkout
stripeRouter.post("/create-checkout-session", async (req, res) => {
  const { planId, userEmail, userId, userName, planName } = req.body;

  if (!planId || !userEmail || !userId) {
    return res.status(400).json({
      error: "planId, userEmail, and userId are required."
    });
  }

  try {
    console.log(`Creando sesión de checkout para usuario: ${userEmail} (${userId})`);

    // Verificar si ya tiene suscripción activa 
    const userDoc = await db.collection('patients').doc(userId).get();
    if (userDoc.exists && userDoc.data().isPremium) {
      return res.status(400).json({
        error: "El usuario ya tiene una suscripción activa"
      });
    }

    // Buscar o crear cliente de Stripe con email del usuario autenticado
    let customer;
    const existingCustomers = await stripeClient.customers.list({
      email: userEmail,
      limit: 1
    });

    if (existingCustomers.data.length > 0) {
      customer = existingCustomers.data[0];
      console.log(`Cliente existente encontrado: ${customer.id}`);

      // Actualizar datos del cliente si es necesario
      if (userName && (!customer.name || customer.name !== userName)) {
        customer = await stripeClient.customers.update(customer.id, {
          name: userName,
          metadata: {
            firebase_uid: userId,
            updated_at: new Date().toISOString()
          }
        });
        console.log(`Cliente actualizado con nombre: ${userName}`);
      }
    } else {
      // Crear nuevo cliente con datos completos
      customer = await stripeClient.customers.create({
        email: userEmail,
        name: userName || 'Usuario',
        metadata: {
          firebase_uid: userId,
          created_from: 'mobile_app',
          created_at: new Date().toISOString()
        }
      });
      console.log(`Nuevo cliente creado: ${customer.id}`);
    }

    // Crear sesión de checkout con metadatos completos
    const session = await stripeClient.checkout.sessions.create({
      payment_method_types: ['card'],
      mode: 'subscription',
      line_items: [{
        price: planId,
        quantity: 1,
      }],
      customer: customer.id,
      client_reference_id: userId,
      metadata: {
        firebase_uid: userId,
        user_email: userEmail,
        user_name: userName || 'Usuario',
        plan_id: planId,
        plan_name: planName || 'Premium',
        source: 'mobile_app'
      },
      success_url: 'auroraapp://success?session_id={CHECKOUT_SESSION_ID}',
      cancel_url: 'auroraapp://cancel',
      // Configuraciones adicionales para mejor UX
      billing_address_collection: 'auto',
      customer_update: {
        address: 'auto',
        name: 'auto'
      },
      // Personalización del checkout
      custom_text: {
        submit: {
          message: 'Tu suscripción se activará inmediatamente después del pago.'
        }
      }
    });

    console.log(`Sesión de checkout creada: ${session.id}`);
    res.json({
      checkoutUrl: session.url,
      sessionId: session.id
    });

  } catch (e) {
    console.error("Error al crear la sesión de Checkout:", e);
    res.status(500).json({
      error: e.message,
      details: process.env.NODE_ENV === 'development' ? e.stack : undefined
    });
  }
});

// Endpoint para verificar el estado de una sesión
stripeRouter.post("/verify-session", async (req, res) => {
  const { sessionId } = req.body;

  if (!sessionId) {
    return res.status(400).json({ error: "sessionId is required" });
  }

  try {
    console.log(`Verificando sesión: ${sessionId}`);

    // Obtener sesión con datos expandidos
    const session = await stripeClient.checkout.sessions.retrieve(sessionId, {
      expand: ['subscription', 'customer']
    });

    console.log(`Estado de sesión ${sessionId}: ${session.payment_status}`);

    if (session.payment_status === 'paid' && session.status === 'complete') {
      const metadata = session.metadata;
      const userId = metadata?.firebase_uid || session.client_reference_id;

      if (userId) {
        try {
          // ACTUALIZAR DATOS DEL USUARIO EN FIREBASE 
          await db.collection('patients').doc(userId).set({
            isPremium: true,
            subscriptionId: session.subscription?.id || session.subscription,
            stripeCustomerId: session.customer?.id || session.customer,
            subscriptionStartDate: FieldValue.serverTimestamp(),
            lastPaymentDate: FieldValue.serverTimestamp(),
            email: metadata?.user_email || session.customer?.email,
            name: metadata?.user_name,
            planId: metadata?.plan_id,
            planName: metadata?.plan_name,
          }, { merge: true });

          // CREAR REGISTRO DE SUSCRIPCIÓN EN COLECCIÓN DEDICADA
          await db.collection('subscriptions').doc(session.subscription?.id || session.subscription).set({
            userId: userId,
            userName: metadata?.user_name,
            userEmail: metadata?.user_email,
            customerId: session.customer?.id || session.customer,
            planId: metadata?.plan_id,
            planName: metadata?.plan_name,
            status: 'active',
            amountTotal: session.amount_total,
            currency: session.currency,
            checkoutSessionId: session.id,
            metadata: session.metadata,
            createdAt: FieldValue.serverTimestamp(),
          }, { merge: true });

          // CREAR NOTIFICACIÓN DE SUSCRIPCIÓN ACTIVADA
          await createNotification({
            userId: userId,
            title: '¡Suscripción Activada!',
            body: `¡Felicidades! Tu plan ${metadata?.plan_name || 'Premium'} ha sido activado con éxito.`,
            type: 'subscription_activated',
            data: {
              subscriptionId: session.subscription?.id || session.subscription,
              planName: metadata?.plan_name || 'Premium',
              planId: metadata?.plan_id,
              amountPaid: session.amount_total,
              currency: session.currency
            }
          });

          console.log(`Suscripción registrada/actualizada para usuario ${userId} a través de /verify-session`);
        } catch (firebaseError) {
          console.error(`Error al actualizar Firebase desde /verify-session:`, firebaseError);
        }
      }
    }

    // Respuesta más completa
    res.json({
      paymentStatus: session.payment_status,
      sessionStatus: session.status,
      subscriptionId: session.subscription?.id || session.subscription,
      subscriptionStatus: session.subscription?.status,
      customerId: session.customer?.id || session.customer,
      customerEmail: session.customer_details?.email || session.customer?.email,
      amountTotal: session.amount_total,
      currency: session.currency,
      metadata: session.metadata
    });
  } catch (error) {
    console.error("Error verificando sesión:", error);
    res.status(500).json({
      error: "Error al verificar la sesión",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Endpoint para cancelar suscripción
stripeRouter.post("/cancel-subscription", async (req, res) => {
  const { subscriptionId, immediate = false } = req.body;

  if (!subscriptionId) {
    return res.status(400).json({ error: "subscriptionId is required" });
  }

  try {
    // Buscar el usuario asociado a esta suscripción ANTES de cancelar
    const subscriptionDoc = await db.collection('subscriptions').doc(subscriptionId).get();
    let userId = null;
    let userName = 'Usuario';
    let planName = 'Premium';

    if (subscriptionDoc.exists) {
      const subscriptionData = subscriptionDoc.data();
      userId = subscriptionData.userId;
      userName = subscriptionData.userName || 'Usuario';
      planName = subscriptionData.planName || 'Premium';
    }

    // Cancelar en Stripe
    let canceledSubscription;

    if (immediate) {
      canceledSubscription = await stripeClient.subscriptions.cancel(subscriptionId);
    } else {
      canceledSubscription = await stripeClient.subscriptions.update(subscriptionId, {
        cancel_at_period_end: true,
        metadata: {
          canceled_by: 'user',
          canceled_from: 'mobile_app',
          canceled_at: new Date().toISOString()
        }
      });
    }

    console.log(`Suscripción ${subscriptionId} ${immediate ? 'cancelada inmediatamente' : 'programada para cancelar'}`);

    if (userId) {
      // Actualizar estado del usuario
      await db.collection('patients').doc(userId).update({
        isPremium: immediate ? false : true, // Si es inmediata, quitar premium
        subscriptionStatus: immediate ? 'canceled' : 'pending_cancelation',
        subscriptionCanceledAt: FieldValue.serverTimestamp()
      });

      // CREAR NOTIFICACIÓN DE CANCELACIÓN
      if (immediate) {
        await createNotification({
          userId: userId,
          title: 'Suscripción Cancelada',
          body: `Tu suscripción ${planName} ha sido cancelada inmediatamente.`,
          type: 'subscription_canceled',
          data: {
            subscriptionId: subscriptionId,
            planName: planName,
            cancelationType: 'immediate',
            canceledAt: new Date().toISOString()
          }
        });
      } else {
        const periodEnd = new Date(canceledSubscription.current_period_end * 1000);
        await createNotification({
          userId: userId,
          title: 'Suscripción Programada para Cancelar',
          body: `Tu suscripción ${planName} se cancelará al final del período actual (${periodEnd.toLocaleDateString()}).`,
          type: 'subscription_cancel_scheduled',
          data: {
            subscriptionId: subscriptionId,
            planName: planName,
            cancelationType: 'end_of_period',
            currentPeriodEnd: periodEnd.toISOString()
          }
        });
      }
    }

    res.json({
      success: true,
      message: immediate ?
        'Suscripción cancelada inmediatamente' :
        'Suscripción se cancelará al final del período actual',
      subscription: {
        id: subscriptionId,
        status: canceledSubscription.status,
        cancelAtPeriodEnd: canceledSubscription.cancel_at_period_end,
        currentPeriodEnd: new Date(canceledSubscription.current_period_end * 1000)
      }
    });

  } catch (error) {
    console.error("Error cancelando suscripción:", error);
    res.status(500).json({
      error: "Error al cancelar suscripción",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Endpoint para crear pago único de sesión con psicólogo
stripeRouter.post("/create-psychology-session", async (req, res) => {
  const {
    userEmail,
    userId,
    userName,
    sessionDate,
    sessionTime,
    psychologistName,
    sessionNotes
  } = req.body;

  if (!userEmail || !userId) {
    return res.status(400).json({
      error: "userEmail y userId son requeridos."
    });
  }

  try {
    // Verificar si el usuario existe en Firebase
    const userDoc = await db.collection('patients').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({
        error: "Usuario no encontrado"
      });
    }

    // Buscar o crear cliente de Stripe
    let customer;
    const existingCustomers = await stripeClient.customers.list({
      email: userEmail,
      limit: 1
    });

    if (existingCustomers.data.length > 0) {
      customer = existingCustomers.data[0];
      console.log(`Cliente existente encontrado: ${customer.id}`);

      // Actualizar datos del cliente si es necesario
      if (userName && (!customer.name || customer.name !== userName)) {
        customer = await stripeClient.customers.update(customer.id, {
          name: userName,
          metadata: {
            firebase_uid: userId,
            updated_at: new Date().toISOString()
          }
        });
        console.log(`Cliente actualizado con nombre: ${userName}`);
      }
    } else {
      // Crear nuevo cliente
      customer = await stripeClient.customers.create({
        email: userEmail,
        name: userName || 'Usuario',
        metadata: {
          firebase_uid: userId,
          created_from: 'mobile_app',
          created_at: new Date().toISOString()
        }
      });
      console.log(`Nuevo cliente creado: ${customer.id}`);
    }

    // Crear sesión de checkout para pago único
    const session = await stripeClient.checkout.sessions.create({
      payment_method_types: ['card'],
      mode: 'payment', // Pago único, no suscripción
      line_items: [{
        price: 'price_1S3nsW2Szsvtfc49V6wCPoSp',  
        quantity: 1,
      }],
      customer: customer.id,
      client_reference_id: userId,
      metadata: {
        firebase_uid: userId,
        user_email: userEmail,
        user_name: userName || 'Usuario',
        session_type: 'psychology_session',
        session_date: sessionDate || '',
        session_time: sessionTime || '',
        psychologist_name: psychologistName || '',
        session_notes: sessionNotes || '',
        source: 'mobile_app',
        created_at: new Date().toISOString()
      },
      success_url: 'auroraapp://psychology-session-success?session_id={CHECKOUT_SESSION_ID}',
      cancel_url: 'auroraapp://psychology-session-cancel',
      billing_address_collection: 'auto',
      customer_update: {
        address: 'auto',
        name: 'auto'
      },
      custom_text: {
        submit: {
          message: 'Tu sesión con psicólogo será confirmada después del pago exitoso.'
        }
      },
      // Configuración específica para sesiones de psicología
      invoice_creation: {
        enabled: true,
        invoice_data: {
          description: `Sesión con psicólogo${psychologistName ? ' - ' + psychologistName : ''}${sessionDate ? ' para ' + sessionDate : ''}`,
          metadata: {
            session_type: 'psychology_session',
            user_id: userId,
            session_date: sessionDate || '',
            psychologist: psychologistName || ''
          }
        }
      }
    });

    // Crear registro preliminar en Firebase
    const sessionRef = await db.collection('psychology_sessions').add({
      userId: userId,
      userEmail: userEmail,
      userName: userName || 'Usuario',
      checkoutSessionId: session.id,
      stripeCustomerId: customer.id,
      sessionDate: sessionDate || null,
      sessionTime: sessionTime || null,
      psychologistName: psychologistName || '',
      sessionNotes: sessionNotes || '',
      paymentStatus: 'pending',
      sessionStatus: 'scheduled',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });

    res.json({
      checkoutUrl: session.url,
      sessionId: session.id,
      psychologySessionId: sessionRef.id,
      message: "Sesión de psicólogo creada exitosamente"
    });

  } catch (error) {
    console.error("Error al crear sesión con psicólogo:", error);
    res.status(500).json({
      error: error.message,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// Endpoint para verificar el estado de una sesión de psicólogo
stripeRouter.post("/verify-psychology-session", async (req, res) => {
  const { sessionId } = req.body;

  if (!sessionId) {
    return res.status(400).json({ error: "sessionId is required" });
  }

  try {
    console.log(`Verificando sesión de psicólogo: ${sessionId}`);

    // Obtener sesión con datos expandidos
    const session = await stripeClient.checkout.sessions.retrieve(sessionId, {
      expand: ['customer', 'payment_intent']
    });

    console.log(`Estado de sesión ${sessionId}: ${session.payment_status}`);

    if (session.payment_status === 'paid' && session.status === 'complete') {
      const metadata = session.metadata;
      const userId = metadata?.firebase_uid || session.client_reference_id;

      if (userId && metadata?.session_type === 'psychology_session') {
        try {
          // Buscar y actualizar el registro de la sesión de psicología
          const psychologySessionsQuery = await db.collection('psychology_sessions')
            .where('checkoutSessionId', '==', sessionId)
            .limit(1)
            .get();

          if (!psychologySessionsQuery.empty) {
            const psychologySessionDoc = psychologySessionsQuery.docs[0];

            // Actualizar registro de sesión
            await psychologySessionDoc.ref.update({
              paymentStatus: 'paid',
              sessionStatus: 'confirmed',
              paymentIntentId: session.payment_intent?.id || session.payment_intent,
              amountPaid: session.amount_total,
              currency: session.currency,
              paidAt: FieldValue.serverTimestamp(),
              updatedAt: FieldValue.serverTimestamp()
            });

            // Crear registro de pago específico
            await db.collection('psychology_payments').add({
              userId: userId,
              userEmail: metadata?.user_email,
              userName: metadata?.user_name,
              psychologySessionId: psychologySessionDoc.id,
              checkoutSessionId: sessionId,
              paymentIntentId: session.payment_intent?.id || session.payment_intent,
              customerId: session.customer?.id || session.customer,
              amountPaid: session.amount_total,
              currency: session.currency,
              sessionDate: metadata?.session_date,
              sessionTime: metadata?.session_time,
              psychologistName: metadata?.psychologist_name,
              paymentStatus: 'succeeded',
              paymentMethod: session.payment_method_types?.[0] || 'card',
              createdAt: FieldValue.serverTimestamp()
            });

            console.log(`Sesión de psicólogo confirmada para usuario ${userId}`);
          }
        } catch (firebaseError) {
          console.error(`Error al actualizar Firebase desde /verify-psychology-session:`, firebaseError);
        }
      }
    }

    // Respuesta completa
    res.json({
      paymentStatus: session.payment_status,
      sessionStatus: session.status,
      paymentIntentId: session.payment_intent?.id || session.payment_intent,
      customerId: session.customer?.id || session.customer,
      customerEmail: session.customer_details?.email || session.customer?.email,
      amountTotal: session.amount_total,
      currency: session.currency,
      sessionType: session.metadata?.session_type,
      sessionDate: session.metadata?.session_date,
      sessionTime: session.metadata?.session_time,
      psychologistName: session.metadata?.psychologist_name,
      metadata: session.metadata
    });
  } catch (error) {
    console.error("Error verificando sesión de psicólogo:", error);
    res.status(500).json({
      error: "Error al verificar la sesión",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Endpoint para obtener sesiones de psicólogo del usuario
stripeRouter.get("/psychology-sessions/:userId", async (req, res) => {
  const { userId } = req.params;
  const { status, limit = 10 } = req.query;

  if (!userId) {
    return res.status(400).json({ error: "userId is required" });
  }

  try {
    let query = db.collection('psychology_sessions')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .limit(parseInt(limit));

    // Filtrar por estado si se especifica
    if (status) {
      query = query.where('sessionStatus', '==', status);
    }

    const sessionsSnapshot = await query.get();

    const sessions = sessionsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate(),
      updatedAt: doc.data().updatedAt?.toDate(),
      paidAt: doc.data().paidAt?.toDate()
    }));

    res.json({
      sessions: sessions,
      totalSessions: sessions.length
    });

  } catch (error) {
    console.error("Error obteniendo sesiones de psicólogo:", error);
    res.status(500).json({
      error: "Error al obtener sesiones de psicólogo",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Función auxiliar para manejar sesiones de psicólogo completadas
async function handlePsychologySessionCompleted(session) {
  console.log(`Procesando sesión de psicólogo completada: ${session.id}`);

  const userId = session.client_reference_id || session.metadata?.firebase_uid;
  const metadata = session.metadata;

  if (!userId) {
    console.error('No se encontró userId en la sesión de psicólogo');
    return;
  }

  try {
    // Buscar y actualizar el registro de la sesión
    const psychologySessionsQuery = await db.collection('psychology_sessions')
      .where('checkoutSessionId', '==', session.id)
      .limit(1)
      .get();

    if (!psychologySessionsQuery.empty) {
      const psychologySessionDoc = psychologySessionsQuery.docs[0];

      await psychologySessionDoc.ref.update({
        paymentStatus: 'paid',
        sessionStatus: 'confirmed',
        paymentIntentId: session.payment_intent,
        amountPaid: session.amount_total,
        currency: session.currency,
        paidAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });

      // Crear registro de pago
      await db.collection('psychology_payments').add({
        userId: userId,
        userEmail: metadata?.user_email,
        userName: metadata?.user_name,
        psychologySessionId: psychologySessionDoc.id,
        checkoutSessionId: session.id,
        paymentIntentId: session.payment_intent,
        customerId: session.customer,
        amountPaid: session.amount_total,
        currency: session.currency,
        sessionDate: metadata?.session_date,
        sessionTime: metadata?.session_time,
        psychologistName: metadata?.psychologist_name,
        paymentStatus: 'succeeded',
        paymentMethod: session.payment_method_types?.[0] || 'card',
        createdAt: FieldValue.serverTimestamp()
      });

      console.log(`Sesión de psicólogo registrada exitosamente para usuario: ${userId}`);
    }
  } catch (error) {
    console.error(`Error al procesar sesión de psicólogo completada:`, error);
    throw error;
  }
}

// Webhook de Stripe con manejo completo de eventos
stripeRouter.post("/stripe-webhook", async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripeClient.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.error(`Webhook signature verification failed.`, err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  console.log(`Webhook recibido: ${event.type}`);

  try {
    switch (event.type) {
      case 'checkout.session.completed':
        // Verificar si es una sesión de psicólogo
        if (event.data.object.metadata?.session_type === 'psychology_session') {
          await handlePsychologySessionCompleted(event.data.object);
        } else {
          await handleCheckoutSessionCompleted(event.data.object);
        }
        break;

      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(event.data.object);
        break;

      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object);
        break;

      case 'invoice.payment_succeeded':
        await handlePaymentSucceeded(event.data.object);
        break;

      case 'invoice.payment_failed':
        await handlePaymentFailed(event.data.object);
        break;
    }

    res.status(200).send();
  } catch (error) {
    console.error('Error processing webhook:', error);
    res.status(500).send('Webhook handler failed');
  }
});

// FUNCIONES AUXILIARES PARA MANEJAR EVENTOS

async function handleCheckoutSessionCompleted(session) {
  console.log(`Procesando checkout completado: ${session.id}`);

  const userId = session.client_reference_id || session.metadata?.firebase_uid;
  const userEmail = session.customer_details?.email || session.metadata?.user_email;
  const userName = session.metadata?.user_name || 'Usuario';
  const planName = session.metadata?.plan_name || 'Premium';
  const planId = session.metadata?.plan_id;
  const subscriptionId = session.subscription;
  const customerId = session.customer;

  if (!userId) {
    console.error('No se encontró userId en el checkout session');
    return;
  }

  try {
    // ACTUALIZAR DATOS DEL USUARIO EN FIREBASE
    await db.collection('patients').doc(userId).set({
      isPremium: true,
      subscriptionId: subscriptionId,
      stripeCustomerId: customerId,
      subscriptionStartDate: FieldValue.serverTimestamp(),
      lastPaymentDate: FieldValue.serverTimestamp(),
      email: userEmail,
      name: userName,
      planId: planId,
      planName: planName
    }, { merge: true });

    // CREAR REGISTRO DE SUSCRIPCIÓN EN COLECCIÓN DEDICADA
    await db.collection('subscriptions').doc(subscriptionId).set({
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      customerId: customerId,
      planId: planId,
      planName: planName,
      status: 'active',
      amountTotal: session.amount_total,
      currency: session.currency,
      checkoutSessionId: session.id,
      metadata: session.metadata,
      createdAt: FieldValue.serverTimestamp(),
    });

    // CREAR NOTIFICACIÓN PARA LA NUEVA SUSCRIPCIÓN
    await createNotification({
      userId: userId,
      title: '¡Suscripción Activada!',
      body: `¡Felicidades! Tu plan ${planName} ha sido activado con éxito.`,
      type: 'subscription_activated',
      data: {
        subscriptionId: subscriptionId,
        planName: planName,
        planId: planId,
        amountPaid: session.amount_total,
        currency: session.currency
      }
    });

    console.log(`Suscripción registrada exitosamente para usuario: ${userId}`);
  } catch (error) {
    console.error(`Error al procesar checkout completado:`, error);
    throw error;
  }
}

async function handleSubscriptionUpdated(subscription) {
  try {
    console.log('🔍 Debug - subscription updated completa:', {
      current_period_end: subscription.current_period_end,
      current_period_start: subscription.current_period_start,
      status: subscription.status
    });

    const updateData = {
      status: subscription.status,
      cancelAtPeriodEnd: subscription.cancel_at_period_end,
      updatedAt: FieldValue.serverTimestamp()
    };

    // SI LA SUSCRIPCIÓN FUE CANCELADA
    if (subscription.status === 'canceled') {
      updateData.canceledAt = FieldValue.serverTimestamp();
      updateData.cancelReason = subscription.cancellation_details?.reason || 'unknown';
    }

    await db.collection('subscriptions').doc(subscription.id).update(updateData);

    // BUSCAR USUARIO Y ACTUALIZAR SU ESTADO 
    const subscriptionDoc = await db.collection('subscriptions').doc(subscription.id).get();
    if (subscriptionDoc.exists) {
      const subscriptionData = subscriptionDoc.data();
      const userIdFromDoc = subscriptionData.userId;
      const planName = subscriptionData.planName || 'Premium';

      await db.collection('patients').doc(userIdFromDoc).update({
        isPremium: subscription.status === 'active',
        subscriptionStatus: subscription.status,
        lastSubscriptionUpdate: FieldValue.serverTimestamp()
      });

      // CREAR NOTIFICACIONES SEGÚN EL ESTADO
      if (subscription.status === 'canceled') {
        await createNotification({
          userId: userIdFromDoc,
          title: 'Suscripción Cancelada',
          body: `Tu suscripción ${planName} ha sido cancelada.`,
          type: 'subscription_canceled',
          data: {
            subscriptionId: subscription.id,
            planName: planName,
            cancelReason: subscription.cancellation_details?.reason || 'unknown',
            canceledAt: new Date().toISOString()
          }
        });
      } else if (subscription.status === 'past_due') {
        await createNotification({
          userId: userIdFromDoc,
          title: 'Problema con el Pago',
          body: `Hay un problema con el pago de tu suscripción ${planName}. Por favor actualiza tu método de pago.`,
          type: 'payment_failed',
          data: {
            subscriptionId: subscription.id,
            planName: planName,
            status: subscription.status
          }
        });
      } else if (subscription.status === 'active' && subscription.cancel_at_period_end) {
        const periodEnd = new Date(subscription.current_period_end * 1000);
        await createNotification({
          userId: userIdFromDoc,
          title: 'Suscripción Programada para Cancelar',
          body: `Tu suscripción ${planName} se cancelará el ${periodEnd.toLocaleDateString()}.`,
          type: 'subscription_cancel_scheduled',
          data: {
            subscriptionId: subscription.id,
            planName: planName,
            currentPeriodEnd: periodEnd.toISOString()
          }
        });
      }

      console.log(`Usuario ${userIdFromDoc} actualizado con estado: ${subscription.status}`);
    }
  } catch (error) {
    console.error(`Error al actualizar suscripción:`, error);
  }
}

// Handler para eliminación de suscripción 
async function handleSubscriptionDeleted(subscription) {
  console.log(`Suscripción eliminada: ${subscription.id}`);

  try {
    // BUSCAR EL DOCUMENTO DE LA SUSCRIPCIÓN
    const subscriptionDoc = await db.collection('subscriptions').doc(subscription.id).get();

    if (subscriptionDoc.exists) {
      const subscriptionData = subscriptionDoc.data();
      const userIdFromDoc = subscriptionData.userId;
      const planName = subscriptionData.planName || 'Premium';

      // ACTUALIZAR USUARIO - REMOVER SUSCRIPCIÓN 
      await db.collection('patients').doc(userIdFromDoc).update({
        isPremium: false,
        subscriptionId: null,
        subscriptionStatus: 'canceled',
        subscriptionCanceledAt: FieldValue.serverTimestamp()
      });

      // ACTUALIZAR DOCUMENTO DE SUSCRIPCIÓN
      await subscriptionDoc.ref.update({
        status: 'deleted',
        deletedAt: FieldValue.serverTimestamp(),
        cancelReason: subscription.cancellation_details?.reason || 'subscription_deleted'
      });

      // CREAR NOTIFICACIÓN DE SUSCRIPCIÓN ELIMINADA
      await createNotification({
        userId: userIdFromDoc,
        title: 'Suscripción Terminada',
        body: `Tu suscripción ${planName} ha terminado. Puedes renovarla cuando gustes.`,
        type: 'subscription_ended',
        data: {
          subscriptionId: subscription.id,
          planName: planName,
          deletedAt: new Date().toISOString()
        }
      });

      console.log(`Suscripción ${subscription.id} marcada como eliminada`);
    }
  } catch (error) {
    console.error(`Error al eliminar suscripción:`, error);
  }
}

async function handlePaymentSucceeded(invoice) {
  console.log(`Pago exitoso: ${invoice.id} para suscripción: ${invoice.subscription}`);

  try {
    // REGISTRAR PAGO EXITOSO
    await db.collection('payments').add({
      invoiceId: invoice.id,
      subscriptionId: invoice.subscription,
      customerId: invoice.customer,
      amountPaid: invoice.amount_paid,
      currency: invoice.currency,
      status: 'succeeded',
      paymentDate: new Date(invoice.status_transitions.paid_at * 1000),
      periodStart: new Date(invoice.period_start * 1000),
      periodEnd: new Date(invoice.period_end * 1000),
      createdAt: FieldValue.serverTimestamp()
    });

    const subscriptionDoc = await db.collection('subscriptions').doc(invoice.subscription).get();
    if (subscriptionDoc.exists) {
      const subscriptionData = subscriptionDoc.data();
      const userIdFromDoc = subscriptionData.userId;
      const planName = subscriptionData.planName || 'Premium';
      const amountFormatted = (invoice.amount_paid / 100).toFixed(2);

      await db.collection('patients').doc(userIdFromDoc).update({
        lastPaymentDate: FieldValue.serverTimestamp(),
        isPremium: true // REACTIVAR SI ESTABA SUSPENDIDA 
      });

      // CREAR NOTIFICACIÓN DE PAGO EXITOSO
      await createNotification({
        userId: userIdFromDoc,
        title: 'Pago Procesado',
        body: `Tu pago de ${amountFormatted} ${invoice.currency.toUpperCase()} para ${planName} ha sido procesado exitosamente.`,
        type: 'payment_succeeded',
        data: {
          subscriptionId: invoice.subscription,
          planName: planName,
          amountPaid: invoice.amount_paid,
          currency: invoice.currency,
          periodEnd: new Date(invoice.period_end * 1000).toISOString()
        }
      });

      console.log(`Pago registrado para usuario: ${userIdFromDoc}`);
    }
  } catch (error) {
    console.error(`Error al procesar pago exitoso:`, error);
  }
}

async function handlePaymentFailed(invoice) {
  console.log(`Pago fallido: ${invoice.id} para suscripción: ${invoice.subscription}`);

  try {
    // REGISTRAR PAGO FALLIDO
    await db.collection('payments').add({
      invoiceId: invoice.id,
      subscriptionId: invoice.subscription,
      customerId: invoice.customer,
      amountDue: invoice.amount_due,
      currency: invoice.currency,
      status: 'failed',
      failureReason: invoice.last_finalization_error?.message || 'unknown',
      attemptedAt: new Date(invoice.status_transitions.finalized_at * 1000),
      createdAt: FieldValue.serverTimestamp()
    });

    const subscriptionDoc = await db.collection('subscriptions').doc(invoice.subscription).get();
    if (subscriptionDoc.exists) {
      const subscriptionData = subscriptionDoc.data();
      const userIdFromDoc = subscriptionData.userId;
      const planName = subscriptionData.planName || 'Premium';
      const amountFormatted = (invoice.amount_due / 100).toFixed(2);

      await db.collection('patients').doc(userIdFromDoc).update({
        lastPaymentFailure: FieldValue.serverTimestamp(),
        paymentStatus: 'failed'
      });

      // CREAR NOTIFICACIÓN DE PAGO FALLIDO
      await createNotification({
        userId: userIdFromDoc,
        title: 'Error en el Pago',
        body: `No pudimos procesar tu pago de ${amountFormatted} ${invoice.currency.toUpperCase()} para ${planName}. Por favor actualiza tu método de pago.`,
        type: 'payment_failed',
        data: {
          subscriptionId: invoice.subscription,
          planName: planName,
          amountDue: invoice.amount_due,
          currency: invoice.currency,
          failureReason: invoice.last_finalization_error?.message || 'unknown'
        }
      });

      console.log(`Pago fallido registrado para usuario: ${userIdFromDoc}`);
    }
  } catch (error) {
    console.error(`Error al procesar pago fallido:`, error);
  }
}

// Endpoint para obtener estado de suscripción del usuario
stripeRouter.get("/subscription-status/:userId", async (req, res) => {
  const { userId } = req.params;

  if (!userId) {
    return res.status(400).json({ error: "userId is required" });
  }

  try {

    const userDoc = await db.collection('patients').doc(userId).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: "Usuario no encontrado" });
    }

    const userData = userDoc.data();

    // Si tiene suscripción, obtener detalles
    if (userData.isPremium && userData.subscriptionId) {
      const subscriptionDoc = await db.collection('subscriptions').doc(userData.subscriptionId).get();

      if (subscriptionDoc.exists) {
        const subscriptionData = subscriptionDoc.data();

        // Verificar estado en Stripe también
        let stripeSubscription = null;
        try {
          stripeSubscription = await stripeClient.subscriptions.retrieve(userData.subscriptionId);
        } catch (stripeError) {
          console.log(`No se pudo obtener suscripción de Stripe: ${stripeError.message}`);
        }

        return res.json({
          hasSubscription: true,
          subscription: {
            id: userData.subscriptionId,
            status: stripeSubscription?.status || subscriptionData.status,
            planName: subscriptionData.planName || userData.planName || 'Premium',
            planId: subscriptionData.planId || userData.planId,
            currentPeriodEnd: stripeSubscription?.current_period_end ?
              new Date(stripeSubscription.current_period_end * 1000) :
              subscriptionData.currentPeriodEnd,
            cancelAtPeriodEnd: stripeSubscription?.cancel_at_period_end || false,
            userName: subscriptionData.userName || userData.name,
            userEmail: subscriptionData.userEmail || userData.email,
            ...subscriptionData
          }
        });
      }
    }

    // Sin suscripción activa
    res.json({
      hasSubscription: false,
      subscription: null
    });

  } catch (error) {
    console.error("Error obteniendo estado de suscripción:", error);
    res.status(500).json({
      error: "Error al obtener estado de suscripción",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

export default stripeRouter;