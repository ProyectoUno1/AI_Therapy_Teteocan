/// articleRoutes.js
import dotenv from "dotenv";
import express from "express";
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../firebase-admin.js';
import { genericUploadHandler } from '../middlewares/upload_handler.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';

dotenv.config();

const articleRouter = express.Router();

// Límite máximo de artículos por psicólogo
const MAX_ARTICLES_PER_PSYCHOLOGIST = 3;

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

// Middleware para verificar límite de artículos
const checkArticleLimit = async (req, res, next) => {
  const { psychologistId } = req.body;

  try {
    const articlesSnapshot = await db.collection('articles')
      .where('psychologistId', '==', psychologistId)
      .where('status', 'in', ['draft', 'published'])
      .get();

    const currentArticleCount = articlesSnapshot.size;

    if (currentArticleCount >= MAX_ARTICLES_PER_PSYCHOLOGIST) {
      return res.status(403).json({
        error: "Límite de artículos alcanzado",
        message: `Has alcanzado el límite de ${MAX_ARTICLES_PER_PSYCHOLOGIST} artículos.`,
        currentCount: currentArticleCount,
        maxLimit: MAX_ARTICLES_PER_PSYCHOLOGIST
      });
    }

    req.articleCount = currentArticleCount;
    req.articlesRemaining = MAX_ARTICLES_PER_PSYCHOLOGIST - currentArticleCount;
    
    next();
  } catch (error) {
    console.error("Error verificando límite de artículos:", error);
    res.status(500).json({ error: "Error al verificar límite de artículos" });
  }
};

// ========================================
// RUTAS PÚBLICAS (sin autenticación)
// ========================================

