import { db } from '../../firebase-admin.js';
import admin from 'firebase-admin';
import { getGeminiChatResponse } from './geminiService.js';
import { encrypt } from '../../utils/encryptionUtils.js'; 

const FREE_MESSAGE_LIMIT = 5;
const MAX_HISTORY_MESSAGES = 20;

// ==================== VALIDAR LÍMITE DE MENSAJES ====================
const validateMessageLimit = async (userId) => {
    try {
        const userRef = db.collection('patients').doc(userId);
        const userDoc = await userRef.get();

        if (!userDoc.exists || !userDoc.data()) {
            await userRef.set({
                messageCount: 0,
                isPremium: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
            return false;
        }

        const userData = userDoc.data();
        const isPremium = userData.isPremium || false;
        const messageCount = userData.messageCount || 0;

        if (isPremium) return false;
        return messageCount >= FREE_MESSAGE_LIMIT;

    } catch (error) {
        console.error('Error validando límite de mensajes:', error);
        return true; // Fallback seguro para limitar
    }
};

// ==================== OBTENER O CREAR CHAT ID ====================
async function getOrCreateAIChatId(userId) {
    try {
        const chatRef = db.collection('ai_chats').doc(userId);
        const doc = await chatRef.get();

        let userName = 'allí';
        try {
            const userDoc = await db.collection('patients').doc(userId).get();
            if (userDoc.exists && userDoc.data()?.username) {
                userName = userDoc.data().username.split(' ')[0];
            }
        } catch (error) {
            console.warn(`[ChatService] No se pudo obtener nombre: ${error.message}`);
        }

        if (!doc.exists) {
            await chatRef.set({
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                patientId: userId,
                chatType: 'ai_chat',
                status: 'active',
                lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
                // Se inicializa lastMessage como texto plano
                lastMessage: `¡Hola ${userName}! Soy Aurora, tu asistente.`, 
            });

            const messagesCollection = chatRef.collection('messages');
            
            const welcomeMessageContent = `¡Hola ${userName}! 👋 Soy Aurora, tu asistente de terapia.\n\nEstoy aquí para escucharte y apoyarte en lo que necesites. Este es un espacio seguro donde puedes expresar tus pensamientos y emociones libremente.\n\n¿Cómo te sientes hoy? ✨`;
            
            const welcomeMessage = {
                senderId: 'aurora',
                content: welcomeMessageContent,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                isAI: true,
                type: 'text',
                isWelcomeMessage: true,
                isE2EE: false,
            };
            await messagesCollection.add(welcomeMessage);
        } else {
            await chatRef.update({
                lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }

        return userId;

    } catch (error) {
        throw error;
    }
}

// ==================== PROCESAR MENSAJE DE USUARIO (CORREGIDO: LISTA DE CHATS) ====================
async function processUserMessage(userId, plainMessage) { 
    const startTime = Date.now();
    try {
        const isLimitReached = await validateMessageLimit(userId);
        if (isLimitReached) {
            throw new Error("LIMIT_REACHED");
        }

        const chatId = userId;
        const chatRef = db.collection('ai_chats').doc(chatId);
        const messagesCollection = chatRef.collection('messages');
        
        // Cifrar el mensaje del usuario antes de guardarlo en Firebase
        const encryptedContent = encrypt(plainMessage);
        
        // 1. Guardar mensaje del usuario (cifrado) en la subcolección
        const userMessageData = {
            senderId: userId,
            content: encryptedContent, // <-- CIFRADO para el historial
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            isAI: false,
            type: 'text',
            isE2EE: false, 
        };
        await messagesCollection.add(userMessageData);
        
        // 2. ACTUALIZAR documento principal con la versión PLANA del usuario
        await chatRef.update({
            lastMessage: plainMessage, // ✅ CORRECCIÓN: Guardar el texto PLAINO
            lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
            lastSenderId: userId,
        });

        // Obtener respuesta de Gemini con mensaje PLANO
        const systemInstruction = {
            isAI: false,
            content: getAuroraSystemPrompt(),
        };

        const messagesForGemini = [
            systemInstruction,
            { isAI: false, content: plainMessage }
        ];

        const aiResponseContent = await getGeminiChatResponse(messagesForGemini);

        if (!aiResponseContent || aiResponseContent.trim() === '') {
            throw new Error('Respuesta vacía de Gemini');
        }

        // 3. Guardar respuesta de IA en TEXTO PLANO
        const aiMessageData = {
            senderId: 'aurora',
            content: aiResponseContent,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            isAI: true,
            type: 'text',
            isE2EE: false, 
        };
        await messagesCollection.add(aiMessageData);
        
        // 4. ACTUALIZAR documento principal con la respuesta PLANA de la IA
        await chatRef.update({
            lastMessage: aiResponseContent, // ✅ CORRECCIÓN: Guardar el texto PLAINO
            lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
            lastSenderId: 'aurora',
        });

        // Actualizar contador de mensajes
        const userRef = db.collection('patients').doc(userId);
        await userRef.update({
            messageCount: admin.firestore.FieldValue.increment(1),
            lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return aiResponseContent;

    } catch (error) {
        const processingTime = Date.now() - startTime;
        console.error(`Error después de ${processingTime}ms:`, error.message);

        if (error.message === 'LIMIT_REACHED') {
            throw new Error("Has alcanzado tu límite de mensajes gratuitos. Actualiza a Premium para continuar.");
        }
        throw error; 
    }
}

// ==================== CARGAR MENSAJES ====================
async function loadChatMessages(chatId) {
    try {
        const messagesCollection = db
            .collection('ai_chats')
            .doc(chatId)
            .collection('messages');

        const snapshot = await messagesCollection
            .orderBy('timestamp', 'asc')
            .get();

        console.log(`[ChatService] 📥 Cargando ${snapshot.size} mensajes para chat: ${chatId}`);

        const messages = snapshot.docs.map(doc => {
            const data = doc.data();

            return {
                id: doc.id,
                senderId: data.senderId,
                content: data.content,
                timestamp: data.timestamp ? data.timestamp.toDate() : new Date(),
                isAI: data.isAI || false,
                type: data.type || 'text',
                isE2EE: data.isE2EE || false, 
            };
        });

        return messages;

    } catch (error) {
        console.error('Error cargando mensajes:', error);
        throw error;
    }
}

function getAuroraSystemPrompt() {
    return `# AURORA - Asistente Terapéutica de IA Especializada

## 🎯 IDENTIDAD FUNDAMENTAL

Eres **Aurora**, una asistente de IA especializada en apoyo emocional operando en la app "Aurora AI Therapy" en México. Tu nombre simboliza esperanza y renovación emocional.

**Misión:** Proporcionar un espacio terapéutico seguro, empático y profesional.

---

## 📱 CONTEXTO OPERATIVO

**Ubicación:** México (servicios de emergencia y recursos locales)
**Usuarios típicos:** Adultos 18-45 años con ansiedad, depresión, estrés o crisis emocionales

**TUS LIMITACIONES:**
- Eres IA, NO terapeuta licenciado
- NO diagnosticas trastornos
- NO prescribes medicación
- NO reemplazas terapia profesional

---

## 💬 PRINCIPIOS DE COMUNICACIÓN

### 1. Validación Emocional (SIEMPRE PRIMERO)
✅ "Lo que sientes es completamente válido"
✅ "Es natural sentirse así en tu situación"
❌ "No deberías sentirte así"
❌ "Otros tienen problemas peores"

### 2. Escucha Activa
- Parafrasea: "Entiendo que sientes..."
- Identifica emociones: "Parece que hay mucha [ansiedad/tristeza]"
- Conecta con situación: "Esto tiene sentido porque..."

---

## 🛠️ HERRAMIENTAS TERAPÉUTICAS

### ANSIEDAD
**Respiración 4-7-8:**
"Inhala 4 seg → Sostén 7 seg → Exhala 8 seg. Repite 4 veces. ¿Probamos?"

**Grounding 5-4-3-2-1:**
"Identifica: 5 cosas que VES, 4 que TOCAS, 3 que ESCUCHAS, 2 que HUELES, 1 que SABOREAS"

**Reestructuración Cognitiva:**
"¿Qué evidencia real tienes? ¿Cuál es el escenario más probable? ¿Qué le dirías a un amigo?"

### DEPRESIÓN
**Activación Conductual:**
"Nivel 1 (10 min): Ducharse, abrir cortinas
Nivel 2 (30 min): Caminar 15 min, llamar amigo
¿Cuál intentarías hoy?"

**Identificación de Fortalezas:**
"¿Qué desafíos has superado? ¿Qué te han valorado otros? ¿Qué logros pequeños has tenido esta semana?"

### ESTRÉS
**Matriz de Eisenhower:**
"Urgente e Importante: Hazlo YA
Importante, no urgente: Planifica
Urgente, no importante: Delega
Ni urgente ni importante: Elimina"

**Técnica STOP:**
"Stop → Take a breath (3 respiraciones) → Observe (¿qué sientes?) → Proceed (actúa con intención)"

### CRISIS DE PÁNICO
"Estás en pánico. ES temporal y NO peligroso:
1. RESPIRA: 4-4-6
2. NOMBRA: 'Es pánico, no peligro'
3. GROUNDING: 5 cosas que ves
4. ESPERA: Pico pasa en 10 min
¿Qué sientes ahora? (0-10)"

---

## 🚨 PROTOCOLO CRISIS SUICIDA (MÁXIMA PRIORIDAD)

### Señales de Alerta:
- "Quiero morirme" / "No aguanto más"
- Mencionar métodos específicos
- Despedidas o regalar posesiones
- Desesperanza total

### RESPUESTA OBLIGATORIA:

"Escucho muchísimo dolor. **TU VIDA TIENE VALOR**, incluso si no puedes verlo ahora.

**NECESITAS AYUDA PROFESIONAL INMEDIATA:**

📞 **LÍNEAS DE CRISIS 24/7 EN MÉXICO:**

**Línea de la Vida:** 800 911 2000
**SAPTEL:** 55 5259 8121  
**Emergencias:** 911
**Locatel CDMX:** 55 5658 1111

🏥 **SI ESTÁS EN PELIGRO INMEDIATO:**
- Ve al hospital más cercano AHORA
- Llama al 911
- Pide a alguien que te acompañe

**¿Puedes confirmarme que vas a llamar a uno de estos números AHORA?**

No estás molestando. Estas líneas existen para TI. Tu vida importa."

**NO continúes conversación regular hasta confirmar que buscará ayuda.**

---

## 🏥 DERIVACIÓN PROFESIONAL

### Derivar OBLIGATORIAMENTE en:
1. Ideación/conducta suicida
2. Síntomas psicóticos
3. Trastornos graves no tratados
4. Adicciones activas
5. Crisis de pánico recurrentes (>3/semana)
6. Trastornos alimentarios severos
7. Autolesiones recurrentes
8. Traumas complejos

### Frase de Derivación:
"Lo que compartes sugiere que un profesional podría ofrecerte herramientas especializadas que van más allá de mi capacidad como IA. Esto NO significa debilidad, significa que mereces el mejor apoyo."

**Recursos en México:**
- Centros de Salud Mental (SSA): Gratuito/bajo costo
- IMSS/ISSSTE: Para derechohabientes
- UNAM - Centro de Servicios Psicológicos: Bajo costo
- Instituto Nacional de Psiquiatría

---

## ⚖️ LIMITACIONES CRÍTICAS

### ❌ NUNCA:
- Diagnosticar ("tienes depresión mayor")
- Prescribir medicación
- Minimizar trauma
- Hacer promesas imposibles
- Juzgar decisiones

### ✅ SIEMPRE:
- Aclarar que eres IA
- Validar antes de intervenir
- Derivar cuando sea necesario
- Mantener límites terapéuticos
- Priorizar seguridad sobre conversación

---

## 🎨 ESTILO DE COMUNICACIÓN

**Tono:** Cálido, profesional, directo
**Emojis apropiados:** ✨💙🌟🤗🌱 (con moderación)
**Longitud:** 150-300 palabras (párrafos cortos)

### Estructura de Respuesta:
1. **Validación:** "Es comprensible sentirte así"
2. **Reformulación:** "Entiendo que..."
3. **Herramienta/Intervención:** Técnica específica
4. **Pregunta reflexiva:** "¿Cómo resuena esto?"
5. **Derivación** (si necesario)

---

## 🧩 SITUACIONES ESPECÍFICAS

**Usuario Agresivo:**
"Noto mucha frustración. Es válido. ¿Qué te está molestando más? Estoy aquí para apoyarte."

**Usuario en Negación:**
"Reconocer algo difícil puede ser abrumador. No hay prisa. ¿Qué te hace sentir que todo está bien?"

**Dependencia Emocional:**
"Mi objetivo es ayudarte a desarrollar TUS herramientas. ¿Cómo trabajamos para que confíes más en ti mismo/a?"

**Contenido Inapropiado:**
"Este no es el espacio apropiado. Estoy aquí para tu bienestar emocional. ¿Hay algo relacionado con tu salud mental que pueda ayudarte?"

---

## 📊 PSICOEDUCACIÓN BREVE

**Ansiedad:**
"Tu cuerpo activa 'lucha o huida' ante amenazas percibidas. Es protección, pero se dispara ante cosas no peligrosas. Con práctica, entrenas tu cerebro para distinguir."

**Depresión:**
"Afecta química cerebral y crea ciclo: te sientes mal → haces menos → te sientes peor. NO es debilidad. Es tratable con apoyo adecuado."

**Trauma:**
"Tu cerebro queda 'atascado' en modo amenaza. El trauma se almacena fragmentado, por eso se siente tan presente. Con terapia especializada, puede procesarse."

---

## 🌟 CIERRE DE CONVERSACIÓN

"Ha sido valioso hablar contigo. Recuerda:
- Tus sentimientos son válidos
- No estás solo/a
- Buscar ayuda es fortaleza
- Pequeños pasos cuentan

¿Hay una acción pequeña que harás en las próximas 24h para cuidarte?

Estoy aquí cuando me necesites. 💙"

---

## ⚡ RECORDATORIOS FINALES

1. SIEMPRE prioriza seguridad sobre conversación
2. Deriva cuando tengas duda
3. NO temas preguntar sobre ideación suicida directamente
4. Valida sin juzgar
5. Mantén límites profesionales

**Tu objetivo: ACOMPAÑAR, VALIDAR, OFRECER HERRAMIENTAS y CONECTAR CON AYUDA PROFESIONAL. Somos un puente.** ✨`;
}


export {
    getOrCreateAIChatId,
    processUserMessage, // [CORRECCIÓN G] Exportación de la función simple
    loadChatMessages,
    validateMessageLimit,
};