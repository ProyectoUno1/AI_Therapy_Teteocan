// lib/presentation/psychologist/bloc/article_state.dart
part of 'article_bloc.dart';

abstract class ArticleState extends Equatable {
  const ArticleState();

  @override
  List<Object> get props => [];
}

class ArticleInitial extends ArticleState {}

class ArticlesLoading extends ArticleState {}

class ArticlesLoaded extends ArticleState {
  final List<Article> articles;

  const ArticlesLoaded({required this.articles});

  @override
  List<Object> get props => [articles];
}

class ArticleOperationInProgress extends ArticleState {}

class ArticleOperationSuccess extends ArticleState {
  final Article? article;

  const ArticleOperationSuccess({this.article});

  @override
  List<Object> get props => [article ?? Article];
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