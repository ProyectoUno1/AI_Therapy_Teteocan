// backend/routes/hello.js

import express from 'express';
import { db } from '../firebase-admin.js';
const router = express.Router();

import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';


router.get("/hello", verifyFirebaseToken, (req, res) => {
    
    const user = req.firebaseUser;
    if (!user) {
        return res.status(401).json({ message: 'Usuario no autenticado o información no disponible.' });
    }
    res.json({
        message: `¡Hola, ${user.email || "usuario"}!`,
        uid: user.uid,
        email_verified: user.email_verified,
    });
});


export default router; 