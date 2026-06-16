import 'package:jago/core/network/api_client.dart';

import '../models/app_notification.dart';
import 'notifications_repository.dart';

/// Backend-backed [NotificationsRepository]. Read mutations re-fetch the list
/// to match the interface.
class ApiNotificationsRepository implements NotificationsRepository {
  final ApiClient _api;

  ApiNotificationsRepository(this._api);

  @override
  Future<List<AppNotification>> getNotifications() async {
    final list = await _api.get('/notifications') as List<dynamic>;
    return list
        .map((e) => _notificationFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AppNotification>> markRead(String id) async {
    await _api.post('/notifications/$id/read');
    return getNotifications();
  }

  @override
  Future<List<AppNotification>> markAllRead() async {
    await _api.post('/notifications/read-all');
    return getNotifications();
  }

  AppNotification _notificationFromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      time: DateTime.parse(json['createdAt'] as String),
      category: _categoryFromJson(json['category'] as String?),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  NotificationCategory _categoryFromJson(String? value) {
    return switch (value) {
      'transaction' => NotificationCategory.transaction,
      'promo' => NotificationCategory.promo,
      'security' => NotificationCategory.security,
      _ => NotificationCategory.info,
    };
  }
}
