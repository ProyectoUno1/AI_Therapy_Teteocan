/*server.js tiene el proposito de iniciar el servidor web con Express.js*/

import app from './app.js'; // Usa import, y añade .js a las importaciones locales
import dotenv from 'dotenv'; 

// Cargar variables de entorno desde .env
dotenv.config();

// Usar puerto desde .env o 3000 por defecto
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Servidor escuchando en http://localhost:${PORT}`);
});
