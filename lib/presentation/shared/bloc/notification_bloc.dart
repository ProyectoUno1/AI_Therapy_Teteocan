// lib/presentation/shared/bloc/notification_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_state.dart';
import 'package:ai_therapy_teteocan/data/models/notification_model.dart';
import 'package:ai_therapy_teteocan/data/repositories/notification_repository.dart';
import 'notification_event.dart';



class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationBloc({required NotificationRepository notificationRepository})
      : _notificationRepository = notificationRepository,
        super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<DeleteReadNotifications>(_onDeleteReadNotifications);
  }

  void _onLoadNotifications(
      LoadNotifications event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    try {
      final notifications = await _notificationRepository.fetchNotificationsForUser(event.userToken);
      emit(NotificationLoaded(notifications));
    } catch (e) {
      emit(NotificationError('No se pudieron cargar las notificaciones: ${e.toString()}'));
    }
  }

  void _onMarkNotificationAsRead(
      MarkNotificationAsRead event, Emitter<NotificationState> emit) async {
    try {
      List<NotificationModel> currentNotifications = [];
      if (state is NotificationLoaded) {
        currentNotifications = (state as NotificationLoaded).notifications;
        
        final updatedNotifications = currentNotifications.map((notification) {
          if (notification.id == event.notificationId) {
            return NotificationModel(
              id: notification.id,
              title: notification.title,
              body: notification.body,
              type: notification.type,
              timestamp: notification.timestamp,
              isRead: true, 
              userId: notification.userId,
              data: notification.data,
            );
          }
          return notification;
        }).toList();
        
        emit(NotificationLoaded(updatedNotifications));
      }

      // Hacer la llamada al servidor
      await _notificationRepository.markNotificationAsRead(
          event.userToken, event.notificationId);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        final notifications = await _notificationRepository.fetchNotificationsForUser(token!);
        emit(NotificationLoaded(notifications));
      }
    } catch (e) {
      emit(NotificationError('No se pudo marcar la notificación como leída: ${e.toString()}'));
      
      if (state is NotificationError) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          add(LoadNotifications(userToken: token!, userId: event.userId, userType: event.userType));
        }
      }
    }
  }

  void _onDeleteNotification(
      DeleteNotification event, Emitter<NotificationState> emit) async {
    try {
      // Guardar el estado actual
      List<NotificationModel> currentNotifications = [];
      if (state is NotificationLoaded) {
        currentNotifications = (state as NotificationLoaded).notifications;
        
        // Actualizar localmente primero
        final updatedNotifications = currentNotifications
            .where((notification) => notification.id != event.notificationId)
            .toList();
        
        emit(NotificationLoaded(updatedNotifications));
      }

      // Hacer la llamada al servidor
      await _notificationRepository.deleteNotification(
          event.userToken, event.notificationId);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        final notifications = await _notificationRepository.fetchNotificationsForUser(token!);
        emit(NotificationLoaded(notifications));
      }
    } catch (e) {
      emit(NotificationError('No se pudo eliminar la notificación: ${e.toString()}'));
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        add(LoadNotifications(userToken: token!, userId: event.userId, userType: event.userType));
      }
    }
  }
void _onDeleteReadNotifications(
    DeleteReadNotifications event, Emitter<NotificationState> emit) async {
  final currentState = state;
  
  try {
    emit(NotificationLoading());
    await _notificationRepository.deleteReadNotifications(event.userToken);
    
    // Recargar las notificaciones después de eliminar
    final notifications = await _notificationRepository.fetchNotificationsForUser(event.userToken);
    emit(NotificationLoaded(notifications));
    
  } catch (e) {
    if (currentState is NotificationLoaded) {
      emit(currentState);
    }
    
    String errorMessage = 'No se pudieron eliminar las notificaciones leídas';
    if (e.toString().contains('404')) {
      errorMessage = 'Error: Endpoint no encontrado. Contacta al soporte técnico.';
    } else if (e.toString().contains('Connection')) {
      errorMessage = 'Error de conexión. Verifica tu internet.';
    }
    
    emit(NotificationError('$errorMessage: ${e.toString()}'));
  }
}
}