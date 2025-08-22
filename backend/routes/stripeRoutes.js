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

// Endpoint para crear la sesión de checkout
stripeRouter.post("/create-checkout-session", async (req, res) => {
  const { planId, userEmail, userId } = req.body;

  if (!planId || !userEmail || !userId) {
    return res.status(400).json({ error: "planId, userEmail, and userId are required." });
  }

  try {
    let customer;
    const existingCustomers = await stripeClient.customers.list({ email: userEmail, limit: 1 });

    if (existingCustomers.data.length > 0) {
      customer = existingCustomers.data[0];
    } else {
      customer = await stripeClient.customers.create({
        email: userEmail,
      });
    }

    const session = await stripeClient.checkout.sessions.create({
      payment_method_types: ['card'],
      mode: 'subscription',
      line_items: [{
        price: planId,
        quantity: 1,
      }],
      customer: customer.id,
      client_reference_id: userId,
      success_url: 'auroraapp://success?session_id={CHECKOUT_SESSION_ID}',
      cancel_url: 'auroraapp://cancel',
    });

    res.json({ checkoutUrl: session.url });

  } catch (e) {
    console.error("Error al crear la sesión de Checkout:", e);
    res.status(500).json({ error: e.message });
  }
});

// Endpoint del webhook de Stripe
stripeRouter.post("/stripe-webhook", async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripeClient.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    console.error(`Webhook signature verification failed.`, err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  switch (event.type) {
    case 'checkout.session.completed':
      const session = event.data.object;
      const userId = session.client_reference_id;
      const customerEmail = session.customer_details.email;
      const subscriptionId = session.subscription;
      const amount = session.amount_total;
      const currency = session.currency;
      const userName = session.metadata?.userName || 'N/A'; 

      console.log(`Evento: ${event.type} recibido para el usuario ${userId}`);

      try {
        // 1. Actualiza el documento del usuario en la colección 'users'
        await db.collection('users').doc(userId).update({ 
          hasSubscription: true, 
          subscriptionId: subscriptionId,
        });
        
        // 2. Registra el evento de pago en una colección de 'subscriptions'
        await db.collection('subscriptions').doc(subscriptionId).set({
          userId: userId,
          userName: userName,
          userEmail: customerEmail,
          status: 'active',
          amount: amount,
          currency: currency,
          createdAt: FieldValue.serverTimestamp(),
        });

        console.log(`Estado de suscripción actualizado para el usuario ${userId} en Firestore.`);
      } catch (error) {
        console.error(`Error al actualizar el estado de suscripción en Firestore:`, error);
        return res.status(500).send('Error interno del servidor');
      }
      break;
      
    case 'customer.subscription.updated':
      const updatedSubscription = event.data.object;
      try {
          await db.collection('subscriptions').doc(updatedSubscription.id).update({ 
              status: updatedSubscription.status,
              updatedAt: FieldValue.serverTimestamp()
          });
          console.log(`Suscripción ${updatedSubscription.id} actualizada a estado: ${updatedSubscription.status}`);
      } catch (error) {
          console.error(`Error al actualizar suscripción en Firestore:`, error);
          return res.status(500).send('Error interno del servidor');
      }
      break;
      
    case 'customer.subscription.deleted':
      const deletedSubscription = event.data.object;
      try {
        // 1. Busca el documento de la suscripción en tu colección de 'subscriptions'
        const subscriptionDoc = db.collection('subscriptions').doc(deletedSubscription.id);
        const docSnapshot = await subscriptionDoc.get();
        if (docSnapshot.exists) {
            const userIdFromDoc = docSnapshot.data().userId;
            
            // 2. Actualiza el estado del usuario en la colección 'users'
            await db.collection('users').doc(userIdFromDoc).update({ hasSubscription: false, subscriptionId: null });
            
            // 3. Actualiza el estado del documento de la suscripción a 'canceled'
            await subscriptionDoc.update({ status: 'canceled', canceledAt: FieldValue.serverTimestamp() });

            console.log(`Suscripción ${deletedSubscription.id} eliminada.`);
        }
      } catch (error) {
        console.error(`Error al eliminar suscripción en Firestore:`, error);
        return res.status(500).send('Error interno del servidor');
      }
      break;
    
    default:
      console.log(`Evento no manejado: ${event.type}`);
  }

  res.status(200).send();
});

export default stripeRouter;