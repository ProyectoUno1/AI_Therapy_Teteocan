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
      final url = '$baseUrl/articles/psychologist/$psychologistId/limit';
      print('🌐 GET ArticleLimit: $url'); // Debug
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return ArticleLimitInfo.fromJson(responseData);
      } else {
        print('❌ Error ArticleLimit: ${response.statusCode}');
        return _getDefaultLimitInfo();
      }
    } catch (e) {
      print('❌ Exception ArticleLimit: $e');
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
      final url = '$baseUrl/articles/create';
      print('🌐 POST CreateArticle: $url'); // Debug
      
      final response = await http.post(
        Uri.parse(url),
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
        print('❌ Error CreateArticle: ${response.statusCode} - ${response.body}');
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear artículo');
      }
    } catch (e) {
      print('❌ Exception CreateArticle: $e');
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
      
      print('🌐 GET PsychologistArticles: $uri'); // Debug
      
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
        print('⚠️ No articles found for psychologist');
        return ArticleListResponse(
          articles: [],
          totalArticles: 0,
          page: page,
          limit: limit,
          articleLimit: _getDefaultLimitInfo(),
        );
      } else {
        print('❌ Error PsychologistArticles: ${response.statusCode}');
        return ArticleListResponse(
          articles: [],
          totalArticles: 0,
          page: page,
          limit: limit,
          articleLimit: _getDefaultLimitInfo(),
        );
      }
    } catch (e) {
      print('❌ Exception PsychologistArticles: $e');
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
      final url = '$baseUrl/articles/update/${article.id}';
      print('🌐 PUT UpdateArticle: $url'); // Debug
      
      final response = await http.put(
        Uri.parse(url),
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
        print('❌ Error UpdateArticle: ${response.statusCode}');
        final errorData = json.decode(response.body);
        throw Exception('Failed to update article: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      print('❌ Exception UpdateArticle: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> deleteArticle(String articleId, String psychologistId) async {
    try {
      final url = '$baseUrl/articles/delete/$articleId';
      print('🌐 DELETE Article: $url'); // Debug
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'psychologistId': psychologistId}),
      );

      if (response.statusCode == 200) {
        print('✅ Article deleted successfully');
      } else {
        print('❌ Error DeleteArticle: ${response.statusCode}');
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? response.body;
        throw Exception('Failed to delete article: $errorMessage');
      }
    } catch (e) {
      print('❌ Exception DeleteArticle: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Article>> getPublishedArticles() async {
  try {
    final url = '$baseUrl/articles/public';
    print('🌐 GET PublishedArticles: $url');
    
    // SOLO headers básicos, SIN Authorization
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // ⚠️ REMOVER esta parte que agrega el token
    // if (authToken != null) {
    //   headers['Authorization'] = 'Bearer $authToken';
    // }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    print('📊 Response Status: ${response.statusCode}');
    print('📊 Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> articlesData = responseData['articles'];
      print('✅ Loaded ${articlesData.length} published articles');
      return articlesData.map((json) => Article.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      print('⚠️ No published articles found');
      return [];
    } else {
      print('❌ Error loading articles: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('❌ Exception loading published articles: $e');
    return [];
  }
}

  Future<String> uploadArticleImage(String imagePath, String psychologistId) async {
    try {
      final uri = Uri.parse('$baseUrl/articles/upload-image');
      print('🌐 POST UploadImage: $uri'); // Debug
      
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
        print('✅ Image uploaded: ${jsonResponse['imageUrl']}');
        return jsonResponse['imageUrl'];
      } else {
        print('❌ Error UploadImage: ${response.statusCode}');
        final errorBody = json.decode(response.body);
        throw Exception('Fallo al subir la imagen: ${errorBody['error'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      print('❌ Exception UploadImage: $e');
      throw Exception('Error de conexión al subir imagen: $e');
    }
  }

  Future<void> likeArticle(String articleId, String userId) async {
    try {
      final url = '$baseUrl/articles/$articleId/like';
      print('🌐 POST LikeArticle: $url'); // Debug
      
      final response = await http.post(
        Uri.parse(url),
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
        print('❌ Error LikeArticle: ${response.statusCode}');
        final errorData = json.decode(response.body);
        throw Exception('Failed to like article: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      print('❌ Exception LikeArticle: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> logArticleView(String articleId) async {
    try {
      final url = '$baseUrl/articles/$articleId/view';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        print('⚠️ Could not log article view');
      }
    } catch (e) {
      print('⚠️ Error logging article view: $e');
    }
  }

  Future<bool> isArticleLiked(String articleId, String userId) async {
    try {
      final url = '$baseUrl/articles/$articleId/is-liked/$userId';
      
      final response = await http.get(
        Uri.parse(url),
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
      final url = '$baseUrl/articles/$articleId';
      print('🌐 GET ArticleById: $url'); // Debug
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(
        Uri.parse(url),
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
        print('❌ Error GetArticleById: ${response.statusCode}');
        final errorData = json.decode(response.body);
        throw Exception('Failed to load article: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Exception GetArticleById: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}