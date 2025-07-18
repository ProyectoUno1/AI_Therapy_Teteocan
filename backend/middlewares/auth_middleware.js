const admin = require('../config/firebase/firebase');

async function verifyFirebaseToken(req, res, next) {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
        return res.status(401).json({ error: 'No token provided' });
    }

    const idToken = authHeader.split("Bearer ")[1];
    
    // Debug: Mostrar información del entorno
    console.log('🔍 Verificando token...');
    console.log('🔍 Usando emulator:', process.env.USE_FIREBASE_EMULATOR === 'true');
    console.log('🔍 Auth emulator host:', process.env.FIREBASE_AUTH_EMULATOR_HOST);
    
    try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        req.firebaseUser = decodedToken; // Attach the decoded user info to the request object (uid, email, etc.)
        console.log('✅ Token verificado exitosamente para:', decodedToken.email);
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

module.exports = verifyFirebaseToken;