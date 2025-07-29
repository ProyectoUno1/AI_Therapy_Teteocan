/* app.js tiene el proposito de definir la logica global de la aplicacion*/

const express = require('express');
const cors = require('cors');
const app = express();


// Middleware: permite que la aplicacion reciba peticiones de otros dominios
app.use(cors());
// Middleware: interpreta el cuerpo de las peticiones como formato JSON
app.use(express.json());

// Rutas base
app.get('/', (req, res) => {
  res.send('¡Aurora Backend funcionando!');
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