// lib/data/services/article_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ArticleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Obtener artículos de un psicólogo
  Stream<List<Article>> getArticlesByPsychologist(String psychologistId) {
    return _firestore
        .collection('articles')
        .where('psychologistId', isEqualTo: psychologistId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Article.fromFirestore(doc))
            .toList());
  }

  // Obtener un artículo específico
  Future<Article?> getArticle(String articleId) async {
    try {
      final doc = await _firestore.collection('articles').doc(articleId).get();
      if (doc.exists) {
        return Article.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Actualizar artículo
  Future<bool> updateArticle(String articleId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('articles').doc(articleId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Eliminar artículo
  Future<bool> deleteArticle(String articleId, String? imageUrl) async {
    try {
      // Eliminar imagen de Storage si existe
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          print('Error al eliminar imagen: $e');
        }
      }

      // Eliminar documento de Firestore
      await _firestore.collection('articles').doc(articleId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Modelo de Artículo
class Article {
  final String id;
  final String psychologistId;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Article({
    required this.id,
    required this.psychologistId,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Article.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Article(
      id: doc.id,
      psychologistId: data['psychologistId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'psychologistId': psychologistId,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}