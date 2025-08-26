import express from "express";
import stripe from "stripe";
import dotenv from "dotenv";
import { db } from '../firebase-admin.js';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';

dotenv.config();

const stripeClient = stripe(process.env.STRIPE_SECRET_KEY);
const stripeRouter = express.Router();

function createTimestampFromUnixSeconds(unixSeconds) {
    if (!unixSeconds || typeof unixSeconds !== 'number') {
        console.warn(' Valor inválido para timestamp:', unixSeconds);
        return null;
    }
    
    try {
        return Timestamp.fromMillis(unixSeconds * 1000);
    } catch (error) {
        console.error('Error al crear timestamp:', error);
        return null;
    }
}

stripeRouter.get("/plans", async (req, res) => {
    try {
        const planIds = [
            'price_1RvpKc2Szsvtfc49E0VZHcAv', // Plan mensual
            'price_1RwQDS2Szsvtfc49voxyVem6'  // Plan anual
        ];

        const plans = [];

        for (const priceId of planIds) {
            const price = await stripeClient.prices.retrieve(priceId, {
                expand: ['product']
            });

            // Crear nombre descriptivo basado en el producto e intervalo
            let planName;
            if (price.recurring?.interval === 'year') {
                planName = `${price.product.name} Anual`;
            } else if (price.recurring?.interval === 'month') {
                planName = `${price.product.name} Mensual`;
            } else {
                planName = price.product.name;
            }

            plans.push({
                id: price.id,
                productId: price.product.id,
                productName: price.product.name,
                planName: planName,
                amount: price.unit_amount,
                currency: price.currency.toUpperCase(),
                interval: price.recurring?.interval,
                intervalCount: price.recurring?.interval_count,
                displayPrice: formatCurrency(price.unit_amount, price.currency),
                isAnnual: price.recurring?.interval === 'year',
            });
        }

        res.json({ plans });

    } catch (e) {
        console.error("Error al obtener planes:", e);
        res.status(500).json({ error: e.message });
    }
});

// Función helper para formatear moneda
function formatCurrency(amount, currency) {
    const formatter = new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: currency.toUpperCase(),
        minimumFractionDigits: 2
    });
    return formatter.format(amount / 100);
}

// Endpoint para crear la sesión de checkout
stripeRouter.post("/create-checkout-session", async (req, res) => {
    const { planId, userEmail, userId, userName } = req.body;

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
            metadata: {
                userName: userName || 'Usuario'
            },
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
stripeRouter.post("/stripe-webhook", express.raw({ type: 'application/json' }), async (req, res) => {
    const sig = req.headers['stripe-signature'];

    if (!sig) {
        console.error('No se encontró firma de Stripe');
        return res.status(400).send('Stripe signature missing');
    }

    let event;

    try {
        event = stripeClient.webhooks.constructEvent(
            req.body,
            sig,
            process.env.STRIPE_WEBHOOK_SECRET
        );

        switch (event.type) {
            case 'checkout.session.completed':
                await handleCheckoutSessionCompleted(event.data.object);
                break;

            case 'customer.subscription.updated':
                await handleSubscriptionUpdated(event.data.object);
                break;

            case 'customer.subscription.deleted':
                await handleSubscriptionDeleted(event.data.object);
                break;
        }

        res.status(200).send();
    } catch (err) {
        console.error(' Error en webhook:', err.message);
        res.status(400).send(`Webhook Error: ${err.message}`);
    }
});

// Handler para checkout.session.completed y almacenamiento en firebase
async function handleCheckoutSessionCompleted(session) {
    const userId = session.client_reference_id;
    const subscriptionId = session.subscription;

    if (!userId || !subscriptionId) {
        console.error('Datos faltantes: userId o subscriptionId');
        return;
    }
    try {
        const subscription = await stripeClient.subscriptions.retrieve(subscriptionId, {
            expand: ['items.data.price', 'items.data.price.product']
        });
        const price = subscription.items.data[0].price;
        const product = price.product;
        let currentPeriodEndTimestamp = createTimestampFromUnixSeconds(subscription.current_period_end);
        
        if (!currentPeriodEndTimestamp) {
            console.warn('current_period_end no disponible, usando created como fallback');
            // Calcular un período de 30 días desde created si current_period_end no está disponible
            const fallbackEndTime = subscription.created + (30 * 24 * 60 * 60); 
            currentPeriodEndTimestamp = createTimestampFromUnixSeconds(fallbackEndTime);
        }
        const planName = price.nickname || 
                        `${product.name} ${price.recurring?.interval === 'year' ? 'Anual' : 'Mensual'}` ||
                        'Premium Plan';

        const subscriptionData = {
            userId: userId,
            stripeSubscriptionId: subscriptionId,
            stripeCustomerId: subscription.customer,
            status: subscription.status,
            planId: price.id,
            planName: planName, 
            productName: product.name,
            currentPeriodEnd: currentPeriodEndTimestamp,
            cancelAtPeriodEnd: subscription.cancel_at_period_end,
            amount: price.unit_amount / 100,
            currency: price.currency.toUpperCase(),
            interval: price.recurring?.interval,
            intervalCount: price.recurring?.interval_count,
            userEmail: session.customer_details?.email,
            userName: session.metadata?.userName || 'Usuario',
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp()
        };

        await db.collection('subscriptions').doc(subscriptionId).set(subscriptionData);

    } catch (error) {
        console.error('Error crítico al procesar checkout session:', error);
        throw error;
    }
}

// Handler para actualizaciones de suscripción 
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

        const currentPeriodEndTimestamp = createTimestampFromUnixSeconds(subscription.current_period_end);
        if (currentPeriodEndTimestamp) {
            updateData.currentPeriodEnd = currentPeriodEndTimestamp;
        } else {
            console.warn('No se pudo actualizar currentPeriodEnd, mantener el valor existente');
        }

        await db.collection('subscriptions').doc(subscription.id).update(updateData);

        console.log(`Suscripción ${subscription.id} actualizada:`, updateData);
    } catch (error) {
        console.error('Error al actualizar suscripción:', error);
    }
}

