part of 'cards_bloc.dart';

enum CardsStatus { initial, loading, success, failure }

class CardsState extends Equatable {
  final CardsStatus status;
  final List<PaymentCard> cards;

  /// Id of the card whose freeze state is currently updating.
  final String? togglingId;
  final String? errorMessage;

  const CardsState({
    this.status = CardsStatus.initial,
    this.cards = const [],
    this.togglingId,
    this.errorMessage,
  });

  CardsState copyWith({
    CardsStatus? status,
    List<PaymentCard>? cards,
    String? togglingId,
    String? errorMessage,
  }) {
    return CardsState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
      // togglingId and errorMessage reset each transition unless set explicitly.
      togglingId: togglingId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, cards, togglingId, errorMessage];
}
