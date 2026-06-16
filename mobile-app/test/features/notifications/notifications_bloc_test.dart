import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/notifications/data/repositories/notifications_repository.dart';
import 'package:jago/features/notifications/presentation/bloc/notifications_bloc.dart';

void main() {
  group('NotificationsBloc', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'loads notifications and computes the unread count',
      build: () => NotificationsBloc(repository: MockNotificationsRepository()),
      act: (bloc) => bloc.add(const NotificationsStarted()),
      wait: const Duration(milliseconds: 800),
      expect: () => [
        isA<NotificationsState>()
            .having((s) => s.status, 'status', NotificationsStatus.loading),
        isA<NotificationsState>()
            .having((s) => s.status, 'status', NotificationsStatus.success)
            .having((s) => s.unreadCount, 'unreadCount', 2),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'opening a notification marks it read',
      build: () => NotificationsBloc(repository: MockNotificationsRepository()),
      act: (bloc) async {
        bloc.add(const NotificationsStarted());
        await Future<void>.delayed(const Duration(milliseconds: 800));
        bloc.add(const NotificationOpened('n1'));
      },
      wait: const Duration(milliseconds: 1600),
      verify: (bloc) {
        final n1 = bloc.state.items.firstWhere((n) => n.id == 'n1');
        expect(n1.isRead, isTrue);
        expect(bloc.state.unreadCount, 1);
      },
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'mark all read zeroes the unread count',
      build: () => NotificationsBloc(repository: MockNotificationsRepository()),
      act: (bloc) async {
        bloc.add(const NotificationsStarted());
        await Future<void>.delayed(const Duration(milliseconds: 800));
        bloc.add(const AllNotificationsRead());
      },
      wait: const Duration(milliseconds: 1600),
      verify: (bloc) => expect(bloc.state.unreadCount, 0),
    );
  });
}
