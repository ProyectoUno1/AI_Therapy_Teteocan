// lib/data/models/article_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseFirebaseTimestamp(dynamic data) {
  if (data == null) return null;
  
  try {
    if (data is Timestamp) {
      return data.toDate();
    }
    
    if (data is DateTime) {
      return data;
    }
    
    if (data is Map<String, dynamic>) {
      final seconds = data['_seconds'];
      final nanoseconds = data['_nanoseconds'];
      if (seconds is int && nanoseconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + nanoseconds ~/ 1000000,
        );
      }
    }
 
    if (data is String) {
      return DateTime.tryParse(data);
    }
    
    return null;
  } catch (e) {
    return null;
  }
}

class Article {
  String? id;
  final String psychologistId;
  final String title;
  final String content;
  final String? summary;
  final String? imageUrl;
  final List<String> tags;
  final String? category;
  final int readingTimeMinutes;
  final bool isPublished;
  final String? status;
  final String? fullName;
  final int views;
  int likes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  Article({
    this.id,
    required this.psychologistId,
    required this.title,
    required this.content,
    this.summary,
    this.imageUrl,
    this.tags = const [],
    this.category,
    required this.readingTimeMinutes,
    this.isPublished = false,
    this.status,
    this.fullName,
    this.views = 0,
    this.likes = 0,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    
    final article = Article(
      id: json['id'],
      psychologistId: json['psychologistId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String?,
      imageUrl: json['imageUrl'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'] as String?,
      readingTimeMinutes: json['readingTimeMinutes'] as int? ?? 0,
      isPublished: json['isPublished'] as bool? ?? false,
      status: json['status'] as String?,
      fullName: json['fullName'] as String?,
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      createdAt: _parseFirebaseTimestamp(json['createdAt']),
      updatedAt: _parseFirebaseTimestamp(json['updatedAt']),
      publishedAt: _parseFirebaseTimestamp(json['publishedAt']),
    );
  
    return article;
  }

  Map<String, dynamic> toMap() {
    return {
      'psychologistId': psychologistId,
      'title': title,
      'content': content,
      'summary': summary,
      'imageUrl': imageUrl,
      'tags': tags,
      'category': category,
      'readingTimeMinutes': readingTimeMinutes,
      'isPublished': isPublished,
      'status': status,
      'fullName': fullName,
      'views': views,
      'likes': likes,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'publishedAt': publishedAt?.millisecondsSinceEpoch,
    };
  }
  Article copyWith({
    String? id,
    String? psychologistId,
    String? title,
    String? content,
    String? summary,
    String? imageUrl,
    List<String>? tags,
    String? category,
    int? readingTimeMinutes,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    String? fullName,
    int? likes,
    int? views,
  }) {
    return Article(
      id: id ?? this.id,
      psychologistId: psychologistId ?? this.psychologistId,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      fullName: fullName ?? this.fullName,
      likes: likes ?? this.likes,
      views: views ?? this.views,
    );
  }

  @override
  List<Object?> get props => [
        id,
        psychologistId,
        title,
        content,
        summary,
        imageUrl,
        tags,
        category,
        readingTimeMinutes,
        isPublished,
        createdAt,
        updatedAt,
        publishedAt,
        fullName,
        likes,
        views,
      ];
}