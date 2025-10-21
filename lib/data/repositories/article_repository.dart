// lib/data/repositories/article_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/data/models/article_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArticleLimitInfo {
  final int currentCount;
  final int maxLimit;
  final int remaining;
  final bool canCreateMore;
  final int percentage;

  ArticleLimitInfo({
    required this.currentCount,
    required this.maxLimit,
    required this.remaining,
    required this.canCreateMore,
    required this.percentage,
  });

  factory ArticleLimitInfo.fromJson(Map<String, dynamic> json) {
    return ArticleLimitInfo(
      currentCount: json['currentCount'] ?? 0,
      maxLimit: json['maxLimit'] ?? 10,
      remaining: json['remaining'] ?? 0,
      canCreateMore: json['canCreateMore'] ?? false,
      percentage: json['percentage'] ?? 0,
    );
  }
}

class ArticleListResponse {
  final List<Article> articles;
  final int totalArticles;
  final int page;
  final int limit;
  final ArticleLimitInfo? articleLimit;

  ArticleListResponse({
    required this.articles,
    required this.totalArticles,
    required this.page,
    required this.limit,
    this.articleLimit,
  });

  factory ArticleListResponse.fromJson(Map<String, dynamic> json) {
    final articlesList = json['articles'] as List<dynamic>?;
    final articles = (articlesList ?? [])
        .map((item) {
          try {
            return Article.fromJson(item as Map<String, dynamic>);
          } catch (e) {
            print('Error parsing article: $e');
            return null;
          }
        })
        .whereType<Article>()
        .toList();
    
    ArticleLimitInfo? limitInfo;
    if (json['articleLimit'] != null) {
      try {
        limitInfo = ArticleLimitInfo.fromJson(json['articleLimit']);
      } catch (e) {
        print('Error parsing articleLimit: $e');
      }
    }
    
    return ArticleListResponse(
      articles: articles,
      totalArticles: json['totalArticles'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      articleLimit: limitInfo,
    );
  }
}

class ArticleRepository {
  final String baseUrl;
  final String? authToken;

  ArticleRepository({required this.baseUrl, this.authToken});

  Future<ArticleLimitInfo> getArticleLimit(String psychologistId) async {
    try {
      final uri = Uri.parse('$baseUrl/articles/psychologist/$psychologistId/limit');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return ArticleLimitInfo.fromJson(responseData);
      } else {
        return _getDefaultLimitInfo();
      }
    } catch (e) {
      return _getDefaultLimitInfo();
    }
  }

  ArticleLimitInfo _getDefaultLimitInfo() {
    return ArticleLimitInfo(
      currentCount: 0,
      maxLimit: 10,
      remaining: 10,
      canCreateMore: true,
      percentage: 0,
    );
  }

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

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
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
          status: article.isPublished ? 'published' : 'draft',
          createdAt: DateTime.now(),
        );
      } else if (response.statusCode == 403) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Has alcanzado el límite de artículos');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear artículo');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ArticleListResponse> getPsychologistArticles(
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


      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return ArticleListResponse.fromJson(responseData);
      } else if (response.statusCode == 404) {
        return ArticleListResponse(
          articles: [],
          totalArticles: 0,
          page: page,
          limit: limit,
          articleLimit: _getDefaultLimitInfo(),
        );
      } else {
        return ArticleListResponse(
          articles: [],
          totalArticles: 0,
          page: page,
          limit: limit,
          articleLimit: _getDefaultLimitInfo(),
        );
      }
    } catch (e) {
      return ArticleListResponse(
        articles: [],
        totalArticles: 0,
        page: page,
        limit: limit,
        articleLimit: _getDefaultLimitInfo(),
      );
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

      if (response.statusCode == 200) {
        return article;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to update article: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
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

      if (response.statusCode == 200) {
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? response.body;
        throw Exception('Failed to delete article: $errorMessage');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Article>> getPublishedArticles() async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/articles/public'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> articlesData = responseData['articles'];
        return articlesData.map((json) => Article.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error loading published articles: $e');
      return [];
    }
  }

  Future<String> uploadArticleImage(String imagePath, String psychologistId) async {
    try {
      final uri = Uri.parse('$baseUrl/articles/upload-image');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }
      
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $idToken';

      request.files.add(
        await http.MultipartFile.fromPath(
          'imageFile',
          imagePath,
        ),
      );
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['imageUrl'];
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Fallo al subir la imagen: ${errorBody['error'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      throw Exception('Error de conexión al subir imagen: $e');
    }
  }


  Future<void> likeArticle(String articleId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/articles/$articleId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'action': 'like',
        }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception('Failed to like article: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> logArticleView(String articleId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/articles/$articleId/view'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        print('Warning: Could not log article view');
      }
    } catch (e) {
      print('Error logging article view: $e');
      // No lanzar error, solo log
    }
  }

  Future<bool> isArticleLiked(String articleId, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/articles/$articleId/is-liked/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['isLiked'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Article> getArticleById(String articleId) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/articles/$articleId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey('article')) {
          return Article.fromJson(responseData['article']);
        } else {
          throw Exception('Invalid response format: missing "article" key');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to load article: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}