import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:jago/l10n/app_localizations.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/transfer_bloc.dart';

/// Step 1 of the Transfer & Pay flow: pick a recipient.
class TransferPage extends StatelessWidget {
  const TransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.transferTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.defaultMargin),
              child: TextField(
                onChanged: (value) =>
                    context.read<TransferBloc>().add(TransferSearchChanged(value)),
                decoration: InputDecoration(
                  hintText: l10n.transferSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<TransferBloc, TransferState>(
                builder: (context, state) {
                  switch (state.status) {
                    case TransferStatus.initial:
                    case TransferStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case TransferStatus.failure:
                      return _ErrorView(
                        message: state.errorMessage ?? l10n.genericError,
                        onRetry: () => context
                            .read<TransferBloc>()
                            .add(const TransferStarted()),
                      );
                    default:
                      final contacts = state.filteredContacts;
                      if (contacts.isEmpty) {
                        return const _EmptyView();
                      }
                      return ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, i) {
                          final c = contacts[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                c.initial,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(c.name),
                            subtitle: Text('${c.bankName} • ${c.accountNumber}'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              context
                                  .read<TransferBloc>()
                                  .add(TransferContactSelected(c));
                              context.push(AppRouter.transferAmount);
                            },
                          );
                        },
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search_rounded,
                size: 48, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.transferContactsEmpty,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
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
        padding: const EdgeInsets.all(32),
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
