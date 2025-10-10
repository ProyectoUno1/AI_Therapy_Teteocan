// lib/presentation/patient/views/article_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/data/models/article_model.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/repositories/article_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;
  final String patientId;

  const ArticleDetailScreen({
    super.key,
    required this.article,
    required this.patientId,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late Article _currentArticle;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _currentArticle = widget.article;
    _logView();
    _checkIfArticleIsLiked();
  }

  void _logView() async {
    if (_currentArticle.id != null) {
      final articleRepo = RepositoryProvider.of<ArticleRepository>(context);

      // 1. Registra la vista en el servidor.
      await articleRepo.logArticleView(_currentArticle.id!);

      // 2. Obtiene el artículo actualizado con el nuevo contador de vistas.
      try {
        final updatedArticle = await articleRepo.getArticleById(
          _currentArticle.id!,
        );

        // 3. Actualiza el estado del widget con el artículo actualizado.
        if (mounted) {
          setState(() {
            _currentArticle = updatedArticle;
          });
        }
      } catch (e) {
        print('Error al actualizar las vistas: $e');
      }
    }
  }

  Future<void> _checkIfArticleIsLiked() async {
    if (_currentArticle.id == null) return;

    final articleRepo = RepositoryProvider.of<ArticleRepository>(context);
    final isLiked = await articleRepo.isArticleLiked(
      _currentArticle.id!,
      widget.patientId,
    );

    setState(() {
      _isLiked = isLiked;
    });
  }

  void _toggleLike() {
    if (_currentArticle.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede dar "Me gusta" a este artículo.'),
        ),
      );
      return;
    }

    final articleRepo = RepositoryProvider.of<ArticleRepository>(context);
    final userId = widget.patientId;

    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _currentArticle.likes++;
      } else {
        _currentArticle.likes--;
      }
    });

    articleRepo.likeArticle(_currentArticle.id!, userId).catchError((e) {
      setState(() {
        _isLiked = !_isLiked;
        if (_isLiked) {
          _currentArticle.likes++;
        } else {
          _currentArticle.likes--;
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = _currentArticle.publishedAt != null
        ? '${_currentArticle.publishedAt!.day}/${_currentArticle.publishedAt!.month}/${_currentArticle.publishedAt!.year}'
        : 'Fecha desconocida';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artículo', style: TextStyle(fontFamily: 'Poppins')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _currentArticle.imageUrl ?? '',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 50,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentArticle.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Por ${_currentArticle.fullName ?? 'Autor Desconocido'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.remove_red_eye_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${_currentArticle.views} vistas',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: _isLiked ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentArticle.likes}',
                        style: TextStyle(
                          color: _isLiked ? Colors.red : Colors.grey[600],
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${_currentArticle.readingTimeMinutes} min de lectura',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 16),
                if (_currentArticle.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: _currentArticle.tags.map((tag) {
                      return Chip(
                        label: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        backgroundColor: AppConstants.lightAccentColor
                            .withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: AppConstants.lightAccentColor,
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _currentArticle.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}