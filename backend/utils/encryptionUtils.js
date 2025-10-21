// backend/utils/encryptionUtils.js
import crypto from 'crypto';

const algorithm = 'aes-256-cbc'; 
// Asegúrate de que estas claves se carguen de forma segura (ej. process.env.ENCRYPTION_KEY)
const ENCRYPTION_KEY = Buffer.from(process.env.ENCRYPTION_KEY, 'hex'); // 32 bytes
const IV_SECRET = Buffer.from(process.env.IV_SECRET, 'hex'); // 16 bytes

function encrypt(text) {
    // Usar un IV fijo para simplicidad, pero idealmente se generaría uno único por mensaje
    // y se guardaría junto al texto encriptado (NO se recomienda en producción)
    const cipher = crypto.createCipheriv(algorithm, ENCRYPTION_KEY, IV_SECRET);
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return encrypted; // Texto encriptado en formato hexadecimal
}

function decrypt(encryptedText) {
    const decipher = crypto.createDecipheriv(algorithm, ENCRYPTION_KEY, IV_SECRET);
    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
}

export { encrypt, decrypt };