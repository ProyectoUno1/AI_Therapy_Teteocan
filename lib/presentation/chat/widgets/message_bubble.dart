// lib/presentation/chat/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? senderImageUrl;
  final IconData? senderIcon;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderImageUrl,
    this.senderIcon,
  });

  @override
  Widget build(BuildContext context) {
    String formattedTime = '...'; // Valor por defecto
    
    if (message.timestamp != null) {
      // Convertir la hora a la zona horaria local del dispositivo
      final localTime = message.timestamp!.toLocal();
      formattedTime = DateFormat('hh:mm a').format(localTime);
      
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: AppConstants.lightAccentColor.withOpacity(0.2),
              radius: 16,
              child: const Icon(
                Icons.psychology, // Icono de Aurora
                size: 20,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
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
                    formattedTime,
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
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundImage:
                  senderImageUrl != null && senderImageUrl!.isNotEmpty
                      ? NetworkImage(senderImageUrl!) as ImageProvider
                      : null,
              backgroundColor:
                  senderImageUrl != null && senderImageUrl!.isNotEmpty
                      ? null
                      : AppConstants.lightAccentColor.withOpacity(
                          0.2,
                        ),
              radius: 16,
              child: senderImageUrl == null || senderImageUrl!.isEmpty
                  ? Icon(
                      senderIcon ?? Icons.person,
                      size: 20,
                      color: AppConstants.lightAccentColor,
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
