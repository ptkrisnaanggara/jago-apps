import 'package:equatable/equatable.dart';

/// Kind of notification, drives the leading icon/colour.
enum NotificationCategory { transaction, promo, security, info }

/// A single in-app notification.
class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final NotificationCategory category;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.category,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      time: time,
      category: category,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, title, body, time, category, isRead];
}
