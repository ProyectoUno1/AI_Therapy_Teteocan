# Chat System Integration - Backend Tasks

## Resumen

Se ha implementado el sistema completo de chats para psicólogos con las siguientes pantallas:

- `PsychologistChatListScreen`: Lista de pacientes con conversaciones activas
- `PatientChatScreen`: Chat individual entre psicólogo y paciente
- Integración completa en `PsychologistHomeScreen`

## Tareas para Conectar con Backend

### 1. Modelos de Datos

#### 1.1 Crear modelo de Chat/Conversación

```dart
// lib/data/models/chat_model.dart
class ChatModel {
  final String id;
  final String psychologistId;
  final String patientId;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isActive;
  final ChatParticipant psychologist;
  final ChatParticipant patient;
}

class ChatParticipant {
  final String id;
  final String name;
  final String? profileImageUrl;
  final bool isOnline;
  final DateTime? lastSeen;
}
```

#### 1.2 Extender MessageModel existente

```dart
// Agregar campos necesarios a MessageModel
class MessageModel {
  // Campos existentes...
  final String chatId;
  final String senderId;
  final String receiverId;
  final MessageStatus status; // sent, delivered, read
  final MessageType type; // text, image, file
}

enum MessageStatus { sent, delivered, read }
enum MessageType { text, image, file, voice }
```

### 2. APIs y Servicios Backend

#### 2.1 API Endpoints para Chats de Psicólogos

```javascript
// backend/routes/psychologistChatRoutes.js

// GET /api/psychologist/chats
// - Obtener lista de chats del psicólogo
// - Incluir información del paciente y último mensaje
// - Ordenar por última actividad

// GET /api/psychologist/chats/:chatId/messages
// - Obtener mensajes de un chat específico
// - Paginación para historial extenso
// - Marcar mensajes como leídos

// POST /api/psychologist/chats/:chatId/messages
// - Enviar mensaje desde psicólogo a paciente
// - Validar que el psicólogo pertenece al chat
// - Notificar al paciente en tiempo real

// PUT /api/psychologist/chats/:chatId/read
// - Marcar mensajes como leídos
// - Actualizar contador de no leídos
```

#### 2.2 API Endpoints para Conexión Bidireccional

```javascript
// backend/routes/chatRoutes.js (compartido)

// POST /api/chats/create
// - Crear nueva conversación entre psicólogo y paciente
// - Validar que ambos usuarios existen
// - Verificar permisos de comunicación

// GET /api/chats/:chatId/participants
// - Obtener información de participantes
// - Estado en línea, última conexión

// WebSocket endpoints para tiempo real:
// - join_chat_room
// - leave_chat_room
// - send_message
// - message_delivered
// - message_read
// - user_typing
// - user_stop_typing
// - user_online_status
```

### 3. Servicios de Datos (Data Sources)

#### 3.1 ChatRemoteDataSource

```dart
// lib/data/datasources/chat_remote_datasource.dart
abstract class ChatRemoteDataSource {
  // Para psicólogos
  Future<List<ChatModel>> getPsychologistChats(String psychologistId);
  Future<List<MessageModel>> getChatMessages(String chatId, {int page = 1});
  Future<MessageModel> sendMessage(String chatId, String content, String senderId);
  Future<void> markMessagesAsRead(String chatId, String userId);

  // Para estado en tiempo real
  Stream<MessageModel> subscribeToNewMessages(String chatId);
  Stream<UserStatus> subscribeToUserStatus(String userId);
  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping);
}
```

#### 3.2 WebSocket Service

```dart
// lib/data/services/websocket_service.dart
class WebSocketService {
  void joinChatRoom(String chatId);
  void leaveChatRoom(String chatId);
  Stream<MessageModel> onNewMessage();
  Stream<TypingStatus> onTypingStatus();
  Stream<UserStatus> onUserStatusChange();
  void sendTypingStatus(String chatId, bool isTyping);
  void sendMessage(MessageModel message);
}
```

### 4. Repositorios

#### 4.1 ChatRepository (extender existente)

```dart
// lib/data/repositories/chat_repository.dart
class ChatRepository {
  // Métodos existentes para AI chat...

  // Nuevos métodos para chats entre usuarios
  Future<List<ChatModel>> getPsychologistChats(String psychologistId);
  Future<List<MessageModel>> getChatMessages(String chatId);
  Future<MessageModel> sendMessageToPatient(String chatId, String content);
  Future<void> markAsRead(String chatId);
  Stream<MessageModel> watchNewMessages(String chatId);
  Stream<bool> watchTypingStatus(String chatId, String userId);
}
```

### 5. BLoC/Estado

#### 5.1 ChatListBloc para Psicólogos

```dart
// lib/presentation/psychologist/bloc/chat_list_bloc.dart
class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  // Eventos:
  // - LoadPsychologistChats
  // - RefreshChats
  // - SearchChats
  // - ChatUpdated (listener en tiempo real)

  // Estados:
  // - ChatListLoading
  // - ChatListLoaded
  // - ChatListError
}
```

#### 5.2 IndividualChatBloc

```dart
// lib/presentation/chat/bloc/individual_chat_bloc.dart
class IndividualChatBloc extends Bloc<IndividualChatEvent, IndividualChatState> {
  // Eventos:
  // - LoadChatMessages
  // - SendMessage
  // - MessageReceived
  // - TypingStarted/Stopped
  // - MarkAsRead

  // Estados:
  // - MessagesLoading
  // - MessagesLoaded
  // - MessageSending
  // - MessageSent
  // - MessageError
}
```

