import express from "express";
import stripe from "stripe";
import dotenv from "dotenv";
import { Buffer } from 'node:buffer';
import { db } from '../firebase-admin.js';
import { FieldValue } from 'firebase-admin/firestore';

dotenv.config();

const stripeClient = stripe(process.env.STRIPE_SECRET_KEY);
const stripeRouter = express.Router();

stripeRouter.use('/stripe-webhook', express.raw({type: 'application/json'}));

//Endpoint para crear la sesión de checkout
stripeRouter.post("/create-checkout-session", async (req, res) => {
  const { planId, userEmail, userId, userName, planName } = req.body;

  if (!planId || !userEmail || !userId) {
    return res.status(400).json({ 
      error: "planId, userEmail, and userId are required." 
    });
  }

  try {
    console.log(`Creando sesión de checkout para usuario: ${userEmail} (${userId})`);
    
    // VERIFICAR SI YA TIENE SUSCRIPCIÓN ACTIVA
    const userDoc = await db.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data().hasSubscription) {
      return res.status(400).json({ 
        error: "El usuario ya tiene una suscripción activa" 
      });
    }
    
    // BUSCAR O CREAR CLIENTE DE STRIPE CON EMAIL DEL USUARIO AUTENTICADO
    let customer;
    const existingCustomers = await stripeClient.customers.list({ 
      email: userEmail, 
      limit: 1 
    });

    if (existingCustomers.data.length > 0) {
      customer = existingCustomers.data[0];
      console.log(`Cliente existente encontrado: ${customer.id}`);
      
      //  ACTUALIZAR DATOS DEL CLIENTE SI ES NECESARIO
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
      // CREAR NUEVO CLIENTE CON DATOS COMPLETOS
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

    // CREAR SESIÓN DE CHECKOUT CON METADATOS COMPLETOS
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
      billing_address_collection: 'auto',
      customer_update: {
        address: 'auto',
        name: 'auto'
      },
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
    
    //  OBTENER SESIÓN CON DATOS 
    const session = await stripeClient.checkout.sessions.retrieve(sessionId, {
      expand: ['subscription', 'customer']
    });
    
    console.log(`Estado de sesión ${sessionId}: ${session.payment_status}`);
    
  
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
  const { userId, immediate = false } = req.body;

  if (!userId) {
    return res.status(400).json({ error: "userId is required" });
  }

  try {
    // OBTENER SUSCRIPCIÓN DEL USUARIO
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists || !userDoc.data().subscriptionId) {
      return res.status(404).json({ error: "No se encontró suscripción activa" });
    }

    const subscriptionId = userDoc.data().subscriptionId;

    // CANCELAR EN STRIPE
    const canceledSubscription = await stripeClient.subscriptions.update(subscriptionId, {
      cancel_at_period_end: !immediate,
      metadata: {
        canceled_by: 'user',
        canceled_from: 'mobile_app',
        canceled_at: new Date().toISOString()
      }
    });

    // SI ES CANCELACIÓN INMEDIATA
    if (immediate) {
      await stripeClient.subscriptions.cancel(subscriptionId);
    }

    console.log(` Suscripción ${subscriptionId} ${immediate ? 'cancelada inmediatamente' : 'programada para cancelar'}`);

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

  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckoutCompleted(event.data.object);
      break;
      
    case 'customer.subscription.created':
      await handleSubscriptionCreated(event.data.object);
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
    
    default:
      console.log(`Evento no manejado: ${event.type}`);
  }

  res.status(200).send();
});


async function handleCheckoutCompleted(session) {
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
    await db.collection('users').doc(userId).set({ 
      hasSubscription: true, 
      subscriptionId: subscriptionId,
      stripeCustomerId: customerId,
      subscriptionStartDate: FieldValue.serverTimestamp(),
      lastPaymentDate: FieldValue.serverTimestamp(),
      email: userEmail,
      name: userName,
      planId: planId,
      planName: planName
    }, { merge: true });

    // CREAR REGISTRO DE SUSCRIPCIÓN 
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

    console.log(` Suscripción registrada exitosamente para usuario: ${userId}`);
  } catch (error) {
    console.error(` Error al procesar checkout completado:`, error);
    throw error;
  }
}

async function handleSubscriptionCreated(subscription) {
  console.log(`Suscripción creada: ${subscription.id}`);
  
  try {
    const subscriptionDoc = await db.collection('subscriptions').doc(subscription.id).get();
    if(subscriptionDoc.exists) {
      await db.collection('subscriptions').doc(subscription.id).update({
        status: subscription.status,
        currentPeriodStart: new Date(subscription.current_period_start * 1000),
        currentPeriodEnd: new Date(subscription.current_period_end * 1000),
        subscriptionCreated: FieldValue.serverTimestamp()
      });
    }

    console.log(` Estado de suscripción creada actualizado: ${subscription.id}`);
  } catch (error) {
    console.error(` Error al actualizar suscripción creada:`, error);
  }
}

