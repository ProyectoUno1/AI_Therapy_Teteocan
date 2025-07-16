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

// Exporta la aplicacion para que pueda ser utilizada en otros archivos
module.exports = app;