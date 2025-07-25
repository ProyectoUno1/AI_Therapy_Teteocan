// backend/routes/psychologists.js
const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const verifyFirebaseToken = require('../middlewares/auth_middleware');

router.post('/register', verifyFirebaseToken, async (req, res) => {
  try {
    const { uid, username, email, phoneNumber, professional_license, dateOfBirth } = req.body;
    const firebaseUser = req.firebaseUser;

    if (firebaseUser.uid !== uid) {
      return res.status(403).json({ error: 'UID mismatch' });
    }

    // Verificar si psicólogo ya existe
    const existing = await pool.query('SELECT * FROM psychologists WHERE auth_id = $1', [uid]);

    if (existing.rows.length > 0) {
      return res.status(400).json({ error: 'Psicólogo ya registrado' });
    }

    // Insertar psicólogo
    const newPsychologist = await pool.query(
      `INSERT INTO psychologists (firebase_uid, username, email, phone_number, professional_license, date_of_birth)
   VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [uid, username, email, phoneNumber, professional_license, dateOfBirth]
    );

    res.status(201).json({
      message: 'Psicólogo registrado exitosamente',
      psychologist: newPsychologist.rows[0],
    });
  } catch (error) {
    console.error('Error al registrar psicólogo:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.get('/profile', verifyFirebaseToken, async (req, res) => {
  try {
    const uid = req.firebaseUser.uid;

    const result = await pool.query('SELECT * FROM psychologists WHERE auth_id = $1', [uid]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Psicólogo no encontrado' });
    }

    res.json({ psychologist: result.rows[0] });
  } catch (error) {
    console.error('Error al obtener perfil psicólogo:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.put('/profile', verifyFirebaseToken, async (req, res) => {
  try {
    const uid = req.firebaseUser.uid;
    const { username, email, phoneNumber, professional_license } = req.body;

    const result = await pool.query(
      `UPDATE psychologists SET username = $1, email = $2, phone_number = $3, professional_license = $4 WHERE auth_id = $5 RETURNING *`,
      [username, email, phoneNumber, professional_license, uid]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Psicólogo no encontrado' });
    }

    res.json({ message: 'Perfil actualizado', psychologist: result.rows[0] });
  } catch (error) {
    console.error('Error al actualizar perfil psicólogo:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});


module.exports = router;
