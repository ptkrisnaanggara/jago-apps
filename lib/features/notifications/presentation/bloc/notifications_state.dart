part of 'notifications_bloc.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<AppNotification> items;
  final AppFailure? failure;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.failure,
  });

  int get unreadCount => items.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    AppFailure? failure,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, items, failure];
}
