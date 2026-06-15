import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/app_notification.dart';
import '../../data/repositories/notifications_repository.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

/// Owns the notification center. Provided app-wide (above the router) so the
/// Home bell badge and the notifications page share one source of truth.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsBloc({required NotificationsRepository repository})
      : _repository = repository,
        super(const NotificationsState()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationOpened>(_onOpened);
    on<AllNotificationsRead>(_onAllRead);
  }

  Future<void> _onStarted(
    NotificationsStarted event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading));
    try {
      final items = await _repository.getNotifications();
      emit(state.copyWith(status: NotificationsStatus.success, items: items));
    } catch (_) {
      emit(state.copyWith(
        status: NotificationsStatus.failure,
        errorMessage: 'Gagal memuat notifikasi. Coba lagi.',
      ));
    }
  }

  Future<void> _onOpened(
    NotificationOpened event,
    Emitter<NotificationsState> emit,
  ) async {
    final items = await _repository.markRead(event.id);
    emit(state.copyWith(status: NotificationsStatus.success, items: items));
  }

  Future<void> _onAllRead(
    AllNotificationsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final items = await _repository.markAllRead();
    emit(state.copyWith(status: NotificationsStatus.success, items: items));
  }
}
