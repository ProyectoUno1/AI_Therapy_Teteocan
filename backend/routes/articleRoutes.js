// articleRoutes.js
import dotenv from "dotenv";
import express from "express";
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../firebase-admin.js';

dotenv.config();

const articleRouter = express.Router();

// Middleware para validar que el usuario sea psicólogo
const validatePsychologist = async (req, res, next) => {
  const { psychologistId } = req.body;
  
  if (!psychologistId) {
    return res.status(400).json({ error: "psychologistId es requerido" });
  }

  try {
    const psychologistDoc = await db.collection('psychologists').doc(psychologistId).get();
    if (!psychologistDoc.exists) {
      return res.status(404).json({ error: "Psicólogo no encontrado" });
    }
    
    req.psychologist = psychologistDoc.data();
    next();
  } catch (error) {
    console.error("Error validando psicólogo:", error);
    res.status(500).json({ error: "Error de validación" });
  }
};


// Endpoint para crear/subir un nuevo artículo
articleRouter.post("/create", validatePsychologist, async (req, res) => {
  const { 
    psychologistId,
    title,
    content,
    summary,
    imageUrl,
    tags = [],
    category,
    readingTimeMinutes,
    isPublished = false 
  } = req.body;

  // Validaciones del contenido
  if (!title || !content) {
    return res.status(400).json({
      error: "title y content son requeridos."
    });
  }

  if (title.length < 10 || title.length > 200) {
    return res.status(400).json({
      error: "El título debe tener entre 10 y 200 caracteres."
    });
  }

  if (content.length < 100) {
    return res.status(400).json({
      error: "El contenido debe tener al menos 100 caracteres."
    });
  }

  try {
    console.log(`Creando artículo para psicólogo: ${psychologistId}`);
    
    // Crear el artículo en Firebase
    const articleRef = await db.collection('articles').add({
      psychologistId: psychologistId,
      psychologistName: req.psychologist.name || 'Psicólogo',
      psychologistEmail: req.psychologist.email || '',
      title: title.trim(),
      content: content.trim(),
      summary: summary?.trim() || content.substring(0, 200) + '...',
      imageUrl: imageUrl || `https://picsum.photos/seed/article_${Date.now()}/400/250`,
      tags: Array.isArray(tags) ? tags.map(tag => tag.trim().toLowerCase()) : [],
      category: category || 'general',
      readingTimeMinutes: readingTimeMinutes || Math.ceil(content.length / 200), // Estimación: 200 caracteres por minuto
      isPublished: isPublished,
      status: isPublished ? 'published' : 'draft',
      views: 0,
      likes: 0,
      comments: [],
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      publishedAt: isPublished ? FieldValue.serverTimestamp() : null
    });

    // Actualizar estadísticas del psicólogo
    await db.collection('psychologists').doc(psychologistId).update({
      articlesCount: FieldValue.increment(1),
      lastArticleDate: FieldValue.serverTimestamp()
    });

    console.log(`Artículo creado exitosamente: ${articleRef.id}`);
    
    res.status(201).json({
      success: true,
      articleId: articleRef.id,
      message: "Artículo creado exitosamente",
      article: {
        id: articleRef.id,
        title: title,
        status: isPublished ? 'published' : 'draft',
        createdAt: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error("Error al crear artículo:", error);
    res.status(500).json({
      error: "Error al crear el artículo",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Endpoint para obtener artículos de un psicólogo específico
articleRouter.get("/psychologist/:psychologistId", async (req, res) => {
  const { psychologistId } = req.params;
  const { status, limit = 10, page = 1 } = req.query;

  if (!psychologistId) {
    return res.status(400).json({ error: "psychologistId es requerido" });
  }

  try {
    let query = db.collection('articles')
      .where('psychologistId', '==', psychologistId)
      .orderBy('createdAt', 'desc');

    // Filtrar por estado si se especifica
    if (status && ['draft', 'published', 'archived'].includes(status)) {
      query = query.where('status', '==', status);
    }

    // Paginación
    const limitNum = Math.min(parseInt(limit), 50); // Máximo 50 artículos por página
    query = query.limit(limitNum);

    const articlesSnapshot = await query.get();
    
    const articles = articlesSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt?.toDate(),
        updatedAt: data.updatedAt?.toDate(),
        publishedAt: data.publishedAt?.toDate()
      };
    });

    res.json({
      articles: articles,
      totalArticles: articles.length,
      page: parseInt(page),
      limit: limitNum
    });

  } catch (error) {
    console.error("Error obteniendo artículos del psicólogo:", error);
    res.status(500).json({
      error: "Error al obtener artículos",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Endpoint para actualizar un artículo existente
articleRouter.put("/update/:articleId", async (req, res) => {
  const { articleId } = req.params;
  const { 
    psychologistId,
    title,
    content,
    summary,
    imageUrl,
    tags,
    category,
    readingTimeMinutes,
    isPublished
  } = req.body;

  if (!articleId || !psychologistId) {
    return res.status(400).json({
      error: "articleId y psychologistId son requeridos."
    });
  }

  try {
    // Verificar que el artículo existe y pertenece al psicólogo
    const articleDoc = await db.collection('articles').doc(articleId).get();
    
    if (!articleDoc.exists) {
      return res.status(404).json({ error: "Artículo no encontrado" });
    }

    const articleData = articleDoc.data();
    if (articleData.psychologistId !== psychologistId) {
      return res.status(403).json({ error: "No tienes permisos para editar este artículo" });
    }

    // Preparar datos de actualización
    const updateData = {
      updatedAt: FieldValue.serverTimestamp()
    };

    if (title !== undefined) {
      if (title.length < 10 || title.length > 200) {
        return res.status(400).json({
          error: "El título debe tener entre 10 y 200 caracteres."
        });
      }
      updateData.title = title.trim();
    }

    if (content !== undefined) {
      if (content.length < 100) {
        return res.status(400).json({
          error: "El contenido debe tener al menos 100 caracteres."
        });
      }
      updateData.content = content.trim();
      // Actualizar tiempo de lectura estimado
      updateData.readingTimeMinutes = Math.ceil(content.length / 200);
    }

    if (summary !== undefined) updateData.summary = summary.trim();
    if (imageUrl !== undefined) updateData.imageUrl = imageUrl;
    if (Array.isArray(tags)) updateData.tags = tags.map(tag => tag.trim().toLowerCase());
    if (category !== undefined) updateData.category = category;
    if (readingTimeMinutes !== undefined) updateData.readingTimeMinutes = readingTimeMinutes;

    // Manejar cambio de estado de publicación
    if (isPublished !== undefined) {
      updateData.isPublished = isPublished;
      updateData.status = isPublished ? 'published' : 'draft';
      
      // Si se está publicando por primera vez
      if (isPublished && !articleData.publishedAt) {
        updateData.publishedAt = FieldValue.serverTimestamp();
      }
    }

    await db.collection('articles').doc(articleId).update(updateData);

    console.log(`Artículo ${articleId} actualizado exitosamente`);
    
    res.json({
      success: true,
      message: "Artículo actualizado exitosamente",
      articleId: articleId
    });

  } catch (error) {
    console.error("Error al actualizar artículo:", error);
    res.status(500).json({
      error: "Error al actualizar el artículo",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Endpoint para eliminar un artículo
articleRouter.delete("/delete/:articleId", async (req, res) => {
  const { articleId } = req.params;
  const { psychologistId } = req.body;

  if (!articleId || !psychologistId) {
    return res.status(400).json({
      error: "articleId y psychologistId son requeridos."
    });
  }

  try {
    // Verificar que el artículo existe y pertenece al psicólogo
    const articleDoc = await db.collection('articles').doc(articleId).get();
    
    if (!articleDoc.exists) {
      return res.status(404).json({ error: "Artículo no encontrado" });
    }

    const articleData = articleDoc.data();
    if (articleData.psychologistId !== psychologistId) {
      return res.status(403).json({ error: "No tienes permisos para eliminar este artículo" });
    }

    // Eliminar el artículo (soft delete)
    await db.collection('articles').doc(articleId).update({
      status: 'deleted',
      deletedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });

 

    // Actualizar estadísticas del psicólogo
    await db.collection('psychologists').doc(psychologistId).update({
      articlesCount: FieldValue.increment(-1)
    });

    console.log(`Artículo ${articleId} eliminado exitosamente`);
    
    res.json({
      success: true,
      message: "Artículo eliminado exitosamente"
    });

  } catch (error) {
    console.error("Error al eliminar artículo:", error);
    res.status(500).json({
      error: "Error al eliminar el artículo",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Endpoint para obtener todos los artículos públicos (para pacientes)
articleRouter.get("/public", async (req, res) => {
  const { category, limit = 20, page = 1, search } = req.query;

  try {
    let query = db.collection('articles')
      .where('isPublished', '==', true)
      .where('status', '==', 'published')
      .orderBy('publishedAt', 'desc');

    // Filtrar por categoría
    if (category) {
      query = query.where('category', '==', category);
    }

    const limitNum = Math.min(parseInt(limit), 50);
    query = query.limit(limitNum);

    const articlesSnapshot = await query.get();
    
    let articles = articlesSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        title: data.title,
        summary: data.summary,
        imageUrl: data.imageUrl,
        psychologistName: data.psychologistName,
        category: data.category,
        tags: data.tags,
        readingTimeMinutes: data.readingTimeMinutes,
        views: data.views,
        likes: data.likes,
        publishedAt: data.publishedAt?.toDate(),
        createdAt: data.createdAt?.toDate()
      };
    });

    // Filtro básico por búsqueda (lado servidor)
    if (search) {
      const searchTerm = search.toLowerCase();
      articles = articles.filter(article => 
        article.title.toLowerCase().includes(searchTerm) ||
        article.summary.toLowerCase().includes(searchTerm) ||
        article.tags.some(tag => tag.includes(searchTerm))
      );
    }

    res.json({
      articles: articles,
      totalArticles: articles.length,
      page: parseInt(page),
      limit: limitNum
    });

  } catch (error) {
    console.error("Error obteniendo artículos públicos:", error);
    res.status(500).json({
      error: "Error al obtener artículos públicos",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Endpoint para obtener un artículo específico por ID
articleRouter.get("/:articleId", async (req, res) => {
  const { articleId } = req.params;
  const { incrementView = false } = req.query;

  if (!articleId) {
    return res.status(400).json({ error: "articleId es requerido" });
  }

  try {
    const articleDoc = await db.collection('articles').doc(articleId).get();
    
    if (!articleDoc.exists) {
      return res.status(404).json({ error: "Artículo no encontrado" });
    }

    const articleData = articleDoc.data();
    
    // Solo mostrar artículos publicados a usuarios no autorizados
    if (!articleData.isPublished || articleData.status !== 'published') {
      return res.status(404).json({ error: "Artículo no disponible" });
    }
    
    // Incrementar vistas si se solicita
    if (incrementView === 'true') {
      await db.collection('articles').doc(articleId).update({
        views: FieldValue.increment(1)
      });
      articleData.views = (articleData.views || 0) + 1;
    }

    const article = {
      id: articleDoc.id,
      ...articleData,
      createdAt: articleData.createdAt?.toDate(),
      updatedAt: articleData.updatedAt?.toDate(),
      publishedAt: articleData.publishedAt?.toDate()
    };

    res.json({ article });

  } catch (error) {
    console.error("Error obteniendo artículo:", error);
    res.status(500).json({
      error: "Error al obtener artículo",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Endpoint para dar like/unlike a un artículo
articleRouter.post("/:articleId/like", async (req, res) => {
  const { articleId } = req.params;
  const { userId, action = 'like' } = req.body; // action: 'like' | 'unlike'

  if (!articleId || !userId) {
    return res.status(400).json({
      error: "articleId y userId son requeridos"
    });
  }

  try {
    const articleDoc = await db.collection('articles').doc(articleId).get();
    
    if (!articleDoc.exists) {
      return res.status(404).json({ error: "Artículo no encontrado" });
    }

    const likeRef = db.collection('article_likes').doc(`${articleId}_${userId}`);
    const likeDoc = await likeRef.get();
    
    if (action === 'like') {
      if (!likeDoc.exists) {
        // Crear like
        await likeRef.set({
          articleId: articleId,
          userId: userId,
          createdAt: FieldValue.serverTimestamp()
        });
        
        // Incrementar contador
        await db.collection('articles').doc(articleId).update({
          likes: FieldValue.increment(1)
        });
        
        res.json({ success: true, message: "Like agregado" });
      } else {
        res.json({ success: true, message: "Ya has dado like a este artículo" });
      }
    } else if (action === 'unlike') {
      if (likeDoc.exists) {
        // Eliminar like
        await likeRef.delete();
        
        // Decrementar contador
        await db.collection('articles').doc(articleId).update({
          likes: FieldValue.increment(-1)
        });
        
        res.json({ success: true, message: "Like eliminado" });
      } else {
        res.json({ success: true, message: "No habías dado like a este artículo" });
      }
    }

  } catch (error) {
    console.error("Error procesando like:", error);
    res.status(500).json({
      error: "Error al procesar like",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Endpoint para obtener categorías disponibles
articleRouter.get("/categories/list", async (req, res) => {
  try {
    const articlesSnapshot = await db.collection('articles')
      .where('isPublished', '==', true)
      .where('status', '==', 'published')
      .select('category')
      .get();

    const categories = [...new Set(articlesSnapshot.docs.map(doc => doc.data().category))];
    
    res.json({ categories });

  } catch (error) {
    console.error("Error obteniendo categorías:", error);
    res.status(500).json({
      error: "Error al obtener categorías",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Endpoint para obtener todos los artículos públicos y publicados
articleRouter.get("/published", async (req, res) => {
  try {
    const { limit = 10, page = 1 } = req.query;
    const limitNum = Math.min(parseInt(limit), 50); // Máximo 50 artículos por página
    const pageNum = parseInt(page);
    const offset = (pageNum - 1) * limitNum;

    let query = db.collection('articles')
      .where('isPublished', '==', true)
      .where('status', '==', 'published')
      .orderBy('publishedAt', 'desc');

    const totalSnapshot = await query.get();
    const totalArticles = totalSnapshot.size;

    const articlesSnapshot = await query
      .offset(offset)
      .limit(limitNum)
      .get();
    
    const articles = articlesSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt?.toDate(),
        updatedAt: data.updatedAt?.toDate(),
        publishedAt: data.publishedAt?.toDate()
      };
    });

    res.json({
      articles: articles,
      totalArticles: totalArticles,
      page: pageNum,
      limit: limitNum
    });

  } catch (error) {
    console.error("Error al obtener artículos publicados:", error);
    res.status(500).json({
      error: "Error al obtener artículos publicados",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

export default articleRouter;