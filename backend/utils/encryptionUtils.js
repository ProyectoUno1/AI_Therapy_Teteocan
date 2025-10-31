// backend/utils/encryptionUtils.js
// ✅ ESTE ARCHIVO YA ESTÁ CORRECTO - NO TOCAR

import crypto from 'crypto';
import dotenv from 'dotenv';
dotenv.config();

const algorithm = 'aes-256-gcm'; 

let ENCRYPTION_KEY;

try {
    if (!process.env.ENCRYPTION_KEY) {
        throw new Error('ENCRYPTION_KEY no configurada en .env');
    }

    ENCRYPTION_KEY = Buffer.from(process.env.ENCRYPTION_KEY, 'hex');

    if (ENCRYPTION_KEY.length !== 32) {
        throw new Error(`ENCRYPTION_KEY debe ser de 32 bytes (64 caracteres hex). Actual: ${ENCRYPTION_KEY.length} bytes`);
    }
    
} catch (error) {
    console.error('❌ Error en configuración de encriptación:', error.message);
    ENCRYPTION_KEY = crypto.randomBytes(32);
    console.warn('⚠️ Usando clave temporal. Configura ENCRYPTION_KEY en tu .env');
}

/**
 * Encripta texto usando AES-256-GCM
 */
function encrypt(text) {
    if (!text || typeof text !== 'string') {
        console.warn('[Cripto] Intento de encriptar texto inválido:', text);
        return text || '';
    }
    
    try {
        const iv = crypto.randomBytes(16);
        const cipher = crypto.createCipheriv(algorithm, ENCRYPTION_KEY, iv);
        
        let encrypted = cipher.update(text, 'utf8', 'hex');
        encrypted += cipher.final('hex');
        
        const authTag = cipher.getAuthTag();
        const result = iv.toString('hex') + authTag.toString('hex') + encrypted;
        
        console.log(`[Cripto] ✅ Texto encriptado: "${text.substring(0, 20)}..." → ${result.substring(0, 20)}...`);
        return result;
        
    } catch (error) {
        console.error('[Cripto] ❌ Error encriptando:', error.message);
        return text;
    }
}

/**
 * Desencripta texto con AES-256-GCM
 */
function decrypt(encryptedData) {
    if (!encryptedData || typeof encryptedData !== 'string') {
        return encryptedData;
    }
    
    if (encryptedData.length < 64) {
        console.warn('[Cripto] Datos muy cortos para ser encriptados GCM');
        return encryptedData;
    }
    
    try {
        const iv = Buffer.from(encryptedData.substring(0, 32), 'hex');
        const authTag = Buffer.from(encryptedData.substring(32, 64), 'hex');
        const encryptedText = encryptedData.substring(64);
        
        const decipher = crypto.createDecipheriv(algorithm, ENCRYPTION_KEY, iv);
        decipher.setAuthTag(authTag);
        
        let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
        decrypted += decipher.final('utf8');
        
        console.log(`[Cripto] ✅ Desencriptado: "${decrypted.substring(0, 20)}..."`);
        return decrypted;
        
    } catch (error) {
        if (error.message.includes('bad decrypt') || 
            error.message.includes('Unsupported state') ||
            error.message.includes('wrong tag')) {
            
            console.warn('[Cripto] Intentando método legacy CBC...');
            return decryptLegacyCBC(encryptedData);
        }
        
        console.error('[Cripto] ❌ Error grave en desencriptación:', error.message);
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
        
        console.log(`[Cripto] ✅ Desencriptado con CBC legacy: "${decrypted.substring(0, 20)}..."`);
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
        const decrypted = decryptLegacyCBC(oldEncryptedText);
        
        if (decrypted && decrypted !== oldEncryptedText) {
            return encrypt(decrypted);
        }
        
        return oldEncryptedText;
    } catch (error) {
        return oldEncryptedText;
    }
}

export { encrypt, decrypt, migrateOldData };