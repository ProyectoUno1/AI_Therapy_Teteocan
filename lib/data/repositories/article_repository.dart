// lib/data/repositories/article_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/data/models/article_model.dart';
import 'package:ai_therapy_teteocan/data/models/article_limit_info.dart';


class ArticleRepository {
  final String baseUrl;
  final Future<String?> Function()? getAuthToken; 

  ArticleRepository({
    required this.baseUrl,
    this.getAuthToken, 
  });
  

Future<Map<String, dynamic>> getPsychologistArticles(
  String psychologistId, {
  String? status,
  int limit = 10,
  int page = 1,
}) async {
  try {
    final url = '$baseUrl/articles/psychologist/$psychologistId';
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    String? currentAuthToken;
    if (getAuthToken != null) {
      currentAuthToken = await getAuthToken!();
    }

    if (currentAuthToken != null) {
      headers['Authorization'] = 'Bearer $currentAuthToken';
    } else {
      throw Exception('Authentication required');
    }

    final queryParams = <String, String>{
      'limit': limit.toString(),
      'page': page.toString(),
    };
    if (status != null) {
      queryParams['status'] = status;
    }

    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return responseData;
    } else {
      throw Exception('Failed to load articles: ${response.statusCode}');
    }
  } catch (e) {
    rethrow; 
  }
}


  Future<List<Article>> getPublishedArticles() async {
    try {
      final url = '$baseUrl/articles/public';
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> articlesData = responseData['articles'];
        return articlesData.map((json) => Article.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Article?> getArticleById(String articleId) async {
    try {
      final url = '$baseUrl/articles/$articleId';
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return Article.fromJson(responseData['article']);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> logArticleView(String articleId) async {
    try {
      final url = '$baseUrl/articles/$articleId/view';
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }


Future<Article> createArticle(Article article) async {
    try {
      final url = '$baseUrl/articles/create';
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      String? currentAuthToken;
      if (getAuthToken != null) {
        currentAuthToken = await getAuthToken!();
      }

      if (currentAuthToken != null) {
        headers['Authorization'] = 'Bearer $currentAuthToken';
      } else {
        throw Exception('Authentication required');
      }

      final body = json.encode(article.toJson());

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final articleId = responseData['articleId'];
        
        return article.copyWith(id: articleId);
      } else {
        throw Exception('Failed to create article: ${response.statusCode}');
      }
    } catch (e) {
      throw e;
    }
  }

  Future<ArticleLimitInfo?> getArticleLimit(String psychologistId) async {
    try {
      final url = '$baseUrl/articles/psychologist/$psychologistId/limit';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      String? currentAuthToken;
      if (getAuthToken != null) {
        currentAuthToken = await getAuthToken!();
      }

      if (currentAuthToken != null) {
        headers['Authorization'] = 'Bearer $currentAuthToken';
      } else {
        return null;
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        return ArticleLimitInfo.fromJson(responseData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateArticle(Article article) async {
    try {
      final url = '$baseUrl/articles/update/${article.id}';
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      String? currentAuthToken;
      if (getAuthToken != null) {
        currentAuthToken = await getAuthToken!();
      }

      if (currentAuthToken != null) {
        headers['Authorization'] = 'Bearer $currentAuthToken';
      } else {
        return false;
      }

      final body = json.encode(article.toJson());

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteArticle(String articleId, String psychologistId) async {
    try {
      final url = '$baseUrl/articles/delete/$articleId';
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      String? currentAuthToken;
      if (getAuthToken != null) {
        currentAuthToken = await getAuthToken!();
      }

      if (currentAuthToken != null) {
        headers['Authorization'] = 'Bearer $currentAuthToken';
      } else {
        return false;
      }

      final body = json.encode({
        'psychologistId': psychologistId,
      });

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> likeArticle(String articleId, String userId, String action) async {
    try {
      final url = '$baseUrl/articles/$articleId/like';
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      String? currentAuthToken;
      if (getAuthToken != null) {
        currentAuthToken = await getAuthToken!();
      }

      if (currentAuthToken != null) {
        headers['Authorization'] = 'Bearer $currentAuthToken';
      } else {
        return false;
      }

      final body = json.encode({
        'userId': userId,
        'action': action, 
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> isArticleLiked(String articleId, String userId) async {
    try {
      final url = '$baseUrl/articles/$articleId/is-liked/$userId';
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      String? currentAuthToken;
      if (getAuthToken != null) {
        currentAuthToken = await getAuthToken!();
      }

      if (currentAuthToken != null) {
        headers['Authorization'] = 'Bearer $currentAuthToken';
      } else {
        return false;
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['isLiked'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<String> uploadArticleImage(String imagePath, String psychologistId) async {
    try {
      final url = '$baseUrl/articles/upload-image';
      var request = http.MultipartRequest('POST', Uri.parse(url));
      String? currentAuthToken;
      if (getAuthToken != null) {
        currentAuthToken = await getAuthToken!();
      }

      if (currentAuthToken != null) {
        request.headers['Authorization'] = 'Bearer $currentAuthToken';
      } else {
        throw Exception('No authentication token available');
      }

      // Agregar archivo
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imagePath,
      ));

      // Enviar request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(responseBody);
        final imageUrl = responseData['imageUrl'];
        return imageUrl;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      throw e;
    }
  }

}