// Handler para eliminación de suscripción 
async function handleSubscriptionDeleted(subscription) {
    try {
        await db.collection('subscriptions').doc(subscription.id).update({
            status: 'canceled',
            canceledAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp()
        });

        console.log(`Suscripción ${subscription.id} marcada como cancelada`);
    } catch (error) {
        console.error('Error al eliminar suscripción:', error);
    }
}

// Endpoint para verificar el estado de una sesión
stripeRouter.post("/verify-session", async (req, res) => {
    const { sessionId } = req.body;

    if (!sessionId) {
        return res.status(400).json({ error: "sessionId is required" });
    }

    try {
        const session = await stripeClient.checkout.sessions.retrieve(sessionId, {
            expand: ['subscription', 'subscription.latest_invoice.payment_intent']
        });

        // Si el pago fue exitoso, esperar a que el webhook procese
        if (session.payment_status === 'paid' && session.subscription) {
            const subscriptionId = session.subscription.id;

            // Esperar hasta 10 segundos a que aparezca en Firestore
            let subscriptionInFirestore = null;
            let attempts = 0;
            const maxAttempts = 10;

            while (!subscriptionInFirestore && attempts < maxAttempts) {
                attempts++;
                await new Promise(resolve => setTimeout(resolve, 1000));

                subscriptionInFirestore = await db.collection('subscriptions')
                    .doc(subscriptionId)
                    .get();
            }
        }

        res.json({
            paymentStatus: session.payment_status,
            sessionStatus: session.status,
            subscriptionId: session.subscription?.id,
            subscriptionStatus: session.subscription?.status,
            customerId: session.customer,
            customerEmail: session.customer_details?.email,
            amountTotal: session.amount_total,
            currency: session.currency,
            planName: session.metadata?.planName || 'Premium'
        });

    } catch (e) {
        console.error("Error al verificar sesión:", e);
        res.status(500).json({ error: e.message });
    }
});

// Endpoint para cancelar suscripción
stripeRouter.post("/cancel-subscription", async (req, res) => {
    const { subscriptionId, immediate = false } = req.body;
    if (!subscriptionId) {
        return res.status(400).json({ error: "subscriptionId is required" });
    }
    try {
        let subscription;
        if (immediate) {
            // Cancelación inmediata
            subscription = await stripeClient.subscriptions.cancel(subscriptionId);
        } else {
            // Cancelación al final del período
            subscription = await stripeClient.subscriptions.update(subscriptionId, {
                cancel_at_period_end: true
            });
        }
        const currentPeriodEndTimestamp = createTimestampFromUnixSeconds(subscription.current_period_end);
        
        const updateData = {
            status: subscription.status,
            cancelAtPeriodEnd: subscription.cancel_at_period_end,
            updatedAt: FieldValue.serverTimestamp()
        };

        if (currentPeriodEndTimestamp) {
            updateData.currentPeriodEnd = currentPeriodEndTimestamp;
        }

        await db.collection('subscriptions').doc(subscriptionId).update(updateData);

        res.json({
            message: immediate ?
                'Suscripción cancelada inmediatamente' :
                'Suscripción se cancelará al final del período',
            subscription: {
                id: subscription.id,
                status: subscription.status,
                cancelAtPeriodEnd: subscription.cancel_at_period_end,
                currentPeriodEnd: new Date(subscription.current_period_end * 1000)
            }
        });

    } catch (e) {
        console.error("Error al cancelar suscripción:", e);
        res.status(500).json({ error: e.message });
    }
});

stripeRouter.get("/check-subscription/:userId", async (req, res) => {
    const { userId } = req.params;

    try {
        const subscription = await db.collection('subscriptions')
            .where('userId', '==', userId)
            .where('status', 'in', ['active', 'trialing'])
            .limit(1)
            .get();

        if (subscription.empty) {
            return res.json({ exists: false });
        }

        const subData = subscription.docs[0].data();
        res.json({
            exists: true,
            subscription: {
                id: subscription.docs[0].id,
                ...subData
            }
        });

    } catch (e) {
        console.error("Error al verificar suscripción:", e);
        res.status(500).json({ error: e.message });
    }
});

export default stripeRouter;