// 🌍 GET /public - Obtener artículos publicados (PÚBLICO)
articleRouter.get("/public", async (req, res) => {
  const { category, limit = 20, page = 1, search } = req.query;

  try {
    console.log('📰 Obteniendo artículos públicos...');
    
    let query = db.collection('articles')
      .where('isPublished', '==', true)
      .where('status', '==', 'published')
      .orderBy('publishedAt', 'desc');

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
        ...data,
        createdAt: data.createdAt?.toDate(),
        updatedAt: data.updatedAt?.toDate(),
        publishedAt: data.publishedAt?.toDate(),
      };
    });

    if (search) {
      const searchTerm = search.toLowerCase();
      articles = articles.filter(article =>
        article.title.toLowerCase().includes(searchTerm) ||
        article.summary.toLowerCase().includes(searchTerm) ||
        article.tags.some(tag => tag.includes(searchTerm))
      );
    }

    console.log(`✅ Devolviendo ${articles.length} artículos públicos`);

    res.json({
      articles: articles,
      totalArticles: articles.length,
      page: parseInt(page),
      limit: limitNum
    });

  } catch (error) {
    console.error("❌ Error obteniendo artículos públicos:", error);
    res.status(500).json({
      error: "Error al obtener artículos públicos",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// 🌍 GET /published - Alias de /public (PÚBLICO)
articleRouter.get("/published", async (req, res) => {
  try {
    const { limit = 10, page = 1 } = req.query;
    const limitNum = Math.min(parseInt(limit), 50);
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

// 🌍 GET /:articleId - Obtener artículo específico (PÚBLICO)
articleRouter.get("/:articleId", async (req, res) => {
  const { articleId } = req.params;

  try {
    const articleDoc = await db.collection('articles').doc(articleId).get();

    if (!articleDoc.exists) {
      return res.status(404).json({ error: "Artículo no encontrado" });
    }

    const articleData = articleDoc.data();

    res.json({
      success: true,
      article: {
        id: articleDoc.id,
        ...articleData,
        createdAt: articleData.createdAt?.toDate(),
        updatedAt: articleData.updatedAt?.toDate(),
        publishedAt: articleData.publishedAt?.toDate()
      }
    });

  } catch (error) {
    console.error("Error al obtener artículo:", error);
    res.status(500).json({
      error: "Error al obtener el artículo",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// 🌍 POST /:articleId/view - Registrar vista (PÚBLICO)
articleRouter.post("/:articleId/view", async (req, res) => {
  const { articleId } = req.params;

  if (!articleId) {
    return res.status(400).json({ error: "articleId es requerido" });
  }

  try {
    const articleDoc = await db.collection('articles').doc(articleId).get();

    if (!articleDoc.exists) {
      return res.status(404).json({ error: "Artículo no encontrado" });
    }

    await db.collection('articles').doc(articleId).update({
      views: FieldValue.increment(1)
    });

    res.json({ success: true, message: "Vista registrada" });
  } catch (error) {
    console.error("Error al registrar vista:", error);
    res.status(500).json({
      error: "Error al registrar la vista",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// ========================================
// RUTAS PROTEGIDAS (requieren autenticación)
// ========================================

// 🔒 POST /create - Crear artículo (PROTEGIDO)
articleRouter.post("/create", verifyFirebaseToken, validatePsychologist, checkArticleLimit, async (req, res) => {
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
    const articleRef = await db.collection('articles').add({
      psychologistId: psychologistId,
      fullName: req.psychologist.fullName || 'Psicólogo',
      psychologistEmail: req.psychologist.email || '',
      title: title.trim(),
      content: content.trim(),
      summary: summary?.trim() || content.substring(0, 200) + '...',
      imageUrl: imageUrl || `https://picsum.photos/seed/article_${Date.now()}/400/250`,
      tags: Array.isArray(tags) ? tags.map(tag => tag.trim().toLowerCase()) : [],
      category: category || 'general',
      readingTimeMinutes: readingTimeMinutes || Math.ceil(content.length / 200),
      isPublished: isPublished,
      status: isPublished ? 'published' : 'draft',
      views: 0,
      likes: 0,
      comments: [],
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      publishedAt: isPublished ? FieldValue.serverTimestamp() : null
    });

    await db.collection('psychologists').doc(psychologistId).update({
      articlesCount: FieldValue.increment(1),
      lastArticleDate: FieldValue.serverTimestamp()
    });

    res.status(201).json({
      success: true,
      articleId: articleRef.id,
      message: "Artículo creado exitosamente",
      article: {
        id: articleRef.id,
        title: title,
        status: isPublished ? 'published' : 'draft',
        createdAt: new Date().toISOString()
      },
      articlesRemaining: req.articlesRemaining - 1,
      maxArticles: MAX_ARTICLES_PER_PSYCHOLOGIST
    });

  } catch (error) {
    console.error("Error al crear artículo:", error);
    res.status(500).json({
      error: "Error al crear el artículo",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// 🔒 GET /psychologist/:psychologistId/limit - Obtener límite (PROTEGIDO)
articleRouter.get("/psychologist/:psychologistId/limit", verifyFirebaseToken, async (req, res) => {
  const { psychologistId } = req.params;

  if (!psychologistId) {
    return res.status(400).json({ error: "psychologistId es requerido" });
  }

  try {
    const articlesSnapshot = await db.collection('articles')
      .where('psychologistId', '==', psychologistId)
      .where('status', 'in', ['draft', 'published'])
      .get();

    const currentCount = articlesSnapshot.size;
    const remaining = MAX_ARTICLES_PER_PSYCHOLOGIST - currentCount;

    res.json({
      currentCount,
      maxLimit: MAX_ARTICLES_PER_PSYCHOLOGIST,
      remaining,
      canCreateMore: remaining > 0,
      percentage: Math.round((currentCount / MAX_ARTICLES_PER_PSYCHOLOGIST) * 100)
    });

  } catch (error) {
    console.error("Error obteniendo límite:", error);
    res.status(500).json({
      error: "Error al obtener límite",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// 🔒 GET /psychologist/:psychologistId - Obtener artículos del psicólogo (PROTEGIDO)
articleRouter.get("/psychologist/:psychologistId", verifyFirebaseToken, async (req, res) => {
  const { psychologistId } = req.params;
  const { status, limit = 10, page = 1 } = req.query;

  if (!psychologistId) {
    return res.status(400).json({ error: "psychologistId es requerido" });
  }

  try {
    let query = db.collection('articles')
      .where('psychologistId', '==', psychologistId);

    if (status && ['draft', 'published', 'archived'].includes(status)) {
      query = query.where('status', '==', status);
    } else {
      query = query.where('status', 'in', ['draft', 'published']);
    }

    query = query.orderBy('createdAt', 'desc');
    const limitNum = Math.min(parseInt(limit), 50);
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

    const activeArticlesSnapshot = await db.collection('articles')
      .where('psychologistId', '==', psychologistId)
      .where('status', 'in', ['draft', 'published'])
      .get();

    const currentCount = activeArticlesSnapshot.size;

    res.status(200).json({
      articles: articles,
      totalArticles: articles.length,
      page: parseInt(page),
      limit: limitNum,
      articleLimit: {
        currentCount,
        maxLimit: MAX_ARTICLES_PER_PSYCHOLOGIST,
        remaining: MAX_ARTICLES_PER_PSYCHOLOGIST - currentCount,
        canCreateMore: currentCount < MAX_ARTICLES_PER_PSYCHOLOGIST
      }
    });

  } catch (error) {
    console.error("Error obteniendo artículos del psicólogo:", error);
    res.status(500).json({
      error: "Error al obtener artículos",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// 🔒 PUT /update/:articleId - Actualizar artículo (PROTEGIDO)
articleRouter.put("/update/:articleId", verifyFirebaseToken, async (req, res) => {
  const { articleId } = req.params;
  const { psychologistId, title, content, summary, imageUrl, tags, category, readingTimeMinutes, isPublished } = req.body;

  if (!articleId || !psychologistId) {
    return res.status(400).json({ error: "articleId y psychologistId son requeridos." });
  }

  try {
    const articleDoc = await db.collection('articles').doc(articleId).get();
    if (!articleDoc.exists) {
      return res.status(404).json({ error: "Artículo no encontrado" });
    }

    const articleData = articleDoc.data();
    if (articleData.psychologistId !== psychologistId) {
      return res.status(403).json({ error: "No tienes permisos para editar este artículo" });
    }

    const updateData = { updatedAt: FieldValue.serverTimestamp() };

    if (title !== undefined) updateData.title = title.trim();
    if (content !== undefined) updateData.content = content.trim();
    if (summary !== undefined) updateData.summary = summary.trim();
    if (imageUrl !== undefined) updateData.imageUrl = imageUrl;
    if (Array.isArray(tags)) updateData.tags = tags.map(tag => tag.trim().toLowerCase());
    if (category !== undefined) updateData.category = category;
    if (readingTimeMinutes !== undefined) updateData.readingTimeMinutes = readingTimeMinutes;

    if (isPublished !== undefined) {
      updateData.isPublished = isPublished;
      updateData.status = isPublished ? 'published' : 'draft';
      if (isPublished && !articleData.publishedAt) {
        updateData.publishedAt = FieldValue.serverTimestamp();
      }
    }

    await db.collection('articles').doc(articleId).update(updateData);

    res.json({ success: true, message: "Artículo actualizado exitosamente", articleId });

  } catch (error) {
    console.error("Error al actualizar artículo:", error);
    res.status(500).json({
      error: "Error al actualizar el artículo",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// 🔒 DELETE /delete/:articleId - Eliminar artículo (PROTEGIDO)
articleRouter.delete("/delete/:articleId", verifyFirebaseToken, async (req, res) => {
  const { articleId } = req.params;
  const { psychologistId } = req.body;

  if (!articleId || !psychologistId) {
    return res.status(400).json({ error: "articleId y psychologistId son requeridos." });
  }

  try {
    const articleDoc = await db.collection('articles').doc(articleId).get();
    if (!articleDoc.exists) {
      return res.status(404).json({ error: "Artículo no encontrado" });
    }

    const articleData = articleDoc.data();
    if (articleData.psychologistId !== psychologistId) {
      return res.status(403).json({ error: "No tienes permisos para eliminar este artículo" });
    }

    await db.collection('articles').doc(articleId).update({
      status: 'deleted',
      deletedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });

    await db.collection('psychologists').doc(psychologistId).update({
      articlesCount: FieldValue.increment(-1)
    });

    res.json({ success: true, message: "Artículo eliminado exitosamente" });

  } catch (error) {
    res.status(500).json({
      error: "Error al eliminar el artículo",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// 🔒 POST /:articleId/like - Like/Unlike artículo (PROTEGIDO)
articleRouter.post("/:articleId/like", verifyFirebaseToken, async (req, res) => {
  const { articleId } = req.params;
  const { userId, action = 'like' } = req.body;

  if (!articleId || !userId) {
    return res.status(400).json({ error: "articleId y userId son requeridos" });
  }

  try {
    const articleDoc = await db.collection('articles').doc(articleId).get();
    if (!articleDoc.exists) {
      return res.status(404).json({ error: "Artículo no encontrado" });
    }

    const likeRef = db.collection('article_likes').doc(`${articleId}_${userId}`);
    const likeDoc = await likeRef.get();

    if (action === 'like' && !likeDoc.exists) {
      await likeRef.set({
        articleId,
        userId,
        createdAt: FieldValue.serverTimestamp()
      });
      await db.collection('articles').doc(articleId).update({
        likes: FieldValue.increment(1)
      });
      res.json({ success: true, message: "Like agregado" });
    } else if (action === 'unlike' && likeDoc.exists) {
      await likeRef.delete();
      await db.collection('articles').doc(articleId).update({
        likes: FieldValue.increment(-1)
      });
      res.json({ success: true, message: "Like eliminado" });
    } else {
      res.json({ success: true, message: "Sin cambios" });
    }

  } catch (error) {
    console.error("Error procesando like:", error);
    res.status(500).json({
      error: "Error al procesar like",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// 🔒 GET /:articleId/is-liked/:userId - Verificar si tiene like (PROTEGIDO)
articleRouter.get("/:articleId/is-liked/:userId", verifyFirebaseToken, async (req, res) => {
  const { articleId, userId } = req.params;

  try {
    const likeDoc = await db.collection('article_likes').doc(`${articleId}_${userId}`).get();
    res.json({ isLiked: likeDoc.exists });
  } catch (error) {
    console.error("Error al verificar like:", error);
    res.status(500).json({
      error: "Error al verificar el like",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// 🔒 POST /upload-image - Subir imagen (PROTEGIDO)
articleRouter.post('/upload-image', verifyFirebaseToken, async (req, res) => {
  const psychologistId = req.firebaseUser.uid;
  const imageId = `article_${psychologistId}_${Date.now()}`;
  const [uploadMiddleware, processMiddleware] = genericUploadHandler('articles_images', imageId);
  
  uploadMiddleware(req, res, (err) => {
    if (err) {
      return res.status(400).json({ error: 'Error al procesar el archivo.' });
    }
    
    processMiddleware(req, res, async (err) => {
      if (err) {
        return res.status(500).json({ error: 'Error al subir la imagen.' });
      }

      try {
        res.json({ 
          message: 'Imagen subida exitosamente', 
          imageUrl: req.uploadedFile.url 
        });
      } catch (error) {
        res.status(500).json({ error: 'Error al procesar la imagen.' });
      }
    });
  });
});

export default articleRouter;