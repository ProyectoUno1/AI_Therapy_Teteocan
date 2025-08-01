// backend/routes/hello.js

import express from 'express'; // Usa import para express
const router = express.Router();

// Importa el middleware de autenticación
// Asegúrate de que 'auth_middleware.js' use 'export default' o 'export { ... }'
// Y la ruta es relativa desde 'routes/' a 'middlewares/'
import verifyFirebaseToken from '../middlewares/auth_middleware.js'; // <-- ¡CORREGIDO!

// Ruta protegida
router.get("/hello", verifyFirebaseToken, (req, res) => {
    // Asume que verifyFirebaseToken adjunta el objeto de usuario de Firebase a req.firebaseUser
    const user = req.firebaseUser;
    // Si req.firebaseUser no está definido (ej. middleware falla o no se ejecuta)
    // es bueno tener un fallback o un manejo de errores más robusto.
    if (!user) {
        return res.status(401).json({ message: 'Usuario no autenticado o información no disponible.' });
    }
    res.json({
        message: `¡Hola, ${user.email || "usuario"}!`,
        uid: user.uid,
        email_verified: user.email_verified,
    });
});

// ¡IMPORTANTE! Exporta el router como default export
export default router; // <-- ¡Esta es la línea clave que necesitas!