// backend/routes/services/geminiService.js


import dotenv from 'dotenv';
dotenv.config();
import { GoogleGenerativeAI } from '@google/generative-ai';

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

if (!GEMINI_API_KEY) {
    console.error("Error: La variable de entorno GEMINI_API_KEY no está definida.");
    process.exit(1);
}

const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

const GEMINI_MODEL = "gemini-1.5-flash";

async function getGeminiChatResponse(messages) {
    try {
        const model = genAI.getGenerativeModel({ model: GEMINI_MODEL });
        const chat = model.startChat({
            // Mapear los mensajes existentes al formato de Gemini
            // Gemini espera [{ role: 'user', parts: [{ text: '...' }] }, { role: 'model', parts: [{ text: '...' }] }]
            history: messages.map(msg => ({
                role: msg.isAI ? 'model' : 'user', // 'model' es para la IA, 'user' para el usuario
                parts: [{ text: msg.content }],
            })),
            generationConfig: {
                maxOutputTokens: 200, // Limita la longitud de la respuesta
                temperature: 0.7,     // Controla la creatividad (0.0 a 1.0)
            },
        });

        // El último mensaje en el array es el nuevo mensaje del usuario
        const lastUserMessage = messages[messages.length - 1].content;

        console.log(`[Gemini] Enviando mensaje a Gemini: "${lastUserMessage}"`);
        const result = await chat.sendMessage(lastUserMessage);
        const response = await result.response;
        const text = response.text();
        console.log(`[Gemini] Respuesta de la IA recibida: "${text}"`);
        return text;

    } catch (error) {
        console.error("[Gemini Service] Error al interactuar con Gemini:", error);
        throw new Error(`Error al comunicarse con el modelo Gemini: ${error.message}`);
    }
}


export {
    getGeminiChatResponse,
};