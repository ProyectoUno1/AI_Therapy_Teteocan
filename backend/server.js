
import app from './app.js'; 
import dotenv from 'dotenv'; 

// Cargar variables de entorno desde .env
dotenv.config();

// Usar puerto desde .env o 3000 por defecto
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Servidor escuchando en http://localhost:${PORT}`);
});
