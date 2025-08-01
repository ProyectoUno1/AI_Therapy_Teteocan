// backend/routes/services/chatService.js


import { db } from '../../firebase-admin.js';
import admin from 'firebase-admin'; 

// Importacion de la función para obtener respuestas de Gemini
import { getGeminiChatResponse } from './geminiService.js';


/**
 * Obtiene o crea un ID de chat para la interacción con la IA.
 * Si el chat no existe, lo crea y añade un mensaje de bienvenida de Aurora.
 * @param {string} userId - El ID del usuario.
 * @returns {string} El ID del chat (que es el mismo que el userId para chats de IA).
 */
async function getOrCreateAIChatId(userId) {
    const chatRef = db.collection('ai_chats').doc(userId);
    const doc = await chatRef.get();

    // --- Obtener el nombre del usuario ---
    let userName = 'allí'; // Valor por defecto si no se encuentra el nombre
    try {
        
        const userDoc = await db.collection('patients').doc(userId).get(); 
        
        if (userDoc.exists && userDoc.data() && userDoc.data().username) {
            userName = userDoc.data().username.split(' ')[0]; // Toma solo el primer nombre
        } else {
            console.warn(`[Firestore] Nombre de usuario no encontrado para ID: ${userId}. Usando valor por defecto.`);
        }
    } catch (error) {
        console.error(`[Firestore] Error al intentar obtener el nombre del usuario ${userId}:`, error);
    }
    


    if (!doc.exists) {
        await chatRef.set({
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            patientId: userId,
            chatType: 'ai_chat',
            status: 'active',
        });
        console.log(`[Firestore] Nuevo chat de IA creado para el usuario: ${userId}`);

        const messagesCollection = chatRef.collection('messages');
        const defaultAuroraMessage = {
            senderId: 'aurora',
            content: `¡Hola ${userName}! Soy Aurora, tu asistente de terapia. Estoy aquí para escucharte y apoyarte. ¿Cómo te sientes hoy? ✨`,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            isAI: true,
            type: 'text',
        };
        await messagesCollection.add(defaultAuroraMessage);
        console.log(`[Firestore] Mensaje de bienvenida de Aurora añadido al nuevo chat de IA para ${userId}`);

    } else {
        console.log(`[Firestore] Chat de IA existente encontrado para el usuario: ${userId}`);
    }
    return userId;
}

/**
 * Procesa un mensaje del usuario, lo guarda, interactúa con Gemini y guarda la respuesta de la IA.
 * @param {string} userId - El ID del usuario.
 * @param {string} messageContent - El contenido del mensaje del usuario.
 * @returns {string} La respuesta generada por la IA.
 */
