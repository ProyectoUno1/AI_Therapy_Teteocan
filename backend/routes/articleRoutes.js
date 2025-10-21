// articleRoutes.js
import dotenv from "dotenv";
import express from "express";
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../firebase-admin.js';
import { genericUploadHandler } from '../middlewares/upload_handler.js';
import { verifyFirebaseToken } from '../middlewares/auth_middleware.js';

dotenv.config();

const articleRouter = express.Router();

//Límite máximo de artículos por psicólogo
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

//Middleware para verificar límite de artículos
const checkArticleLimit = async (req, res, next) => {
  const { psychologistId } = req.body;

  try {
    // Contar artículos activos (no eliminados)
    const articlesSnapshot = await db.collection('articles')
      .where('psychologistId', '==', psychologistId)
      .where('status', 'in', ['draft', 'published'])
      .get();

    const currentArticleCount = articlesSnapshot.size;

    if (currentArticleCount >= MAX_ARTICLES_PER_PSYCHOLOGIST) {
      return res.status(403).json({
        error: "Límite de artículos alcanzado",
        message: `Has alcanzado el límite de ${MAX_ARTICLES_PER_PSYCHOLOGIST} artículos. Elimina algunos artículos antes de crear nuevos.`,
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

// Endpoint para crear/subir un nuevo artículo
articleRouter.post("/create", validatePsychologist, checkArticleLimit, async (req, res) => {
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
    console.log(`Artículos restantes: ${req.articlesRemaining}`);

    // Crear el artículo en Firebase
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

//Endpoint para obtener el límite y contador de artículos
articleRouter.get("/psychologist/:psychologistId/limit", async (req, res) => {
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
    const canCreateMore = remaining > 0;

    res.json({
      currentCount,
      maxLimit: MAX_ARTICLES_PER_PSYCHOLOGIST,
      remaining,
      canCreateMore,
      percentage: Math.round((currentCount / MAX_ARTICLES_PER_PSYCHOLOGIST) * 100)
    });

  } catch (error) {
    console.error("Error obteniendo límite de artículos:", error);
    res.status(500).json({
      error: "Error al obtener información del límite",
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
    console.log(`Obteniendo artículos para psychologistId: ${psychologistId}`);

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

    // Obtener información del límite
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
      },
      message: articles.length === 0 ? 'No se encontraron artículos para este psicólogo' : undefined
    });

  } catch (error) {
    console.error("Error obteniendo artículos del psicólogo:", error);

    if (error.code === 9 || error.message.includes('index')) {
      return res.status(500).json({
        error: "Es necesario crear un índice en Firestore. Revisa la consola de Firebase.",
        details: process.env.NODE_ENV === 'development' ? error.message : undefined,
        indexUrl: error.message.match(/https:\/\/[^\s]+/)?.[0]
      });
    }

    res.status(500).json({
      error: "Error al obtener artículos",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

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
    const articleDoc = await db.collection('articles').doc(articleId).get();

    if (!articleDoc.exists) {
      return res.status(404).json({ error: "Artículo no encontrado" });
    }

    const articleData = articleDoc.data();
    if (articleData.psychologistId !== psychologistId) {
      return res.status(403).json({ error: "No tienes permisos para editar este artículo" });
    }

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
      updateData.readingTimeMinutes = Math.ceil(content.length / 200);
    }

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

articleRouter.delete("/delete/:articleId", async (req, res) => {
  const { articleId } = req.params;
  const { psychologistId } = req.body;

  if (!articleId || !psychologistId) {
    return res.status(400).json({
      error: "articleId y psychologistId son requeridos."
    });
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

    res.json({
      success: true,
      message: "Artículo eliminado exitosamente"
    });

  } catch (error) {
    res.status(500).json({
      error: "Error al eliminar el artículo",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

articleRouter.get("/public", async (req, res) => {
  const { category, limit = 20, page = 1, search } = req.query;

  try {
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

articleRouter.get("/:articleId", async (req, res) => {
  const { articleId } = req.params;

  try {
    const articleDoc = await db.collection('articles').doc(articleId).get();

    if (!articleDoc.exists) {
      return res.status(404).json({ error: "Artículo no encontrado" });
    }

    const articleData = articleDoc.data();

    res.json({
      success: true, article: {
        id: articleDoc.id,
        ...articleData
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

articleRouter.post("/:articleId/like", async (req, res) => {
  const { articleId } = req.params;
  const { userId, action = 'like' } = req.body;

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
        await likeRef.set({
          articleId: articleId,
          userId: userId,
          createdAt: FieldValue.serverTimestamp()
        });

        await db.collection('articles').doc(articleId).update({
          likes: FieldValue.increment(1)
        });

        res.json({ success: true, message: "Like agregado" });
      } else {
        res.json({ success: true, message: "Ya has dado like a este artículo" });
      }
    } else if (action === 'unlike') {
      if (likeDoc.exists) {
        await likeRef.delete();

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

articleRouter.get("/:articleId/is-liked/:userId", async (req, res) => {
  const { articleId, userId } = req.params;

  if (!articleId || !userId) {
    return res.status(400).json({ error: "articleId y userId son requeridos" });
  }

  try {
    const likeDoc = await db.collection('article_likes').doc(`${articleId}_${userId}`).get();

    const isLiked = likeDoc.exists;

    res.json({ isLiked: isLiked });
  } catch (error) {
    console.error("Error al verificar like:", error);
    res.status(500).json({
      error: "Error al verificar el like",
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

articleRouter.post('/upload-image', verifyFirebaseToken, async (req, res) => {
  const psychologistId = req.firebaseUser.uid;
  const imageId = `article_${psychologistId}_${Date.now()}`;
  const [uploadMiddleware, processMiddleware] = genericUploadHandler('articles_images', imageId);
  uploadMiddleware(req, res, (err) => {
    if (err) {
      console.error('Error en multer middleware:', err);
      return res.status(400).json({ error: 'Error al procesar el archivo.' });
    }
    
    processMiddleware(req, res, async (err) => {
      if (err) {
        console.error('Error en Cloudinary middleware:', err);
        return res.status(500).json({ error: 'Error al subir la imagen a Cloudinary.' });
      }

      try {
        const imageUrl = req.uploadedFile.url;
        
        res.json({ 
          message: 'Imagen de artículo subida exitosamente', 
          imageUrl: imageUrl 
        });
      } catch (error) {
        console.error('Error al procesar la imagen:', error);
        res.status(500).json({ error: 'Error al procesar la imagen.' });
      }
    });
  });
});

export default articleRouter;