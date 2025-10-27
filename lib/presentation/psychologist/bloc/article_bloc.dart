// lib/presentation/psychologist/bloc/article_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/article_model.dart';
import 'package:ai_therapy_teteocan/data/repositories/article_repository.dart';
import 'package:ai_therapy_teteocan/data/models/article_limit_info.dart';

part 'article_event.dart';
part 'article_state.dart';

class ArticleBloc extends Bloc<ArticleEvent, ArticleState> {
  final ArticleRepository articleRepository;
  final String? psychologistId; 

  ArticleBloc({
    required this.articleRepository,
    this.psychologistId,
  }) : super(ArticleInitial()) {
    on<LoadArticles>(_onLoadArticles);
    on<LoadArticleLimit>(_onLoadArticleLimit);
    on<CreateArticle>(_onCreateArticle);
    on<UpdateArticle>(_onUpdateArticle);
    on<DeleteArticle>(_onDeleteArticle);
    on<LoadPublishedArticles>(_onLoadPublishedArticles);
  }

  // ✅ AGREGAR ESTE MÉTODO
  String? _getCurrentPsychologistId() {
    print('👤 Psychologist ID para ArticleBloc: $psychologistId');
    return psychologistId;
  }

  // El resto del código permanece igual...
  Future<void> _onLoadArticles(
    LoadArticles event,
    Emitter<ArticleState> emit,
  ) async {
    try {
      emit(ArticlesLoading());
      
      final psychologistId = _getCurrentPsychologistId();
      if (psychologistId == null) {
        emit(const ArticlesError(message: 'No se pudo obtener el ID del psicólogo'));
        return;
      }

      // ✅ Obtener la respuesta cruda
      final responseData = await articleRepository.getPsychologistArticles(
        psychologistId,
      );

      // ✅ PARSEAR AQUÍ, no en el repository
      final List<dynamic> articlesJson = responseData['articles'] ?? [];
      final articles = articlesJson
          .map((json) => Article.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // ✅ Parsear el límite
      final ArticleLimitInfo? limitInfo = responseData['articleLimit'] != null
          ? ArticleLimitInfo.fromJson(responseData['articleLimit'] as Map<String, dynamic>)
          : null;

      print('✅ Parsed ${articles.length} articles successfully');

      emit(ArticlesLoaded(
        articles: articles,
        limitInfo: limitInfo,
      ));
    } catch (e, stackTrace) {
      print('❌ Error loading articles: $e');
      print('❌ StackTrace: $stackTrace');
      emit(ArticlesError(message: e.toString()));
    }
  }

  Future<void> _onLoadArticleLimit(
    LoadArticleLimit event,
    Emitter<ArticleState> emit,
  ) async {
    if (psychologistId == null) {
      return;
    }

    try {
      final limitInfo = await articleRepository.getArticleLimit(psychologistId!);
      
      if (state is ArticlesLoaded) {
        final currentState = state as ArticlesLoaded;
        emit(currentState.copyWith(limitInfo: limitInfo));
      } else if (limitInfo != null) {
        emit(ArticleLimitLoaded(limitInfo: limitInfo));
      }
    } catch (e) {
      print('Error loading article limit: $e');
    }
  }

  Future<void> _onCreateArticle(
    CreateArticle event,
    Emitter<ArticleState> emit,
  ) async {
    if (psychologistId == null) {
      emit(const ArticleOperationError(
        message: 'Se requiere psychologistId para crear artículos',
      ));
      return;
    }

    emit(ArticleOperationInProgress());
    try {
      final articleWithPsychologistId = event.article.copyWith(
        psychologistId: psychologistId!,
        createdAt: DateTime.now(),
      );
      
      final createdArticle = await articleRepository.createArticle(
        articleWithPsychologistId,
      );
      
      emit(ArticleOperationSuccess(article: createdArticle));
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      add(const LoadArticles());
      
    } catch (e) {
      String errorMessage = e.toString();
      
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceAll('Exception:', '').trim();
      }
      
      emit(ArticleOperationError(message: errorMessage));
    }
  }

  Future<void> _onUpdateArticle(
    UpdateArticle event,
    Emitter<ArticleState> emit,
  ) async {
    if (psychologistId == null) {
      emit(const ArticleOperationError(
        message: 'Se requiere psychologistId para actualizar artículos',
      ));
      return;
    }

    emit(ArticleOperationInProgress());
    try {
      final success = await articleRepository.updateArticle(
        event.article,
      );
      
      emit(ArticleOperationSuccess(article: success ? event.article : null));
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      add(const LoadArticles());
      
    } catch (e) {
      emit(ArticleOperationError(message: e.toString()));
    }
  }

  Future<void> _onDeleteArticle(
    DeleteArticle event,
    Emitter<ArticleState> emit,
  ) async {
    if (psychologistId == null) {
      emit(const ArticleOperationError(
        message: 'Se requiere psychologistId para eliminar artículos',
      ));
      return;
    }

    final previousState = state;
    
    emit(ArticleOperationInProgress());
    
    try {
      await articleRepository.deleteArticle(event.articleId, psychologistId!);
      emit(const ArticleOperationSuccess());
 
      await Future.delayed(const Duration(milliseconds: 800));

      if (previousState is ArticlesLoaded) {
        final updatedArticles = previousState.articles
            .where((article) => article.id != event.articleId)
            .toList();
        emit(ArticlesLoaded(
          articles: updatedArticles,
          limitInfo: previousState.limitInfo,
        ));
      }

      add(const LoadArticles());
      
    } catch (e) {
      emit(ArticleOperationError(message: e.toString()));

      if (previousState is ArticlesLoaded) {
        emit(previousState);
      }
    }
  }

  Future<void> _onLoadPublishedArticles(
    LoadPublishedArticles event,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticlesLoading());
    try {
      final articles = await articleRepository.getPublishedArticles();
      emit(ArticlesLoaded(articles: articles));
    } catch (e) {
      emit(ArticlesError(message: e.toString()));
    }
  }
}