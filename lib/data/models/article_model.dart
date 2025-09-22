// lib/data/models/article_model.dart
import 'package:equatable/equatable.dart';

class Article extends Equatable {
  final String? id;
  final String psychologistId;
  final String title;
  final String content;
  final String summary;
  final String imageUrl;
  final List<String> tags;
  final String category;
  final int readingTimeMinutes;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  const Article({
    this.id,
    required this.psychologistId,
    required this.title,
    required this.content,
    required this.summary,
    required this.imageUrl,
    required this.tags,
    required this.category,
    required this.readingTimeMinutes,
    required this.isPublished,
    required this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'psychologistId': psychologistId,
      'title': title,
      'content': content,
      'summary': summary,
      'imageUrl': imageUrl,
      'tags': tags,
      'category': category,
      'readingTimeMinutes': readingTimeMinutes,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
    };
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      psychologistId: json['psychologistId'],
      title: json['title'],
      content: json['content'],
      summary: json['summary'],
      imageUrl: json['imageUrl'],
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'],
      readingTimeMinutes: json['readingTimeMinutes'],
      isPublished: json['isPublished'],
      createdAt: json['createdAt'] is String 
        ? DateTime.parse(json['createdAt'])
        : DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: json['updatedAt'] != null
        ? (json['updatedAt'] is String 
          ? DateTime.parse(json['updatedAt'])
          : DateTime.fromMillisecondsSinceEpoch(json['updatedAt']))
        : null,
      publishedAt: json['publishedAt'] != null
        ? (json['publishedAt'] is String 
          ? DateTime.parse(json['publishedAt'])
          : DateTime.fromMillisecondsSinceEpoch(json['publishedAt']))
        : null,
    );
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
      ];
}