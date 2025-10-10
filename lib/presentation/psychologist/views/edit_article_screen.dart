// lib/presentation/psychologist/views/edit_article_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/article_model.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/article_bloc.dart';
import 'package:ai_therapy_teteocan/data/repositories/article_repository.dart';

class EditArticleScreen extends StatefulWidget {
  final Article article;

  const EditArticleScreen({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  State<EditArticleScreen> createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _summaryController;
  late TextEditingController _categoryController;
  late TextEditingController _tagsController;
  late TextEditingController _readingTimeController;
  
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;
  bool _isPublished = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article.title);
    _contentController = TextEditingController(text: widget.article.content);
    _summaryController = TextEditingController(text: widget.article.summary ?? '');
    _categoryController = TextEditingController(text: widget.article.category ?? '');
    _tagsController = TextEditingController(text: widget.article.tags.join(', '));
    _readingTimeController = TextEditingController(
      text: widget.article.readingTimeMinutes.toString(),
    );
    _uploadedImageUrl = widget.article.imageUrl;
    _isPublished = widget.article.isPublished;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _summaryController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _readingTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isUploadingImage = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Subiendo imagen...'),
                ],
              ),
              duration: Duration(minutes: 2),
            ),
          );
        }

        // Subir imagen 
        final articleRepository = context.read<ArticleRepository>();
        final uploadedUrl = await articleRepository.uploadArticleImage(
          image.path,
          widget.article.psychologistId,
        );

        setState(() {
          _uploadedImageUrl = uploadedUrl;
          _isUploadingImage = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Imagen actualizada exitosamente'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      print('Error al subir imagen: $e');
    }
  }

  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) return;

    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final updatedArticle = widget.article.copyWith(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      summary: _summaryController.text.trim().isEmpty 
          ? null 
          : _summaryController.text.trim(),
      category: _categoryController.text.trim().isEmpty 
          ? null 
          : _categoryController.text.trim(),
      tags: tags,
      readingTimeMinutes: int.tryParse(_readingTimeController.text) ?? 5,
      imageUrl: _uploadedImageUrl,
      isPublished: _isPublished,
      updatedAt: DateTime.now(),
    );

    context.read<ArticleBloc>().add(UpdateArticle(article: updatedArticle));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Artículo',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: AppConstants.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isUploadingImage ? null : _saveArticle,
          ),
        ],
      ),
      body: BlocListener<ArticleBloc, ArticleState>(
        listener: (context, state) {
          if (state is ArticleOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Artículo actualizado exitosamente')),
            );
            Navigator.of(context).pop();
          } else if (state is ArticleOperationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagen con subida automática
                GestureDetector(
                  onTap: _isUploadingImage ? null : _pickAndUploadImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: _isUploadingImage
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: AppConstants.secondaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Subiendo imagen...',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _selectedImage != null || _uploadedImageUrl != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _selectedImage != null
                                        ? Image.file(
                                            _selectedImage!,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            _uploadedImageUrl!,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.grey[400],
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: _pickAndUploadImage,
                                        color: AppConstants.secondaryColor,
                                      ),
                                    ),
                                  ),
                                  if (_uploadedImageUrl != null && _selectedImage != null)
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Actualizada',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 50,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Toca para cambiar imagen',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La imagen se subirá automáticamente al seleccionarla',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Título
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(fontFamily: 'Poppins'),
                  ),
                  style: const TextStyle(fontFamily: 'Poppins'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa un título';
                    }
                    return null;
                  },
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Resumen
                TextFormField(
                  controller: _summaryController,
                  decoration: const InputDecoration(
                    labelText: 'Resumen (opcional)',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(fontFamily: 'Poppins'),
                  ),
                  style: const TextStyle(fontFamily: 'Poppins'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Contenido
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Contenido',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(fontFamily: 'Poppins'),
                  ),
                  style: const TextStyle(fontFamily: 'Poppins'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa el contenido';
                    }
                    return null;
                  },
                  maxLines: 10,
                ),
                const SizedBox(height: 16),

                // Categoría
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Categoría (opcional)',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(fontFamily: 'Poppins'),
                  ),
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 16),

                // Tags
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Etiquetas (separadas por comas)',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(fontFamily: 'Poppins'),
                    hintText: 'ansiedad, depresión, bienestar',
                  ),
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 16),

                // Tiempo de lectura
                TextFormField(
                  controller: _readingTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Tiempo de lectura (minutos)',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(fontFamily: 'Poppins'),
                  ),
                  style: const TextStyle(fontFamily: 'Poppins'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Botón guardar
                ElevatedButton(
                  onPressed: _isUploadingImage ? null : _saveArticle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.secondaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isUploadingImage
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}