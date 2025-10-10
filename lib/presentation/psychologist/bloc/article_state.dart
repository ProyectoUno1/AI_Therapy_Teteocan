// lib/presentation/psychologist/bloc/article_state.dart
part of 'article_bloc.dart';

abstract class ArticleState extends Equatable {
  const ArticleState();

  @override
  List<Object?> get props => [];
}

class ArticleInitial extends ArticleState {}

class ArticlesLoading extends ArticleState {}

class ArticlesLoaded extends ArticleState {
  final List<Article> articles;
  final ArticleLimitInfo? limitInfo;

  const ArticlesLoaded({
    required this.articles,
    this.limitInfo,
  });
  ArticlesLoaded copyWith({
    List<Article>? articles,
    ArticleLimitInfo? limitInfo,
  }) {
    return ArticlesLoaded(
      articles: articles ?? this.articles,
      limitInfo: limitInfo ?? this.limitInfo,
    );
  }

  @override
  List<Object?> get props => [articles, limitInfo];
}

class ArticleLimitLoaded extends ArticleState {
  final ArticleLimitInfo limitInfo;

  const ArticleLimitLoaded({required this.limitInfo});

  @override
  List<Object> get props => [limitInfo];
}

class ArticleOperationInProgress extends ArticleState {}

class ArticleOperationSuccess extends ArticleState {
  final Article? article;

  const ArticleOperationSuccess({this.article});

  @override
  List<Object?> get props => [article];
}

class ArticleOperationError extends ArticleState {
  final String message;

  const ArticleOperationError({required this.message});

  @override
  List<Object> get props => [message];
}

class ArticlesError extends ArticleState {
  final String message;

  const ArticlesError({required this.message});

  @override
  List<Object> get props => [message];
}