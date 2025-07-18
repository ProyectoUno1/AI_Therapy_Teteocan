/* db.js maneja la conexión a la base de datos PostgreSQL*/

// Importar dotenv para manejar variables de entorno y pg para la conexión a PostgreSQL
const { Pool } = require('pg');
const dotenv = require('dotenv');

// Cargar las variables de entorno desde el archivo .env
dotenv.config();
const isSSL = process.env.DB_SSL === 'true'; // Trabajar con SSL si está habilitado

// Crear un pool de conexiones a la base de datos PostgreSQL
const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
    ssl: isSSL ? { rejectUnauthorized: false } : false,
});

// Probar la conexión a la base de datos
pool.connect()
    .then((client) => {
        console.log('Conexión a la base de datos Neon PostgreSQL exitosa');
        client.release();
    })
    .catch((err) => {
        console.error('Error al conectar a la base de datos Neon PostgreSQL:', err.message);
    });

// Exportar el pool para que pueda ser utilizado en otras partes de la aplicación
module.exports = pool;