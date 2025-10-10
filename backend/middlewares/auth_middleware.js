// backend/middlewares/auth_middleware.js

import { auth } from '../firebase-admin.js';
import admin from 'firebase-admin';

async function verifyFirebaseToken(req, res, next) {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
        return res.status(401).json({ error: 'No token provided' });
    }

    const idToken = authHeader.split("Bearer ")[1];

    try {
        const decodedToken = await auth.verifyIdToken(idToken);
        req.firebaseUser = decodedToken;
        req.userId = decodedToken.uid; 
        next();
    } catch (error) {
        console.error('❌ Error verifying Firebase token:', error.message);
        console.error('❌ Código de error:', error.code);

        // Mensaje de error más específico para el entorno de desarrollo
        let errorMessage = 'Invalid or expired token';
        if (process.env.NODE_ENV === 'development') {
            errorMessage += ` - Detalles: ${error.message}`;

            // Sugerencia para el error específico de firma
            if (error.code === 'auth/argument-error' && error.message.includes('signature')) {
                errorMessage += '. Posiblemente estás usando un token del emulador en un backend de producción, o viceversa.';
            }
        }

        return res.status(403).json({
            error: errorMessage,
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
}

export { verifyFirebaseToken };