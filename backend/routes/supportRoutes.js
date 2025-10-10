// backend/routes/supportRoutes.js

import express from "express";
import { db } from "../firebase-admin.js";

const router = express.Router();

/**
 * POST /api/support/tickets
 * Crear un nuevo ticket de soporte
 */
router.post("/tickets", async (req, res) => {
  try {
    const {
      userId,
      userEmail,
      userName,
      userType,
      subject,
      category,
      message,
      priority,
    } = req.body;

    // Validación básica
    if (!userId || !userEmail || !subject || !message) {
      return res.status(400).json({
        error: "Faltan campos requeridos: userId, userEmail, subject, message",
      });
    }

    // Crear el ticket en Firestore
    const ticketData = {
      userId,
      userEmail,
      userName: userName || "Usuario",
      userType: userType || "patient",
      subject,
      category: category || "general",
      message,
      priority: priority || "medium",
      status: "open",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      response: null,
      responseAt: null,
    };

    const ticketRef = await db.collection("support_tickets").add(ticketData);

    res.status(201).json({
      success: true,
      message: "Ticket creado exitosamente",
      ticketId: ticketRef.id,
      ticket: {
        id: ticketRef.id,
        ...ticketData,
      },
    });
  } catch (error) {
    console.error("Error al crear ticket:", error);
    res.status(500).json({
      error: "Error al crear el ticket de soporte",
      details: error.message,
    });
  }
});

/**
 * GET /api/support/tickets/user/:userId
 * Obtener todos los tickets de un usuario
 */
router.get("/tickets/user/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const ticketsSnapshot = await db
      .collection("support_tickets")
      .where("userId", "==", userId)
      .orderBy("createdAt", "desc")
      .get();

    if (ticketsSnapshot.empty) {
      return res.status(200).json([]);
    }

    const tickets = [];
    ticketsSnapshot.forEach((doc) => {
      tickets.push({
        id: doc.id,
        ...doc.data(),
      });
    });

    res.status(200).json(tickets);
  } catch (error) {
    console.error("Error al obtener tickets:", error);
    res.status(500).json({
      error: "Error al obtener los tickets",
      details: error.message,
    });
  }
});

/**
 * GET /api/support/tickets/:ticketId
 * Obtener un ticket específico por ID
 */
router.get("/tickets/:ticketId", async (req, res) => {
  try {
    const { ticketId } = req.params;

    const ticketDoc = await db
      .collection("support_tickets")
      .doc(ticketId)
      .get();

    if (!ticketDoc.exists) {
      return res.status(404).json({
        error: "Ticket no encontrado",
      });
    }

    res.status(200).json({
      id: ticketDoc.id,
      ...ticketDoc.data(),
    });
  } catch (error) {
    console.error("Error al obtener ticket:", error);
    res.status(500).json({
      error: "Error al obtener el ticket",
      details: error.message,
    });
  }
});

/**
 * PATCH /api/support/tickets/:ticketId
 * Actualizar un ticket (responder, cambiar estado, etc.)
 */
router.patch("/tickets/:ticketId", async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { status, response } = req.body;

    const ticketRef = db.collection("support_tickets").doc(ticketId);
    const ticketDoc = await ticketRef.get();

    if (!ticketDoc.exists) {
      return res.status(404).json({
        error: "Ticket no encontrado",
      });
    }

    const updateData = {
      updatedAt: new Date().toISOString(),
    };

    if (status) {
      updateData.status = status;
    }

    if (response) {
      updateData.response = response;
      updateData.responseAt = new Date().toISOString();
      if (!status) {
        updateData.status = "resolved";
      }
    }

    await ticketRef.update(updateData);

    const updatedDoc = await ticketRef.get();

    res.status(200).json({
      success: true,
      message: "Ticket actualizado exitosamente",
      ticket: {
        id: updatedDoc.id,
        ...updatedDoc.data(),
      },
    });
  } catch (error) {
    console.error("Error al actualizar ticket:", error);
    res.status(500).json({
      error: "Error al actualizar el ticket",
      details: error.message,
    });
  }
});

/**
 * DELETE /api/support/tickets/:ticketId
 * Eliminar un ticket (solo para administradores)
 */
router.delete("/tickets/:ticketId", async (req, res) => {
  try {
    const { ticketId } = req.params;

    const ticketRef = db.collection("support_tickets").doc(ticketId);
    const ticketDoc = await ticketRef.get();

    if (!ticketDoc.exists) {
      return res.status(404).json({
        error: "Ticket no encontrado",
      });
    }

    await ticketRef.delete();

    res.status(200).json({
      success: true,
      message: "Ticket eliminado exitosamente",
    });
  } catch (error) {
    console.error("Error al eliminar ticket:", error);
    res.status(500).json({
      error: "Error al eliminar el ticket",
      details: error.message,
    });
  }
});

/**
 * GET /api/support/tickets
 * Obtener todos los tickets (para administradores)
 * Opcional: filtrar por status, priority, category
 */
router.get("/tickets", async (req, res) => {
  try {
    const { status, priority, category } = req.query;

    let query = db.collection("support_tickets");

    if (status) {
      query = query.where("status", "==", status);
    }

    if (priority) {
      query = query.where("priority", "==", priority);
    }

    if (category) {
      query = query.where("category", "==", category);
    }

    const ticketsSnapshot = await query.orderBy("createdAt", "desc").get();

    if (ticketsSnapshot.empty) {
      return res.status(200).json([]);
    }

    const tickets = [];
    ticketsSnapshot.forEach((doc) => {
      tickets.push({
        id: doc.id,
        ...doc.data(),
      });
    });

    res.status(200).json(tickets);
  } catch (error) {
    console.error("Error al obtener tickets:", error);
    res.status(500).json({
      error: "Error al obtener los tickets",
      details: error.message,
    });
  }
});

export default router;
