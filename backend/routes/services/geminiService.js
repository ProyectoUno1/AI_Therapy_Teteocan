// backend/routes/services/geminiService.js (CORREGIDO)

import dotenv from 'dotenv';
dotenv.config();
import { GoogleGenerativeAI } from '@google/generative-ai';

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

// Inicializar cliente de Gemini
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

        // Configurar el modelo con la instrucción del sistema
        const model = genAI.getGenerativeModel({ 
            model: GEMINI_MODEL,
            systemInstruction: systemInstruction.content, 
        });

        const geminiHistory = conversationHistory.map(msg => ({
            role: msg.isAI ? 'model' : 'user',
            parts: [{ text: msg.content }],
        }));

        // Iniciar chat con historial
        const chat = model.startChat({
            history: geminiHistory,
            generationConfig: {
                maxOutputTokens: 800, // Aumentado para respuestas más completas
                temperature: 0.8,     // Más creativo
                topP: 0.95,
                topK: 40,
            },
        });

        const result = await chat.sendMessage(currentUserMessage.content);
        const response = result.response;
        let aiText = '';

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
                console.error('Feedback del prompt:', response.promptFeedback);
                
                if (response.promptFeedback.blockReason) {
                    return 'Disculpa, no puedo responder a ese mensaje debido a restricciones de contenido. ¿Podrías reformularlo de otra manera?';
                }
            }

            return 'Disculpa, tuve un problema al procesar tu mensaje. ¿Podrías intentar de nuevo?';
        }

        const preview = aiText.length > 150 
            ? aiText.substring(0, 150) + '...' 
            : aiText;

        return aiText.trim();

    } catch (error) {
        console.error("\ERROR CRÍTICO:", error.message);
        console.error("Stack trace:", error.stack);
        
        // Errores específicos de la API
        if (error.message.includes('API key')) {
            throw new Error('Error de configuración: API key inválida o no configurada');
        }
        
        if (error.message.includes('quota')) {
            throw new Error('Servicio temporalmente no disponible. Intenta más tarde.');
        }
        
        if (error.message.includes('SAFETY')) {
            return 'Lo siento, no puedo responder a ese tipo de contenido. ¿Hay algo más en lo que pueda ayudarte?';
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
        console.error('\nCONFIGURACIÓN INCOMPLETA ');
        console.error('La API key de Gemini no está configurada correctamente.');
        console.error('Por favor, agrega tu API key en el archivo .env:');
        console.error('GEMINI_API_KEY=tu_clave_real_aqui\n');
        console.error('Obtén tu clave en: https://makersuite.google.com/app/apikey\n');
        return false;
    }
    
    console.log('Configuración validada correctamente');
    return true;
}


validateGeminiConfig();

export {
    getGeminiChatResponse,
    validateGeminiConfig,
};