async function handleSubscriptionUpdated(subscription) {
  console.log(`Suscripción actualizada: ${subscription.id} - Estado: ${subscription.status}`);
  
  try {
    const updateData = {
      status: subscription.status,
      currentPeriodStart: new Date(subscription.current_period_start * 1000),
      currentPeriodEnd: new Date(subscription.current_period_end * 1000),
      updatedAt: FieldValue.serverTimestamp()
    };

  
    if (subscription.status === 'canceled') {
      updateData.canceledAt = FieldValue.serverTimestamp();
      updateData.cancelReason = subscription.cancellation_details?.reason || 'unknown';
    }

    await db.collection('subscriptions').doc(subscription.id).update(updateData);

    // BUSCAR USUARIO Y ACTUALIZAR SU ESTADO
    const subscriptionDoc = await db.collection('subscriptions').doc(subscription.id).get();
    if (subscriptionDoc.exists) {
      const userIdFromDoc = subscriptionDoc.data().userId;
      
      await db.collection('users').doc(userIdFromDoc).update({ 
        hasSubscription: subscription.status === 'active',
        subscriptionStatus: subscription.status,
        lastSubscriptionUpdate: FieldValue.serverTimestamp()
      });

      console.log(`Usuario ${userIdFromDoc} actualizado con estado: ${subscription.status}`);
    }
  } catch (error) {
    console.error(` Error al actualizar suscripción:`, error);
  }
}

async function handleSubscriptionDeleted(subscription) {
  console.log(`Suscripción eliminada: ${subscription.id}`);
  
  try {
    // BUSCAR EL DOCUMENTO DE LA SUSCRIPCIÓN
    const subscriptionDoc = await db.collection('subscriptions').doc(subscription.id).get();
    
    if (subscriptionDoc.exists) {
      const userIdFromDoc = subscriptionDoc.data().userId;
      
      // ACTUALIZAR USUARIO - REMOVER SUSCRIPCIÓN
      await db.collection('users').doc(userIdFromDoc).update({ 
        hasSubscription: false, 
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

      console.log(` Suscripción ${subscription.id} marcada como eliminada`);
    }
  } catch (error) {
    console.error(` Error al eliminar suscripción:`, error);
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

    // ACTUALIZAR ÚLTIMA FECHA DE PAGO DEL USUARIO
    const subscriptionDoc = await db.collection('subscriptions').doc(invoice.subscription).get();
    if (subscriptionDoc.exists) {
      const userIdFromDoc = subscriptionDoc.data().userId;
      
      await db.collection('users').doc(userIdFromDoc).update({ 
        lastPaymentDate: FieldValue.serverTimestamp(),
        hasSubscription: true // REACTIVAR SI ESTABA SUSPENDIDA
      });

      console.log(` Pago registrado para usuario: ${userIdFromDoc}`);
    }
  } catch (error) {
    console.error(` Error al procesar pago exitoso:`, error);
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

    // NOTIFICAR AL USUARIO (OPCIONAL)
    const subscriptionDoc = await db.collection('subscriptions').doc(invoice.subscription).get();
    if (subscriptionDoc.exists) {
      const userIdFromDoc = subscriptionDoc.data().userId;
      
      await db.collection('users').doc(userIdFromDoc).update({ 
        lastPaymentFailure: FieldValue.serverTimestamp(),
        paymentStatus: 'failed'
      });

      console.log(` Pago fallido registrado para usuario: ${userIdFromDoc}`);
    }
  } catch (error) {
    console.error(` Error al procesar pago fallido:`, error);
  }
}

// Endpoint para obtener estado de suscripción del usuario
stripeRouter.get("/subscription-status/:userId", async (req, res) => {
  const { userId } = req.params;

  if (!userId) {
    return res.status(400).json({ error: "userId is required" });
  }

  try {
    // OBTENER DATOS DEL USUARIO
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ error: "Usuario no encontrado" });
    }

    const userData = userDoc.data();
    
    //  SI TIENE SUSCRIPCIÓN, OBTENER DETALLES
    if (userData.hasSubscription && userData.subscriptionId) {
      const subscriptionDoc = await db.collection('subscriptions').doc(userData.subscriptionId).get();
      
      if (subscriptionDoc.exists) {
        const subscriptionData = subscriptionDoc.data();
        
        //  VERIFICAR ESTADO EN STRIPE TAMBIÉN
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

    //  SIN SUSCRIPCIÓN ACTIVA
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