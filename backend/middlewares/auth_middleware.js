// backend/middlewares/auth_middleware.js

// --- ¡IMPORTACIÓN NECESARIA! ---
// Importa la instancia 'auth' desde tu configuración central de Firebase Admin.
import { auth } from '../firebase-admin.js'; // Ajusta la ruta si es necesario.
                                             // Desde 'middlewares', '../' sube a 'backend/',
                                             // y luego 'firebase-admin.js' está ahí.

async function verifyFirebaseToken(req, res, next) {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
        return res.status(401).json({ error: 'No token provided' });
    }

    const idToken = authHeader.split("Bearer ")[1];

    console.log('🔍 Verificando token...');
    // Estas variables de entorno no las configuras directamente en este archivo,
    // pero si se cargan al inicio de la app, estarán disponibles.
    console.log('🔍 Usando emulator:', process.env.USE_FIREBASE_EMULATOR === 'true');
    console.log('🔍 Auth emulator host:', process.env.FIREBASE_AUTH_EMULATOR_HOST);

    try {
        // --- ¡CORRECCIÓN CLAVE AQUÍ! ---
        // Usa la instancia 'auth' que importaste.
        const decodedToken = await auth.verifyIdToken(idToken);
        req.firebaseUser = decodedToken; // Adjunta la info del usuario decodificada al objeto de la petición (uid, email, etc.)
        console.log('✅ Token verificado exitosamente para:', decodedToken.email || decodedToken.uid); // Usa uid si no hay email
        next();
    } catch (error) {
        console.error('❌ Error verifying Firebase token:', error.message);
        console.error('❌ Código de error:', error.code);
        return res.status(403).json({
            error: 'Invalid or expired token',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
}

export default verifyFirebaseToken;