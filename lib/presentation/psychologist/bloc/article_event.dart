// lib/presentation/psychologist/bloc/article_event.dart
part of 'article_bloc.dart';

abstract class ArticleEvent extends Equatable {
  const ArticleEvent();

  @override
  List<Object> get props => [];
}

class LoadArticles extends ArticleEvent {
  final String? status;
  final int limit;
  final int page;

  const LoadArticles({this.status, this.limit = 10, this.page = 1});

  @override
  List<Object> get props => [limit, page, status ?? ''];
}

class LoadArticleLimit extends ArticleEvent {
  const LoadArticleLimit();
}

class LoadPublishedArticles extends ArticleEvent {}

class CreateArticle extends ArticleEvent {
  final Article article;

  const CreateArticle({required this.article});

  @override
  List<Object> get props => [article];
}

class UpdateArticle extends ArticleEvent {
  final Article article;

  const UpdateArticle({required this.article});

  @override
  List<Object> get props => [article];
}

class DeleteArticle extends ArticleEvent {
  final String articleId;

  const DeleteArticle({required this.articleId});

  @override
  List<Object> get props => [articleId];
}