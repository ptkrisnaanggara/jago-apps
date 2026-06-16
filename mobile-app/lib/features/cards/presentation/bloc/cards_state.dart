part of 'cards_bloc.dart';

enum CardsStatus { initial, loading, success, failure }

class CardsState extends Equatable {
  final CardsStatus status;
  final List<PaymentCard> cards;

  /// Id of the card whose freeze state is currently updating.
  final String? togglingId;
  final AppFailure? failure;

  const CardsState({
    this.status = CardsStatus.initial,
    this.cards = const [],
    this.togglingId,
    this.failure,
  });

  CardsState copyWith({
    CardsStatus? status,
    List<PaymentCard>? cards,
    String? togglingId,
    AppFailure? failure,
  }) {
    return CardsState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
      // togglingId and failure reset each transition unless set explicitly.
      togglingId: togglingId,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, cards, togglingId, failure];
}