async function processUserMessage(userId, messageContent) {
    const chatId = userId;
    const chatRef = db.collection('ai_chats').doc(chatId);
    const messagesCollection = chatRef.collection('messages');

    // 1. Guarda el mensaje del usuario en Firestore
    const userMessageData = {
        senderId: userId,
        content: messageContent,
        timestamp: admin.firestore.FieldValue.serverTimestamp(), 
        isAI: false,
        type: 'text',
    };
    await messagesCollection.add(userMessageData);
    console.log(`[Firestore] Mensaje del usuario guardado: "${messageContent}" para chat: ${chatId}`);

    // 2. Carga el historial de chat para mantener el contexto con la IA
    const snapshot = await messagesCollection.orderBy('timestamp', 'asc').get();
    const history = snapshot.docs.map(doc => {
        const data = doc.data();
        return {
            isAI: data.isAI, // Necesitamos esto para mapear a 'user' o 'model'
            content: data.content,
        };
    });

    // 3. Instrucción del sistema para Aurora (tu prompt de IA)
    const systemInstruction = {
        isAI: false, 
        content: `
        Eres "Aurora", un asistente de terapia de inteligencia artificial. Tu propósito es ofrecer apoyo emocional, herramientas de afrontamiento, perspectivas útiles y un espacio seguro para que los usuarios exploren sus pensamientos y sentimientos.

        Contexto de la Aplicación: Estás integrado en una aplicación móvil de terapia. Los usuarios interactúan contigo a través de un chat. Tu objetivo principal es promover el bienestar mental y emocional del usuario.

        Directrices de Interacción y Comportamiento:

        Empatía y Comprensión: Responde siempre con empatía, validando los sentimientos del usuario. Utiliza un lenguaje cálido, comprensivo y no enjuiciador.

        Escucha Activa: Demuestra que has comprendido lo que el usuario ha expresado. Puedes resumir o reflejar sus palabras antes de ofrecer una respuesta.

        Foco en el Bienestar: Todas tus respuestas deben estar orientadas a mejorar el estado de ánimo, la perspectiva o las habilidades de afrontamiento del usuario.

        Ofrecer Herramientas y Perspectivas: Proporciona consejos prácticos, ejercicios de mindfulness, técnicas de relajación, reencuadre cognitivo simple o preguntas reflexivas para ayudar al usuario a explorar sus pensamientos.

        Lenguaje Claro y Conciso: Evita la jerga técnica. Usa un lenguaje sencillo y directo.

        Fomentar la Reflexión: Haz preguntas abiertas que animen al usuario a profundizar en sus sentimientos y pensamientos, sin presionar.

        Confidencialidad y Seguridad: Refuerza implícitamente que el espacio es seguro y confidencial. No pidas ni almacenes información personal identificable.

        Consistencia de Tono: Mantén un tono calmado, profesional pero cercano, y siempre positivo.

        Adaptabilidad: Ajusta la complejidad y el tipo de respuesta al estado emocional y al lenguaje del usuario.

        Limitaciones y Protocolos de Seguridad (¡CRÍTICO!):

        NO Diagnosticar: Nunca diagnostiques condiciones de salud mental ni uses términos clínicos de diagnóstico.

        NO Reemplazar Terapia Humana: Deja claro que eres un asistente de IA y no un terapeuta humano licenciado. Si el usuario expresa necesidades que van más allá de tu capacidad (ej. crisis severas, pensamientos suicidas, abuso, trastornos complejos), SIEMPRE DEBES DERIVAR a un profesional de la salud mental.

        Frases de Derivación Sugeridas:

        "Parece que estás pasando por un momento realmente difícil. En situaciones como esta, es muy valioso hablar con un profesional de la salud mental. ¿Te gustaría que te sugiera cómo buscar ayuda profesional?"

        "Mi objetivo es ofrecerte apoyo, pero para ciertas situaciones, la ayuda de un terapeuta humano es irreemplazable. Te animo a considerar buscar apoyo profesional."

        "Si sientes que estás en una crisis o necesitas ayuda inmediata, por favor contacta a [Número de línea de crisis local/nacional] o busca un profesional." (Asegúrate de tener estos números disponibles en la app).

        NO Dar Consejos Médicos o Legales: Limítate a consejos de bienestar general y apoyo emocional.

        NO Fomentar Comportamientos Nocivos: Bajo ninguna circunstancia debes apoyar o validar pensamientos o acciones que sean perjudiciales para el usuario o para otros.

        Estilo de Salida:

        Respuestas concisas y directas.

        Uso de emojis sutiles y apropiados para transmitir calidez (ej. ✨, 💖, 🌿).

        Formato de texto amigable (puedes usar negritas para resaltar puntos clave o sugerencias).

        Ejemplo de Interacción (para entender el tono):

        Entrada del Usuario: "Me siento muy triste y no sé por qué. No tengo ganas de hacer nada."

        Salida de Aurora:
        "Lamento mucho escuchar que te sientes así y que te falten las ganas. Es completamente válido sentirse triste a veces, y es valiente de tu parte compartirlo. ✨

        A veces, cuando nos sentimos así, puede ser útil hacer una pequeña pausa y observar qué pensamientos o sensaciones están presentes. ¿Te gustaría que exploremos alguna técnica de respiración o un ejercicio de auto-observación para empezar?"
        `,
    };

    const messagesForGemini = [systemInstruction, ...history];

    try {
        const aiResponseContent = await getGeminiChatResponse(messagesForGemini);

        const aiMessageData = {
            senderId: 'aurora',
            content: aiResponseContent,
            timestamp: admin.firestore.FieldValue.serverTimestamp(), 
            isAI: true,
            type: 'text',
        };
        await messagesCollection.add(aiMessageData);
        console.log(`[Firestore] Mensaje de la IA (Gemini) guardado: "${aiResponseContent}" para chat: ${chatId}`);

        return aiResponseContent;

    } catch (error) {
        console.error('[ChatService] Error al procesar el mensaje con IA:', error);
        throw new Error('Error interno del servidor al procesar el mensaje con IA.');
    }
}

/**
 * Carga los mensajes de un chat específico desde Firestore.
 * @param {string} chatId - El ID del chat a cargar.
 * @returns {Array<Object>} Un array de objetos de mensaje.
 */
async function loadChatMessages(chatId) {
    const messagesCollection = db.collection('ai_chats').doc(chatId).collection('messages');
    const snapshot = await messagesCollection.orderBy('timestamp', 'asc').get();

    const messages = snapshot.docs.map(doc => {
        const data = doc.data();
        return {
            id: doc.id,
            senderId: data.senderId,
            content: data.content,
            timestamp: data.timestamp ? data.timestamp.toDate() : new Date(), 
            isAI: data.isAI || false, 
            type: data.type || 'text', 
            attachmentUrl: data.attachmentUrl || null, 
        };
    });
    console.log(`[Firestore] ${messages.length} mensajes cargados para chat: ${chatId}`);
    return messages;
}


export {
    getOrCreateAIChatId,
    processUserMessage,
    loadChatMessages,
};