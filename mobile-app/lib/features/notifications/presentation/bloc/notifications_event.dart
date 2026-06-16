part of 'notifications_bloc.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsStarted extends NotificationsEvent {
  const NotificationsStarted();
}

class NotificationOpened extends NotificationsEvent {
  final String id;

  const NotificationOpened(this.id);

  @override
  List<Object?> get props => [id];
}

class AllNotificationsRead extends NotificationsEvent {
  const AllNotificationsRead();
}
