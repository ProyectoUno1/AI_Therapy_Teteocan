// backend/routes/users.js

const express = require("express");
const router = express.Router();
const pool = require("../config/db");
const verifyFirebaseToken = require("../middlewares/auth_middleware");

// Endpoint para sincronizar usuario con la base de datos
router.post("/sync", verifyFirebaseToken, async (req, res) => {
  try {
    const { uid, name, email } = req.body;
    const firebaseUser = req.firebaseUser;

    // Validar que el UID del token coincida con el del body
    if (firebaseUser.uid !== uid) {
      return res.status(403).json({ error: 'UID mismatch' });
    }

    // Verificar si el usuario ya existe en la base de datos
    const existingUser = await pool.query(
      'SELECT * FROM users WHERE auth_id = $1',
      [uid]
    );

    if (existingUser.rows.length > 0) {
      // Usuario ya existe, actualizar información si es necesario
      await pool.query(
        'UPDATE users SET full_name = $1, email = $2 WHERE auth_id = $3',
        [name, email, uid]
      );
      
      console.log(`✅ Usuario actualizado: ${email}`);
      return res.json({ 
        message: 'Usuario actualizado exitosamente',
        user: existingUser.rows[0]
      });
    } else {
      // Usuario nuevo, crear registro en la base de datos
      const newUser = await pool.query(
        'INSERT INTO users (auth_id, full_name, email, role) VALUES ($1, $2, $3, $4) RETURNING *',
        [uid, name, email, 'user'] // Por defecto rol 'user'
      );
      
      console.log(`✅ Usuario creado: ${email}`);
      return res.status(201).json({
        message: 'Usuario creado exitosamente',
        user: newUser.rows[0]
      });
    }
  } catch (error) {
    console.error('❌ Error al sincronizar usuario:', error);
    return res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Endpoint para obtener perfil del usuario
router.get("/profile", verifyFirebaseToken, async (req, res) => {
  try {
    const firebaseUser = req.firebaseUser;
    
    const user = await pool.query(
      'SELECT * FROM users WHERE auth_id = $1',
      [firebaseUser.uid]
    );

    if (user.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    res.json({
      user: user.rows[0],
      firebase_data: {
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        email_verified: firebaseUser.email_verified
      }
    });
  } catch (error) {
    console.error('❌ Error al obtener perfil:', error);
    return res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Endpoint para obtener mensajes AI del usuario
router.get("/ai-messages", verifyFirebaseToken, async (req, res) => {
  try {
    const firebaseUser = req.firebaseUser;
    
    // Primero obtener el user_id de la base de datos
    const userResult = await pool.query(
      'SELECT id FROM users WHERE auth_id = $1',
      [firebaseUser.uid]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const userId = userResult.rows[0].id;

    // Obtener los mensajes AI del usuario
    const messages = await pool.query(
      'SELECT * FROM ai_messages WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50',
      [userId]
    );

    res.json({
      messages: messages.rows,
      total: messages.rows.length
    });
  } catch (error) {
    console.error('❌ Error al obtener mensajes AI:', error);
    return res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Endpoint para obtener sesiones de terapia del usuario
router.get("/therapy-sessions", verifyFirebaseToken, async (req, res) => {
  try {
    const firebaseUser = req.firebaseUser;
    
    // Primero obtener el user_id de la base de datos
    const userResult = await pool.query(
      'SELECT id FROM users WHERE auth_id = $1',
      [firebaseUser.uid]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const userId = userResult.rows[0].id;

    // Obtener las sesiones de terapia del usuario
    const sessions = await pool.query(`
      SELECT ts.*, 
             u.full_name as therapist_name,
             u.email as therapist_email
      FROM therapy_sessions ts
      JOIN users u ON ts.therapist_id = u.id
      WHERE ts.user_id = $1 
      ORDER BY ts.scheduled_at DESC
    `, [userId]);

    res.json({
      sessions: sessions.rows,
      total: sessions.rows.length
    });
  } catch (error) {
    console.error('❌ Error al obtener sesiones:', error);
    return res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
