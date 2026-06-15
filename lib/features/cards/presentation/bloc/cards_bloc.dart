import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/payment_card.dart';
import '../../data/repositories/cards_repository.dart';

part 'cards_event.dart';
part 'cards_state.dart';

class CardsBloc extends Bloc<CardsEvent, CardsState> {
  final CardsRepository _repository;

  CardsBloc({required CardsRepository repository})
      : _repository = repository,
        super(const CardsState()) {
    on<CardsStarted>(_onStarted);
    on<CardFrozenToggled>(_onFrozenToggled);
  }

  Future<void> _onStarted(CardsStarted event, Emitter<CardsState> emit) async {
    emit(state.copyWith(status: CardsStatus.loading));
    try {
      final cards = await _repository.getCards();
      emit(state.copyWith(status: CardsStatus.success, cards: cards));
    } catch (_) {
      emit(state.copyWith(
        status: CardsStatus.failure,
        errorMessage: 'Gagal memuat kartu. Coba lagi.',
      ));
    }
  }

  Future<void> _onFrozenToggled(
    CardFrozenToggled event,
    Emitter<CardsState> emit,
  ) async {
    emit(state.copyWith(togglingId: event.id));
    try {
      final cards =
          await _repository.setFrozen(event.id, frozen: event.frozen);
      emit(state.copyWith(status: CardsStatus.success, cards: cards));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Gagal memperbarui kartu. Coba lagi.'));
    }
  }
}
