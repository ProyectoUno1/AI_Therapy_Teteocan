// lib/presentation/patient/views/patient_home_content.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/feeling_model.dart';

class DailyTip {
  final String title;
  final String description;
  final IconData icon;

  const DailyTip({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class DailyTipsManager {
  static const List<DailyTip> _tips = [
    DailyTip(
      title: 'Practica la atención plena',
      description:
          'Dedica 5 minutos cada mañana a respirar conscientemente y observar tus pensamientos sin juzgarlos.',
      icon: Icons.self_improvement,
    ),
    DailyTip(
      title: 'Desconexión digital',
      description:
          'Toma un descanso de 30 minutos sin dispositivos para reconectar contigo mismo.',
      icon: Icons.phone_disabled,
    ),
    DailyTip(
      title: 'Diario de gratitud',
      description:
          'Escribe 3 cosas por las que te sientes agradecido hoy. La gratitud mejora tu bienestar.',
      icon: Icons.favorite,
    ),
    DailyTip(
      title: 'Ejercicio físico',
      description:
          'Camina al menos 15 minutos al aire libre. El ejercicio libera endorfinas naturales.',
      icon: Icons.directions_walk,
    ),
    DailyTip(
      title: 'Conexión social',
      description:
          'Llama o envía un mensaje a alguien importante para ti. Las conexiones nutren el alma.',
      icon: Icons.group,
    ),
    DailyTip(
      title: 'Momento de calma',
      description:
          'Encuentra 10 minutos de silencio completo para relajarte y recargar energías.',
      icon: Icons.spa,
    ),
    DailyTip(
      title: 'Aprendizaje nuevo',
      description:
          'Lee sobre algo que te interese durante 10 minutos. Mantén tu mente activa y curiosa.',
      icon: Icons.menu_book,
    ),
    DailyTip(
      title: 'Organiza tu espacio',
      description:
          'Dedica 15 minutos a organizar tu entorno. Un espacio limpio calma la mente.',
      icon: Icons.cleaning_services,
    ),
    DailyTip(
      title: 'Escucha música',
      description:
          'Escucha tu música favorita por 20 minutos. La música puede mejorar tu estado de ánimo.',
      icon: Icons.music_note,
    ),
    DailyTip(
      title: 'Ayuda a otros',
      description:
          'Realiza un pequeño acto de bondad hoy. Ayudar a otros también te ayuda a ti.',
      icon: Icons.volunteer_activism,
    ),
    DailyTip(
      title: 'Hidrátate bien',
      description:
          'Bebe al menos 8 vasos de agua hoy. La hidratación afecta tu energía y concentración.',
      icon: Icons.local_drink,
    ),
    DailyTip(
      title: 'Respiración profunda',
      description:
          'Practica 5 respiraciones profundas cuando te sientas estresado. Es tu calmante natural.',
      icon: Icons.air,
    ),
    DailyTip(
      title: 'Tiempo en la naturaleza',
      description:
          'Pasa al menos 20 minutos en contacto con la naturaleza. Reduce el estrés naturalmente.',
      icon: Icons.park,
    ),
    DailyTip(
      title: 'Sonríe más',
      description:
          'Sonríe intencionalmente 5 veces hoy. Incluso una sonrisa forzada puede mejorar tu humor.',
      icon: Icons.sentiment_very_satisfied,
    ),
  ];

  static List<DailyTip> getTipsForToday() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

    // Selecciona 3 consejos diferentes basados en el día del año
    List<DailyTip> todaysTips = [];
    for (int i = 0; i < 3; i++) {
      int index =
          (dayOfYear + i * 5) %
          _tips.length; // Multiplicar por 5 para mayor variación
      todaysTips.add(_tips[index]);
    }

    return todaysTips;
  }

  static String getTodayMotivationalMessage() {
    final messages = [
      "¡Hoy es un nuevo día lleno de posibilidades!",
      "Cada pequeño paso cuenta en tu bienestar.",
      "Tu salud mental es una prioridad importante.",
      "Recuerda: está bien no estar bien todo el tiempo.",
      "Eres más fuerte de lo que crees.",
      "El autocuidado no es egoísmo, es necesario.",
      "Hoy es una oportunidad para cuidarte mejor.",
    ];

    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return messages[dayOfYear % messages.length];
  }
}

class Article {
  final String title;
  final String author;
  final String imageUrl;
  final String date;

  Article({
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.date,
  });
}

class PatientHomeContent extends StatefulWidget {
  const PatientHomeContent({super.key});

  @override
  State<PatientHomeContent> createState() => _PatientHomeContentState();
}

class _PatientHomeContentState extends State<PatientHomeContent> {
  Feeling? selectedFeeling;

  String _getFeelingMessage(Feeling feeling) {
    switch (feeling) {
      case Feeling.terrible:
        return 'Entiendo que hoy es un día difícil. Recuerda que está bien no sentirse bien siempre. 💜';
      case Feeling.bad:
        return 'Lamento que te sientas así. Considera hablar con alguien o practicar técnicas de relajación. 🌸';
      case Feeling.neutral:
        return 'Un día normal puede ser el inicio de algo mejor. ¿Qué tal si intentas algo que te guste? 🌟';
      case Feeling.good:
        return '¡Qué bueno saber que te sientes bien! Aprovecha esta energía positiva. ✨';
      case Feeling.great:
        return '¡Excelente! Tu energía positiva es contagiosa. Sigue así y comparte esa alegría. 🎉';
    }
  }

  void _showTipDialog(BuildContext context, DailyTip tip) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(tip.icon, color: AppConstants.primaryColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tip.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            tip.description,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendido',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Article> articles = [
      Article(
        title: 'Cómo afrontar el estrés: estrategias prácticas',
        author: 'Dr. Alex Rodriguez',
        imageUrl:
            'https://img.freepik.com/free-photo/mental-health-care-concept-mind-hand-holding-brain_23-2151042571.jpg',
        date: 'Julio 15, 2025',
      ),
      Article(
        title: 'El poder de la atención plena en la vida diaria',
        author: 'Dr. Maria Lopez',
        imageUrl:
            'https://img.freepik.com/free-photo/happy-young-woman-doing-yoga-outdoors-sunrise-canyon_1150-13783.jpg',
        date: 'Julio 10, 2025',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mensaje del día',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.wb_sunny,
                        color: AppConstants.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Inspiración para hoy',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    DailyTipsManager.getTodayMotivationalMessage(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sección de sentimientos con diseño acogedor (con overflow arreglado)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppConstants.primaryColor.withOpacity(0.05),
                  AppConstants.primaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: AppConstants.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Cómo te sientes hoy?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: 'Poppins',
                              color: AppConstants.primaryColor,
                            ),
                          ),
                          Text(
                            'Tu bienestar emocional es importante',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ImprovedFeelingIcon(
                        emoji: '😢',
                        label: 'Terrible',
                        feeling: Feeling.terrible,
                        isSelected: selectedFeeling == Feeling.terrible,
                        onTap: () => setState(() {
                          selectedFeeling = Feeling.terrible;
                        }),
                      ),
                      _ImprovedFeelingIcon(
                        emoji: '😔',
                        label: 'Mal',
                        feeling: Feeling.bad,
                        isSelected: selectedFeeling == Feeling.bad,
                        onTap: () => setState(() {
                          selectedFeeling = Feeling.bad;
                        }),
                      ),
                      _ImprovedFeelingIcon(
                        emoji: '😐',
                        label: 'Regular',
                        feeling: Feeling.neutral,
                        isSelected: selectedFeeling == Feeling.neutral,
                        onTap: () => setState(() {
                          selectedFeeling = Feeling.neutral;
                        }),
                      ),
                      _ImprovedFeelingIcon(
                        emoji: '😊',
                        label: 'Bien',
                        feeling: Feeling.good,
                        isSelected: selectedFeeling == Feeling.good,
                        onTap: () => setState(() {
                          selectedFeeling = Feeling.good;
                        }),
                      ),
                      _ImprovedFeelingIcon(
                        emoji: '😄',
                        label: 'Genial',
                        feeling: Feeling.great,
                        isSelected: selectedFeeling == Feeling.great,
                        onTap: () => setState(() {
                          selectedFeeling = Feeling.great;
                        }),
                      ),
                    ],
                  ),
                ),
                if (selectedFeeling != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppConstants.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.emoji_emotions,
                          color: AppConstants.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getFeelingMessage(selectedFeeling!),
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Consejos diarios',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: DailyTipsManager.getTipsForToday().length,
              itemBuilder: (context, index) {
                final tip = DailyTipsManager.getTipsForToday()[index];
                return _TipCard(
                  title: tip.title,
                  description: tip.description,
                  icon: tip.icon,
                  onTap: () {
                    _showTipDialog(context, tip);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Artículos de psicología
          const Text(
            'Artículos de psicología',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          ...articles.map((article) => _ArticleCard(article: article)),
        ],
      ),
    );
  }
}

class _ImprovedFeelingIcon extends StatelessWidget {
  final String emoji;
  final String label;
  final Feeling feeling;
  final bool isSelected;
  final VoidCallback onTap;

  const _ImprovedFeelingIcon({
    required this.emoji,
    required this.label,
    required this.feeling,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppConstants.primaryColor.withOpacity(0.2)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppConstants.primaryColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppConstants.primaryColor
                    : Colors.grey.shade600,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _TipCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 170,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppConstants.primaryColor, size: 24),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: AppConstants.primaryColor,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;

  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navegar al artículo completo
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                article.imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Por ${article.author}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        article.date,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
