// backend/utils/encryptionUtils.js

import crypto from 'crypto';
import dotenv from 'dotenv';
dotenv.config();

const algorithm = 'aes-256-gcm'; 

let ENCRYPTION_KEY;

try {
    // Validar que la variable exista
    if (!process.env.ENCRYPTION_KEY) {
        throw new Error('ENCRYPTION_KEY no configurada en .env');
    }

    // Convertir y validar longitud
    ENCRYPTION_KEY = Buffer.from(process.env.ENCRYPTION_KEY, 'hex');

    if (ENCRYPTION_KEY.length !== 32) {
        throw new Error(`ENCRYPTION_KEY debe ser de 32 bytes (64 caracteres hex). Actual: ${ENCRYPTION_KEY.length} bytes`);
    }
    
} catch (error) {
    console.error('Error en configuración de encriptación:', error.message);
    
    // Fallback para desarrollo
    ENCRYPTION_KEY = crypto.randomBytes(32);
    console.warn('Usando clave temporal. Configura ENCRYPTION_KEY en tu .env');
}

/**
 * Encripta texto usando AES-256-GCM (más seguro que CBC)
 */
function encrypt(text) {
    if (!text || typeof text !== 'string') {
        console.warn('[Cripto] Intento de encriptar texto inválido:', text);
        return text || '';
    }
    
    try {
        // Generar IV único para cada encriptación
        const iv = crypto.randomBytes(16);
        
        const cipher = crypto.createCipheriv(algorithm, ENCRYPTION_KEY, iv);
        
        let encrypted = cipher.update(text, 'utf8', 'hex');
        encrypted += cipher.final('hex');
        
        // Obtener auth tag para GCM
        const authTag = cipher.getAuthTag();
        
        // Combinar IV + authTag + texto encriptado
        const result = iv.toString('hex') + authTag.toString('hex') + encrypted;
        
        console.log(`[Cripto] Texto encriptado: "${text.substring(0, 20)}..." → ${result.substring(0, 20)}...`);
        return result;
        
    } catch (error) {
        console.error('[Cripto] Error encriptando:', error.message);
        return text;
    }
}

/**
 * Desencripta texto con AES-256-GCM
 */
function decrypt(encryptedData) {
    // Si no es string válido, devolver tal cual
    if (!encryptedData || typeof encryptedData !== 'string') {
        return encryptedData;
    }
    
    // Verificar longitud mínima para datos GCM (IV(32) + authTag(32) + data)
    if (encryptedData.length < 64) {
        console.warn('[Cripto] Datos muy cortos para ser encriptados GCM');
        return encryptedData;
    }
    
    try {
        // Extraer componentes (GCM: IV(16 bytes = 32 hex) + authTag(16 bytes = 32 hex) + encryptedText)
        const iv = Buffer.from(encryptedData.substring(0, 32), 'hex');
        const authTag = Buffer.from(encryptedData.substring(32, 64), 'hex');
        const encryptedText = encryptedData.substring(64);
        
        const decipher = crypto.createDecipheriv(algorithm, ENCRYPTION_KEY, iv);
        decipher.setAuthTag(authTag);
        
        let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
        decrypted += decipher.final('utf8');
        return decrypted;
        
    } catch (error) {
        // Manejar errores específicos
        if (error.message.includes('bad decrypt') || 
            error.message.includes('Unsupported state') ||
            error.message.includes('wrong tag')) {
            
            return decryptLegacyCBC(encryptedData);
        }
        
        console.error('[Cripto] Error grave en desencriptación:', error.message);
        return encryptedData;
    }
}

/**
 * Método legacy para compatibilidad con datos encriptados con CBC
 */
function decryptLegacyCBC(encryptedText) {
    if (!encryptedText || typeof encryptedText !== 'string') {
        return encryptedText;
    }
    
    try {
        const LEGACY_IV = Buffer.from(process.env.IV_SECRET || '0'.repeat(32), 'hex').slice(0, 16);
        const legacyCipher = crypto.createDecipheriv('aes-256-cbc', ENCRYPTION_KEY, LEGACY_IV);
        
        let decrypted = legacyCipher.update(encryptedText, 'hex', 'utf8');
        decrypted += legacyCipher.final('utf8');
        
        console.log(`[Cripto] Desencriptado con CBC legacy: "${decrypted.substring(0, 20)}..."`);
        return decrypted;
        
    } catch (error) {
        console.warn('[Cripto] También falló CBC legacy, devolviendo texto original');
        return encryptedText;
    }
}

/**
 * Función para migrar datos antiguos al nuevo formato
 */
function migrateOldData(oldEncryptedText) {
    try {
        // Desencriptar con método antiguo
        const decrypted = decryptLegacyCBC(oldEncryptedText);
        
        // Si se pudo desencriptar, re-encriptar con nuevo método
        if (decrypted && decrypted !== oldEncryptedText) {
            return encrypt(decrypted);
        }
        
        return oldEncryptedText;
    } catch (error) {
        return oldEncryptedText;
    }
}


export { encrypt, decrypt, migrateOldData };