/* app.js tiene el proposito de definir la logica global de la aplicacion*/

const express = require('express');
const cors = require('cors');
const app = express();
const pool = require('./config/db');

// Middleware: permite que la aplicacion reciba peticiones de otros dominios
app.use(cors());
// Middleware: interpreta el cuerpo de las peticiones como formato JSON
app.use(express.json());

// Rutas base
app.get('/', (req, res) => {
  res.send('¡Aurora Backend funcionando!');
});

// Ruta de prueba: obtener fecha actual de PostgreSQL
app.get('/api/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({
      message: 'Successful database connection with Neon PostgreSQL',
      timestamp: result.rows[0].now,
    });
  } catch (error) {
    console.error('Error en consulta:', error);
    res.status(500).json({ error: 'Error en la conexión con PostgreSQL' });
  }
});

// Add global error handler in app.js
app.use((error, req, res, next) => {
  console.error('Global error:', error);
  res.status(500).json({ 
    error: process.env.NODE_ENV === 'production' ? 'Internal server error' : error.message 
  });
});


const patientsRoutes = require('./routes/patients');
const psychologistsRoutes = require('./routes/psychologists');

app.use('/api/patients', patientsRoutes);
app.use('/api/psychologists', psychologistsRoutes);


// Exporta la aplicacion para que pueda ser utilizada en otros archivos
module.exports = app;