// backend/routes/patients.js
const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const verifyFirebaseToken = require('../middlewares/auth_middleware');




router.post('/register', verifyFirebaseToken, async (req, res) => {
  try {

    console.log('Datos recibidos para registro:', req.body);
    const { uid, username, email, phoneNumber, dateOfBirth } = req.body;
    const firebaseUser = req.firebaseUser;

    if (firebaseUser.uid !== uid) {
      return res.status(403).json({ error: 'UID mismatch' });
    }

    // Verificar si paciente ya existe
    const existing = await pool.query('SELECT * FROM patients WHERE auth_id = $1', [uid]);

    if (existing.rows.length > 0) {
      return res.status(400).json({ error: 'Paciente ya registrado' });
    }

    // Insertar paciente con fecha de nacimiento
    const newPatient = await pool.query(
      `INSERT INTO patients (auth_id, username, email, phone_number, date_of_birth)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [uid, username, email, phoneNumber, dateOfBirth]
    );

    res.status(201).json({
      message: 'Paciente registrado exitosamente',
      patient: newPatient.rows[0],
    });
  } catch (error) {
    console.error('Error al registrar paciente:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});


router.get('/profile', verifyFirebaseToken, async (req, res) => {
  try {
    const uid = req.firebaseUser.uid;

    const result = await pool.query('SELECT * FROM patients WHERE auth_id = $1', [uid]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Paciente no encontrado' });
    }

    res.json({ patient: result.rows[0] });
  } catch (error) {
    console.error('Error al obtener perfil paciente:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.put('/profile', verifyFirebaseToken, async (req, res) => {
  try {
    const uid = req.firebaseUser.uid;
    const { username, email, phoneNumber } = req.body;

    const result = await pool.query(
      `UPDATE patients SET username = $1, email = $2, phone_number = $3 WHERE auth_id = $4 RETURNING *`,
      [username, email, phoneNumber, uid]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Paciente no encontrado' });
    }

    res.json({ message: 'Perfil actualizado', patient: result.rows[0] });
  } catch (error) {
    console.error('Error al actualizar perfil paciente:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
