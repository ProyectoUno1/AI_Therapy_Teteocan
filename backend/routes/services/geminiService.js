// backend/routes/services/geminiService.js (CORREGIDO - ERROR 500 RESUELTO)

import dotenv from 'dotenv';
dotenv.config();
import { GoogleGenerativeAI } from '@google/generative-ai';

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
const GEMINI_MODEL = "gemini-2.0-flash-exp"; 

/**
 * Genera una respuesta de chat usando Gemini AI
 * @param {Array} messages - Array de mensajes del historial
 * @returns {string} Respuesta generada por la IA
 */
async function getGeminiChatResponse(messages) {
    try {
        const systemInstruction = messages[0]; 
        const conversationHistory = messages.slice(1, -1); 
        const currentUserMessage = messages[messages.length - 1]; 

        console.log(`📊 Procesando ${conversationHistory.length} mensajes de historial`);

        // Configurar el modelo
        const model = genAI.getGenerativeModel({ 
            model: GEMINI_MODEL,
            systemInstruction: systemInstruction.content, 
        });

        // ✅ Convertir y limpiar historial
        let geminiHistory = conversationHistory
            .filter(msg => !msg.isWelcomeMessage) // Eliminar mensaje de bienvenida
            .map(msg => ({
                role: msg.isAI ? 'model' : 'user',
                parts: [{ text: msg.content }],
            }));

        console.log(`📋 Historial inicial: ${geminiHistory.length} mensajes`);

        // ✅ CRÍTICO: Asegurar que comienza con 'user'
        while (geminiHistory.length > 0 && geminiHistory[0].role === 'model') {
            console.warn('⚠️ Eliminando mensaje "model" del inicio del historial');
            geminiHistory.shift();
        }

        // ✅ Eliminar mensajes consecutivos del mismo rol
        geminiHistory = geminiHistory.filter((msg, index) => {
            if (index === 0) return true;
            if (msg.role === geminiHistory[index - 1].role) {
                console.warn(`⚠️ Eliminando mensaje duplicado del rol: ${msg.role}`);
                return false;
            }
            return true;
        });

        // ✅ Si el historial termina con 'model', eliminar el último
        if (geminiHistory.length > 0 && geminiHistory[geminiHistory.length - 1].role === 'model') {
            console.warn('⚠️ Eliminando último mensaje "model" del historial');
            geminiHistory.pop();
        }

        console.log(`✅ Historial limpio: ${geminiHistory.length} mensajes`);
        console.log(`📝 Mensaje actual: "${currentUserMessage.content.substring(0, 50)}..."`);

        // Iniciar chat con historial limpio
        const chat = model.startChat({
            history: geminiHistory,
            generationConfig: {
                maxOutputTokens: 800,
                temperature: 0.8,
                topP: 0.95,
                topK: 40,
            },
        });

        // Enviar mensaje del usuario
        const result = await chat.sendMessage(currentUserMessage.content);
        const response = result.response;

        // ✅ FIX: Declarar la variable aiText
        let aiText = '';

        // Extraer texto de la respuesta
        if (typeof response.text === 'function') {
            aiText = response.text();
        } 
        else if (response.candidates && response.candidates[0]) {
            const firstCandidate = response.candidates[0];
            if (firstCandidate.content && firstCandidate.content.parts) {
                aiText = firstCandidate.content.parts
                    .map(part => part.text || '')
                    .join('');
            }
        }
        else if (response.text) {
            aiText = response.text;
        }

        // Validar que la respuesta no esté vacía
        if (!aiText || aiText.trim() === '') {
            if (response.promptFeedback) {
                console.error('⚠️ Feedback del prompt:', response.promptFeedback);
                
                if (response.promptFeedback.blockReason) {
                    return 'Disculpa, no puedo responder a ese mensaje debido a restricciones de contenido. ¿Podrías reformularlo de otra manera?';
                }
            }

            return 'Disculpa, tuve un problema al procesar tu mensaje. ¿Podrías intentar de nuevo?';
        }

        console.log(`✅ Respuesta generada: "${aiText.substring(0, 50)}..."`);
        return aiText.trim();

    } catch (error) {
        console.error("\n❌ ERROR CRÍTICO EN GEMINI:", error.message);
        console.error("Stack trace:", error.stack);
        
        // Errores específicos de la API
        if (error.message.includes('API key')) {
            throw new Error('Error de configuración: API key inválida o no configurada');
        }
        
        if (error.message.includes('quota') || error.message.includes('rate limit')) {
            throw new Error('Servicio temporalmente no disponible. Intenta más tarde.');
        }
        
        if (error.message.includes('SAFETY')) {
            return 'Lo siento, no puedo responder a ese tipo de contenido. ¿Hay algo más en lo que pueda ayudarte?';
        }

        if (error.message.includes('500')) {
            console.error('❌ Error 500: Problema con el historial o estructura del mensaje');
            throw new Error('Error al procesar la conversación. Por favor, intenta de nuevo.');
        }

        // Error genérico
        throw new Error(`Error al comunicarse con Gemini: ${error.message}`);
    }
}

/**
 * Función auxiliar para validar la configuración de Gemini
 */
function validateGeminiConfig() {
    if (!GEMINI_API_KEY || GEMINI_API_KEY === 'gemini_api_key') {
        console.error('\n⚠️ CONFIGURACIÓN INCOMPLETA ⚠️');
        console.error('La API key de Gemini no está configurada correctamente.');
        console.error('Por favor, agrega tu API key en el archivo .env:');
        console.error('GEMINI_API_KEY=tu_clave_real_aqui\n');
        console.error('Obtén tu clave en: https://makersuite.google.com/app/apikey\n');
        return false;
    }
    
    console.log('✅ Configuración de Gemini validada correctamente');
    return true;
}

// Validar configuración al iniciar
validateGeminiConfig();

export {
    getGeminiChatResponse,
    validateGeminiConfig,
};