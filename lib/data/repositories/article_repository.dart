// lib/data/repositories/article_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/data/models/article_model.dart';

class ArticleRepository {
  final String baseUrl;

  ArticleRepository({required this.baseUrl});

  Future<Article> createArticle(Article article) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/articles/create'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'psychologistId': article.psychologistId,
          'title': article.title,
          'content': article.content,
          'summary': article.summary,
          'imageUrl': article.imageUrl,
          'tags': article.tags,
          'category': article.category,
          'readingTimeMinutes': article.readingTimeMinutes,
          'isPublished': article.isPublished,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        // Crear el objeto Article con el ID devuelto por el servidor
        return Article(
          id: responseData['articleId'],
          psychologistId: article.psychologistId,
          title: article.title,
          content: article.content,
          summary: article.summary,
          imageUrl: article.imageUrl,
          tags: article.tags,
          category: article.category,
          readingTimeMinutes: article.readingTimeMinutes,
          isPublished: article.isPublished,
          createdAt: article.createdAt,
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to create article: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      print('Error creating article: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Article>> getPsychologistArticles(
    String psychologistId, {
    String? status,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final queryParams = {
        if (status != null) 'status': status,
        'limit': limit.toString(),
        'page': page.toString(),
      };

      final uri = Uri.parse('$baseUrl/articles/psychologist/$psychologistId')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Get articles response status: ${response.statusCode}');
      print('Get articles response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> articlesJson = responseData['articles'];
        return articlesJson.map((json) => Article.fromJson(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to load articles: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      print('Error loading articles: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Article> updateArticle(Article article) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/articles/update/${article.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'psychologistId': article.psychologistId,
          'title': article.title,
          'content': article.content,
          'summary': article.summary,
          'imageUrl': article.imageUrl,
          'tags': article.tags,
          'category': article.category,
          'readingTimeMinutes': article.readingTimeMinutes,
          'isPublished': article.isPublished,
        }),
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        return article;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to update article: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      print('Error updating article: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> deleteArticle(String articleId, String psychologistId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/articles/delete/$articleId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'psychologistId': psychologistId}),
      );

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception('Failed to delete article: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      print('Error deleting article: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}