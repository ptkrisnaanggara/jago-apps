part of 'cards_bloc.dart';

sealed class CardsEvent extends Equatable {
  const CardsEvent();

  @override
  List<Object?> get props => [];
}

class CardsStarted extends CardsEvent {
  const CardsStarted();
}

class CardFrozenToggled extends CardsEvent {
  final String id;
  final bool frozen;

  const CardFrozenToggled({required this.id, required this.frozen});

  @override
  List<Object?> get props => [id, frozen];
}
