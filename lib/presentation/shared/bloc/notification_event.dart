// lib/presentation/shared/bloc/notification_event.dart

import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final String userId;
  final String userToken;
  final String userType;

  const LoadNotifications({
    required this.userId,
    required this.userToken,
    required this.userType,
  });

  @override
  List<Object> get props => [userId, userToken, userType];
}

class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;
  final String userToken;
  final String userId;
  final String userType;

  const MarkNotificationAsRead({
    required this.notificationId,
    required this.userToken,
    required this.userId,
    required this.userType,
  });

  @override
  List<Object> get props => [notificationId, userToken, userId, userType];
}

class DeleteNotification extends NotificationEvent {
  final String notificationId;
  final String userToken;
  final String userId;
  final String userType;

  const DeleteNotification({
    required this.notificationId,
    required this.userToken,
    required this.userId,
    required this.userType,
  });

  @override
  List<Object> get props => [notificationId, userToken, userId, userType];
}

class DeleteReadNotifications extends NotificationEvent {
  final String userToken;
  final String userId;
  final String userType;

  const DeleteReadNotifications({
    required this.userToken,
    required this.userId,
    required this.userType,
  });

  @override
  List<Object> get props => [userToken, userId, userType];
}