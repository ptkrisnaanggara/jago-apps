import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jago/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/payment_card.dart';
import '../../data/repositories/cards_repository.dart';
import '../bloc/cards_bloc.dart';

class CardsPage extends StatelessWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CardsBloc(
        repository: context.read<CardsRepository>(),
      )..add(const CardsStarted()),
      child: const _CardsView(),
    );
  }
}

class _CardsView extends StatelessWidget {
  const _CardsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cardsTitle)),
      body: SafeArea(
        child: BlocConsumer<CardsBloc, CardsState>(
          listenWhen: (prev, curr) =>
              curr.status == CardsStatus.success &&
              curr.errorMessage != null &&
              prev.errorMessage != curr.errorMessage,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          },
          builder: (context, state) {
            switch (state.status) {
              case CardsStatus.initial:
              case CardsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case CardsStatus.failure:
                return _ErrorView(
                  message: state.errorMessage ?? l10n.genericError,
                  onRetry: () =>
                      context.read<CardsBloc>().add(const CardsStarted()),
                );
              case CardsStatus.success:
                return ListView(
                  padding: const EdgeInsets.all(AppTheme.defaultMargin),
                  children: [
                    for (final card in state.cards)
                      _CardSection(
                        card: card,
                        toggling: state.togglingId == card.id,
                      ),
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}

/// A single card: the gradient visual + its controls. Stateful so "show
/// details" can reveal the full number / CVV locally (presentation-only).
class _CardSection extends StatefulWidget {
  final PaymentCard card;
  final bool toggling;

  const _CardSection({required this.card, required this.toggling});

  @override
  State<_CardSection> createState() => _CardSectionState();
}

class _CardSectionState extends State<_CardSection> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final card = widget.card;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardVisual(card: card, revealed: _revealed),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.toggling
                      ? null
                      : () => context.read<CardsBloc>().add(
                            CardFrozenToggled(
                              id: card.id,
                              frozen: !card.isFrozen,
                            ),
                          ),
                  icon: widget.toggling
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(card.isFrozen
                          ? Icons.lock_open_rounded
                          : Icons.ac_unit_rounded),
                  label: Text(
                      card.isFrozen ? l10n.cardUnfreeze : l10n.cardFreeze),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _revealed = !_revealed),
                  icon: Icon(_revealed
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded),
                  label: Text(
                      _revealed ? l10n.cardHideDetails : l10n.cardShowDetails),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardVisual extends StatelessWidget {
  final PaymentCard card;
  final bool revealed;

  const _CardVisual({required this.card, required this.revealed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = AppColors.pocketAccent(card.accentIndex);
    final accentDark = Color.lerp(accent, Colors.black, 0.35)!;
    final typeLabel =
        card.type == CardType.virtual ? l10n.cardVirtual : l10n.cardPhysical;

    return AspectRatio(
      aspectRatio: 1.6,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accentDark],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card.label,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _GlassChip(label: typeLabel),
                  ],
                ),
                const Spacer(),
                Text(
                  revealed ? card.number : card.maskedNumber,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _CardField(
                        label: l10n.cardHolder,
                        value: card.holderName,
                      ),
                    ),
                    _CardField(label: l10n.cardExpiry, value: card.expiry),
                    if (revealed) ...[
                      const SizedBox(width: 16),
                      _CardField(label: l10n.cardCvv, value: card.cvv),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (card.isFrozen)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withValues(alpha: 0.45),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.ac_unit_rounded,
                        color: AppColors.white, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      l10n.cardFrozen,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  final String label;
  final String value;

  const _CardField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.75),
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GlassChip extends StatelessWidget {
  final String label;

  const _GlassChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
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