### 6. Base de Datos (Firebase/SQL)

#### 6.1 Estructura Firebase (si se usa Firestore)

```
chats/
  {chatId}/
    - id: string
    - psychologistId: string
    - patientId: string
    - createdAt: timestamp
    - lastMessageAt: timestamp
    - lastMessage: string
    - psychologistUnreadCount: number
    - patientUnreadCount: number
    - isActive: boolean

messages/
  {chatId}/
    {messageId}/
      - id: string
      - chatId: string
      - senderId: string
      - receiverId: string
      - content: string
      - timestamp: timestamp
      - type: 'text' | 'image' | 'file'
      - status: 'sent' | 'delivered' | 'read'

user_status/
  {userId}/
    - isOnline: boolean
    - lastSeen: timestamp
    - currentChatId: string (opcional)
```

#### 6.2 Estructura SQL (alternativa)

```sql
-- Tabla de chats
CREATE TABLE chats (
  id VARCHAR(255) PRIMARY KEY,
  psychologist_id VARCHAR(255) NOT NULL,
  patient_id VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_message_at TIMESTAMP,
  last_message TEXT,
  psychologist_unread_count INT DEFAULT 0,
  patient_unread_count INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  FOREIGN KEY (psychologist_id) REFERENCES psychologists(id),
  FOREIGN KEY (patient_id) REFERENCES patients(id)
);

-- Tabla de mensajes
CREATE TABLE messages (
  id VARCHAR(255) PRIMARY KEY,
  chat_id VARCHAR(255) NOT NULL,
  sender_id VARCHAR(255) NOT NULL,
  receiver_id VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  message_type ENUM('text', 'image', 'file', 'voice') DEFAULT 'text',
  status ENUM('sent', 'delivered', 'read') DEFAULT 'sent',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (chat_id) REFERENCES chats(id)
);

-- Tabla de estado de usuarios
CREATE TABLE user_status (
  user_id VARCHAR(255) PRIMARY KEY,
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMP,
  current_chat_id VARCHAR(255),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### 7. Notificaciones Push

#### 7.1 Firebase Cloud Messaging (FCM)

```dart
// lib/services/notification_service.dart
class NotificationService {
  Future<void> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String messageContent,
    required String chatId,
  });

  Future<void> handleIncomingMessage(RemoteMessage message);
  Future<void> setupChatNotificationHandlers();
}
```

#### 7.2 Backend - Envío de Notificaciones

```javascript
// backend/services/notificationService.js
const sendChatNotification = async (
  receiverId,
  senderName,
  message,
  chatId
) => {
  // Obtener token FCM del receptor
  // Enviar notificación con datos del chat
  // Incrementar contador de no leídos
};
```

### 8. Implementación por Fases

#### Fase 1: Funcionalidad Básica

- [ ] Crear modelos de datos
- [ ] Implementar API endpoints básicos
- [ ] Conectar PsychologistChatListScreen con datos reales
- [ ] Implementar envío/recepción de mensajes
- [ ] Persistencia en base de datos

#### Fase 2: Tiempo Real

- [ ] Implementar WebSocket/Socket.IO
- [ ] Estados de "escribiendo..."
- [ ] Estados en línea/desconectado
- [ ] Actualización automática de chats

#### Fase 3: Características Avanzadas

- [ ] Notificaciones push
- [ ] Compartir archivos/imágenes
- [ ] Historial de mensajes con paginación
- [ ] Búsqueda en conversaciones

#### Fase 4: Funciones Profesionales

- [ ] Notas de sesión desde chat
- [ ] Integración con calendario
- [ ] Videollamadas/llamadas de voz
- [ ] Reportes de comunicación

### 9. Archivos que Necesitan Modificación

#### Frontend (Flutter)

- `lib/data/models/` - Nuevos modelos
- `lib/data/datasources/` - Chat data source
- `lib/data/repositories/chat_repository.dart` - Extender
- `lib/presentation/psychologist/bloc/` - Nuevos BLoCs
- `lib/services/` - WebSocket y notificaciones

#### Backend (Node.js)

- `backend/routes/` - Nuevas rutas de chat
- `backend/controllers/` - Controladores de chat
- `backend/services/` - Servicios de chat y notificaciones
- `backend/models/` - Modelos de chat y mensajes
- `backend/websocket/` - Manejo de WebSocket
- `backend/database/` - Migraciones/esquemas

### 10. Testing

#### 10.1 Tests de Frontend

- Unit tests para BLoCs de chat
- Widget tests para pantallas de chat
- Integration tests para flujo completo

#### 10.2 Tests de Backend

- Unit tests para servicios de chat
- Integration tests para APIs
- Tests de WebSocket en tiempo real

### 11. Consideraciones de Seguridad

- Validación de permisos: solo psicólogos asignados pueden chatear con pacientes
- Encriptación de mensajes en tránsito y reposo
- Rate limiting para prevenir spam
- Validación de contenido de mensajes
- Logs de auditoría para comunicaciones

Esta documentación proporciona una hoja de ruta completa para conectar el frontend ya implementado con un backend robusto y escalable.
