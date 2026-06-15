import '../models/app_notification.dart';

/// Contract for in-app notifications. UI/BLoC depend on this, not the mock.
abstract class NotificationsRepository {
  Future<List<AppNotification>> getNotifications();

  /// Marks one notification read and returns the updated list.
  Future<List<AppNotification>> markRead(String id);

  /// Marks every notification read and returns the updated list.
  Future<List<AppNotification>> markAllRead();
}

/// Temporary mock. Holds a mutable in-memory list so read-state persists for
/// the session (a real impl would call an API).
class MockNotificationsRepository implements NotificationsRepository {
  static const _latency = Duration(milliseconds: 600);

  final List<AppNotification> _items = _seed();

  static List<AppNotification> _seed() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        title: 'Transfer berhasil',
        body: 'Kamu mengirim Rp150.000 ke Budi Santoso.',
        time: now.subtract(const Duration(minutes: 12)),
        category: NotificationCategory.transaction,
      ),
      AppNotification(
        id: 'n2',
        title: 'Tagihan akan jatuh tempo',
        body: 'Tagihan PLN Rp320.000 jatuh tempo dalam 3 hari.',
        time: now.subtract(const Duration(hours: 5)),
        category: NotificationCategory.info,
      ),
      AppNotification(
        id: 'n3',
        title: 'Promo akhir pekan',
        body: 'Cashback 20% untuk pembayaran tagihan via Jago.',
        time: now.subtract(const Duration(days: 1)),
        category: NotificationCategory.promo,
        isRead: true,
      ),
      AppNotification(
        id: 'n4',
        title: 'Login perangkat baru',
        body: 'Akunmu diakses dari perangkat baru. Cek keamanan.',
        time: now.subtract(const Duration(days: 2)),
        category: NotificationCategory.security,
        isRead: true,
      ),
    ];
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    await Future<void>.delayed(_latency);
    return List.unmodifiable(_items);
  }

  @override
  Future<List<AppNotification>> markRead(String id) async {
    await Future<void>.delayed(_latency);
    final i = _items.indexWhere((n) => n.id == id);
    if (i != -1) _items[i] = _items[i].copyWith(isRead: true);
    return List.unmodifiable(_items);
  }

  @override
  Future<List<AppNotification>> markAllRead() async {
    await Future<void>.delayed(_latency);
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    return List.unmodifiable(_items);
  }
}
