import express from "express";
import cors from "cors";
import patientsRoutes from "./routes/patients.js";
import psychologistsRoutes from "./routes/psychologists.js";
import aiChatRoutes from "./routes/aiChatRoutes.js";
import chatRoutes from "./routes/chatRoutes.js";
import appointmentsRoutes from "./routes/appointments.js";
import patientManagementRoutes from './routes/patient_management.js';
import notificationsRoutes from './routes/notifications.js';
import { verifyFirebaseToken } from "./middlewares/auth_middleware.js";
import stripeRouter from "./routes/stripeRoutes.js";
import fcmRoutes from './routes/fcm.js';
import { db } from './firebase-admin.js';
import articleRouter from './routes/articleRoutes.js';
import { scheduleCleanupTask } from './routes/services/appointmentsCleanup.js';
import supportRoutes from "./routes/supportRoutes.js";
import bankInfoRoutes from './routes/bankInfoRoutes.js';

const app = express();
const allowedOrigins = process.env.NODE_ENV === "production"
  ? [
      process.env.FRONTEND_URL,
      'https://ai-therapy-teteocan.onrender.com',
    ].filter(Boolean)
  : [
      
    ];

const corsOptions = {
  origin: function (origin, callback) {
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.indexOf(origin) !== -1 || process.env.NODE_ENV !== "production") {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
};

// --- Middleware específico para el webhook de Stripe ---
app.use("/api/stripe/stripe-webhook", express.raw({ type: 'application/json' }));

// --- Middlewares Globales ---
app.use(cors(corsOptions));
app.use(express.json()); 

// Health check endpoint
app.get("/", (req, res) => {
  res.json({ 
    status: "ok",
    message: "Aurora Backend API",
    environment: process.env.NODE_ENV,
    timestamp: new Date().toISOString()
  });
});

app.get("/health", (req, res) => {
  res.json({ 
    status: "healthy",
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// --- Rutas Unificadas ---
app.use("/api/patients", verifyFirebaseToken, patientsRoutes);
app.use("/api/psychologists", verifyFirebaseToken, psychologistsRoutes);
app.use("/api/appointments", verifyFirebaseToken, appointmentsRoutes);
app.use("/api/chats/ai-chat", verifyFirebaseToken, aiChatRoutes);
app.use("/api/chats", verifyFirebaseToken, chatRoutes);
app.use("/api/stripe", stripeRouter);
app.use('/api/patient-management', verifyFirebaseToken, patientManagementRoutes);
app.use('/api/notifications', verifyFirebaseToken, notificationsRoutes);
app.use('/api', fcmRoutes);
app.use('/api/articles', articleRouter);
app.use('/api/articles/public', articleRouter);
app.use("/api/support", supportRoutes);
app.use('/api', bankInfoRoutes);

// Iniciar tarea de limpieza
scheduleCleanupTask();

// --- Manejador de Errores Global ---
app.use((error, req, res, next) => {
  console.error("💥 Error global capturado:", error);
  res.status(error.status || 500).json({
    error: error.message || "Internal server error",
  });
});

export default app;