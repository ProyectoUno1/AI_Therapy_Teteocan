// lib/presentation/chat/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? profilePictureUrl;
  final IconData? senderIcon;
  final bool isRead; 

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.profilePictureUrl,
    this.senderIcon,
    this.isRead = false, 
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String formattedTime = '...'; 
    
    if (message.timestamp != null) {
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
               backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              radius: 16,
              child: Icon(
                Icons.psychology, // Icono de Aurora
                size: 20,
                 color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.colorScheme.primary
                    : (isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : theme.colorScheme.primary.withOpacity(0.1)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: !isMe && isDark
                    ? Border.all(color: theme.dividerColor, width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMe
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                  ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isMe
                               ? theme.colorScheme.onPrimary.withOpacity(0.7)
                          : theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildReadStatusIndicator(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundImage:
                  profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                      ? NetworkImage(profilePictureUrl!) as ImageProvider
                      : null,
              backgroundColor:
                  profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                      ? null
                      : theme.colorScheme.primary.withOpacity(0.2),
              radius: 16,
              child: profilePictureUrl == null || profilePictureUrl!.isEmpty
                  ? Icon(
                      senderIcon ?? Icons.person,
                      size: 20,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  // Widget para el indicador de estado de lectura
  Widget _buildReadStatusIndicator() {
    if (isRead) {
      // Mensaje leído - doble check azul
      return const Row(
        children: [
          Icon(
            Icons.done_all,
            size: 14,
            color: Colors.blue, 
          ),
        ],
      );
    } else {
      // Mensaje enviado pero no leído - doble check gris
      return const Row(
        children: [
          Icon(
            Icons.done_all,
          size: 14,
            color: Colors.grey, 
          ),
        ],
      );
    }
  }
}