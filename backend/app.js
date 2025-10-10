import express from "express";
import cors from "cors";
import aiRoutes from "./routes/aiRoutes.js";
import patientsRoutes from "./routes/patients.js";
import psychologistsRoutes from "./routes/psychologists.js";
import aiChatRoutes from "./routes/aiChatRoutes.js";
import chatRoutes from "./routes/chatRoutes.js";
import appointmentsRoutes from "./routes/appointments.js";
import patientManagementRoutes from "./routes/patient_management.js";
import notificationsRoutes from "./routes/notifications.js";
import { verifyFirebaseToken } from "./middlewares/auth_middleware.js";
import stripeRouter from "./routes/stripeRoutes.js";
import fcmRoutes from "./routes/fcm.js";
import { auth, db } from "./firebase-admin.js";
import articleRouter from "./routes/articleRoutes.js";
import supportRoutes from "./routes/supportRoutes.js";

const app = express();

// --- Configuración CORS para desarrollo y producción ---
const corsOptions = {
  origin:
    process.env.NODE_ENV === "production"
      ? [process.env.FRONTEND_URL, "https://tu-app-url.com"] // URLs de producción
      : ["http://localhost:3000", "http://10.0.2.2:3000"], // URLs de desarrollo
  credentials: true,
};

// --- Middleware específico para el webhook de Stripe ---
app.use(
  "/api/stripe/stripe-webhook",
  express.raw({ type: "application/json" })
);

// --- Middlewares Globales ---
app.use(cors(corsOptions));
app.use(express.json());

app.get("/", (req, res) => {
  res.send("Aurora Backend funcionando en modo DESARROLLO!");
});

// --- Rutas Unificadas ---
app.use("/api/patients", verifyFirebaseToken, patientsRoutes);
app.use("/api/psychologists", verifyFirebaseToken, psychologistsRoutes); // RUTA UNIFICADA
app.use("/api/appointments", verifyFirebaseToken, appointmentsRoutes);
app.use("/api/ai", verifyFirebaseToken, aiRoutes);
app.use("/api/chats/ai-chat", verifyFirebaseToken, aiChatRoutes);
app.use("/api/chats", verifyFirebaseToken, chatRoutes);
app.use("/api/stripe", stripeRouter);
app.use(
  "/api/patient-management",
  verifyFirebaseToken,
  patientManagementRoutes
);
app.use("/api/notifications", verifyFirebaseToken, notificationsRoutes);
app.use("/api", fcmRoutes); // Rutas FCM
app.use("/articles", articleRouter);
app.use("/api/support", supportRoutes); // Rutas de soporte

// --- Manejador de Errores Global ---
app.use((error, req, res, next) => {
  console.error("💥 Error global capturado:", error);
  res.status(error.status || 500).json({
    error: error.message || "Internal server error",
  });
});

export default app;
