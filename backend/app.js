// \AI_Therapy_Teteocan\backend\app.js

import express from "express";
import cors from "cors";
import aiRoutes from "./routes/aiRoutes.js";
import patientsRoutes from "./routes/patients.js";
import psychologistsRoutes from "./routes/psychologists.js";
import aiChatRoutes from "./routes/aiChatRoutes.js";
import chatRoutes from "./routes/chatRoutes.js";
import psychologistProfessionalProfileRoutes from "./routes/psychologist_professional_profile.js";
import { verifyFirebaseToken } from "./middlewares/auth_middleware.js";

import { auth, db } from "./firebase-admin.js";

const app = express();

// --- Configuración CORS para desarrollo y producción ---
const corsOptions = {
  origin:
    process.env.NODE_ENV === "production"
      ? [process.env.FRONTEND_URL, "https://tu-app-url.com"] // ← URLs de producción
      : ["http://localhost:3000", "http://10.0.2.2:3000"], // URLs de desarrollo
  credentials: true,
};

// --- Middlewares Globales ---
app.use(cors(corsOptions));
app.use(express.json()); // Para interpretar cuerpos de petición JSON
// --- Middleware de Autenticación Firebase (Adaptado para Desarrollo) ---


app.get("/", (req, res) => {
  res.send("¡Aurora Backend funcionando en modo DESARROLLO!");
});

app.use("/api/patients", patientsRoutes);
app.use("/api/psychologists", psychologistsRoutes);
app.use("/api/psychologists", psychologistProfessionalProfileRoutes);


app.use("/api/ai", aiRoutes);
app.use("/api/chats/ai-chat", aiChatRoutes);
app.use("/api/chats", chatRoutes);
app.use(verifyFirebaseToken);


// --- Manejador de Errores Global ---
app.use((error, req, res, next) => {

  console.error("💥 Error global capturado:", error);
  res.status(error.status || 500).json({
    error: error.message || "Internal server error",
  });

});

export default app;
