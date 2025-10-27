// lib/data/models/article_limit_info.dart

class ArticleLimitInfo {
  final int currentCount;
  final int maxLimit;
  final int remaining;
  final int percentage;
  final bool canCreateMore;

  const ArticleLimitInfo({
    required this.currentCount,
    required this.maxLimit,
    required this.remaining,
    required this.percentage,
    required this.canCreateMore,
  });

  factory ArticleLimitInfo.fromJson(Map<String, dynamic> json) {
    final currentCount = json['currentCount'] ?? 0;
    final maxLimit = json['maxLimit'] ?? 0;
    final remaining = json['remaining'] ?? 0;
    final percentage = json['percentage'] ?? 0;
    final canCreateMore = json['canCreateMore'] ?? false;

    return ArticleLimitInfo(
      currentCount: currentCount,
      maxLimit: maxLimit,
      remaining: remaining,
      percentage: percentage,
      canCreateMore: canCreateMore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentCount': currentCount,
      'maxLimit': maxLimit,
      'remaining': remaining,
      'percentage': percentage,
      'canCreateMore': canCreateMore,
    };
  }

  @override
  String toString() {
    return 'ArticleLimitInfo(currentCount: $currentCount, maxLimit: $maxLimit, remaining: $remaining, percentage: $percentage, canCreateMore: $canCreateMore)';
  }

  ArticleLimitInfo copyWith({
    int? currentCount,
    int? maxLimit,
    int? remaining,
    int? percentage,
    bool? canCreateMore,
  }) {
    return ArticleLimitInfo(
      currentCount: currentCount ?? this.currentCount,
      maxLimit: maxLimit ?? this.maxLimit,
      remaining: remaining ?? this.remaining,
      percentage: percentage ?? this.percentage,
      canCreateMore: canCreateMore ?? this.canCreateMore,
    );
  }
}