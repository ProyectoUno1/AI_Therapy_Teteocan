/*server.js tiene el proposito de iniciar el servidor web con Express.js*/

const app = require('./app');
const dotenv = require('dotenv');


// Cargar variables de entorno desde .env
dotenv.config();

// Usar puerto desde .env o 3000 por defecto
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Servidor escuchando en http://localhost:${PORT}`);
});
