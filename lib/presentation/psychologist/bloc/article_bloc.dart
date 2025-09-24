// lib/presentation/psychologist/bloc/article_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/article_model.dart';
import 'package:ai_therapy_teteocan/data/repositories/article_repository.dart';

part 'article_event.dart';
part 'article_state.dart';

class ArticleBloc extends Bloc<ArticleEvent, ArticleState> {
  final ArticleRepository articleRepository;
  final String psychologistId;

  ArticleBloc({
    required this.articleRepository,
    required this.psychologistId,
  }) : super(ArticleInitial()) {
    on<LoadArticles>(_onLoadArticles);
    on<CreateArticle>(_onCreateArticle);
    on<UpdateArticle>(_onUpdateArticle);
    on<DeleteArticle>(_onDeleteArticle);
    on<LoadPublishedArticles>(_onLoadPublishedArticles);
  }

  Future<void> _onLoadArticles(LoadArticles event, Emitter<ArticleState> emit) async {
    emit(ArticlesLoading());
    try {
      final articles = await articleRepository.getPsychologistArticles(
        psychologistId,
        status: event.status,
        limit: event.limit,
        page: event.page,
      );
      emit(ArticlesLoaded(articles: articles));
    } catch (e) {
      emit(ArticlesError(message: e.toString()));
    }
  }

  Future<void> _onCreateArticle(CreateArticle event, Emitter<ArticleState> emit) async {
    emit(ArticleOperationInProgress());
    try {
      final articleWithPsychologistId = event.article.copyWith(
        psychologistId: psychologistId,
        createdAt: DateTime.now(),
      );
      final createdArticle = await articleRepository.createArticle(articleWithPsychologistId);
      emit(ArticleOperationSuccess(article: createdArticle));
      
      // Recargar la lista de artículos después de crear uno nuevo
      add(LoadArticles());
    } catch (e) {
      emit(ArticleOperationError(message: e.toString()));
    }
  }

  Future<void> _onUpdateArticle(UpdateArticle event, Emitter<ArticleState> emit) async {
    emit(ArticleOperationInProgress());
    try {
      final updatedArticle = await articleRepository.updateArticle(event.article);
      emit(ArticleOperationSuccess(article: updatedArticle));
      
      // Recargar la lista de artículos después de actualizar
      add(LoadArticles());
    } catch (e) {
      emit(ArticleOperationError(message: e.toString()));
    }
  }

  Future<void> _onDeleteArticle(DeleteArticle event, Emitter<ArticleState> emit) async {
    emit(ArticleOperationInProgress());
    try {
      await articleRepository.deleteArticle(event.articleId, psychologistId);
      emit(ArticleOperationSuccess());
      
      // Recargar la lista de artículos después de eliminar
      add(LoadArticles());
    } catch (e) {
      emit(ArticleOperationError(message: e.toString()));
    }
  }

  Future<void> _onLoadPublishedArticles(LoadPublishedArticles event, Emitter<ArticleState> emit) async {
    emit(ArticlesLoading());
    try {
      final articles = await articleRepository.getPublishedArticles();
      emit(ArticlesLoaded(articles: articles));
    } catch (e) {
      emit(ArticlesError(message: e.toString()));
    }
  }
}