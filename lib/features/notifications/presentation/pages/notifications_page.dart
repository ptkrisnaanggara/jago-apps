import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:jago/l10n/app_localizations.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/app_notification.dart';
import '../bloc/notifications_bloc.dart';

/// In-app notification center. Reads the app-level [NotificationsBloc] so its
/// read-state stays in sync with the Home bell badge.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context
                    .read<NotificationsBloc>()
                    .add(const AllNotificationsRead()),
                child: Text(l10n.notificationsMarkAllRead),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            switch (state.status) {
              case NotificationsStatus.initial:
              case NotificationsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case NotificationsStatus.failure:
                return _ErrorView(
                  message: failureText(
                      context, state.failure ?? AppFailure.generic),
                  onRetry: () => context
                      .read<NotificationsBloc>()
                      .add(const NotificationsStarted()),
                );
              case NotificationsStatus.success:
                if (state.items.isEmpty) {
                  return Center(child: Text(l10n.notificationsEmpty));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      _NotificationTile(item: state.items[i]),
                );
            }
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (icon, color) = _styleFor(item.category);
    final timeLabel = DateFormat('d MMM, HH:mm', 'id_ID').format(item.time);

    return ListTile(
      onTap: item.isRead
          ? null
          : () => context.read<NotificationsBloc>().add(
                NotificationOpened(item.id),
              ),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(
        item.title,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(item.body),
          const SizedBox(height: 4),
          Text(timeLabel,
              style: textTheme.bodySmall?.copyWith(color: AppColors.grey)),
        ],
      ),
      trailing: item.isRead
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
      isThreeLine: true,
    );
  }

  static (IconData, Color) _styleFor(NotificationCategory category) {
    return switch (category) {
      NotificationCategory.transaction => (
          Icons.swap_horiz_rounded,
          AppColors.primary
        ),
      NotificationCategory.promo => (Icons.local_offer_rounded, AppColors.success),
      NotificationCategory.security => (
          Icons.shield_outlined,
          AppColors.error
        ),
      NotificationCategory.info => (Icons.info_outline_rounded, AppColors.grey),
    };
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context)!.actionRetry)),
          ],
        ),
      ),
    );
  }
}
