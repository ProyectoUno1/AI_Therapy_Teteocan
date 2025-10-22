// generateKeysV2.js
import crypto from 'crypto';

const encryptionKey = crypto.randomBytes(32).toString('hex'); // 64 caracteres

console.log('🔐 NUEVA CONFIGURACIÓN PARA .env:');
console.log('');
console.log(`ENCRYPTION_KEY=${encryptionKey}`);
console.log('');
console.log('📝 ELIMINA la variable IV_SECRET de tu .env');
console.log('✅ La nueva configuración usa GCM con IV aleatorio');