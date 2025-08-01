// lib/presentation/chat/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:intl/intl.dart'; // <--- ¡Importa esta librería!

// lib/presentation/chat/widgets/message_bubble.dart
// ... (imports) ...

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe; // <-- SIEMPRE true = YO, false = OTRO/IA

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe // Si isMe es true, a la derecha. Si es false, a la izquierda.
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[ // Si NO soy yo (es decir, es Aurora), muestro avatar de IA.
            CircleAvatar(
              backgroundColor: AppConstants.lightAccentColor.withOpacity(0.2),
              radius: 16,
              child: Icon(
                Icons.psychology, // Icono de Aurora
                size: 20,
                color: AppConstants.lightAccentColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe // Si isMe es true, color de acento. Si es false, color claro.
                    ? AppConstants.lightAccentColor
                    : AppConstants.lightAccentColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('hh:mm a').format(message.timestamp ?? DateTime.now()),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black54,
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 24), // Si soy yo, espacio a la derecha.
        ],
      ),
    );
  }
}